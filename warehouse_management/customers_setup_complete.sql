-- ============================================================================
-- COMPLETE CUSTOMER DUES SETUP SQL
-- ============================================================================
-- Run this ENTIRE file in Supabase SQL Editor to fix "can't add customer" issue
-- This creates customers table + customer_transactions table + all functions
-- ============================================================================

-- ============================================================================
-- 1. CREATE CUSTOMERS TABLE (MISSING FROM ORIGINAL SETUP)
-- ============================================================================

-- Drop table if exists (WARNING: This will delete existing customer data)
-- Comment out the DROP line if you want to preserve existing data
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Basic info
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  email VARCHAR(255),
  address TEXT,

  -- Customer type
  customer_type VARCHAR(50) DEFAULT 'customer' CHECK (customer_type IN ('customer', 'employee', 'supplier')),

  -- Due tracking
  total_due DECIMAL(12, 2) DEFAULT 0,
  is_paid BOOLEAN DEFAULT true,
  last_transaction_date TIMESTAMPTZ,

  -- Avatar customization
  avatar_color VARCHAR(20),
  avatar_url TEXT,

  -- Additional notes
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_type ON customers(customer_type);
CREATE INDEX idx_customers_due ON customers(total_due);

-- Enable Row Level Security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Customers
DROP POLICY IF EXISTS "Users can view their own customers" ON customers;
CREATE POLICY "Users can view their own customers"
  ON customers FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own customers" ON customers;
CREATE POLICY "Users can insert their own customers"
  ON customers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own customers" ON customers;
CREATE POLICY "Users can update their own customers"
  ON customers FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own customers" ON customers;
CREATE POLICY "Users can delete their own customers"
  ON customers FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- 2. CREATE CUSTOMER TRANSACTIONS TABLE
-- ============================================================================

DROP TABLE IF EXISTS customer_transactions CASCADE;

CREATE TABLE customer_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),

  transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('GIVEN', 'RECEIVED')),

  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  note TEXT,
  balance DECIMAL(12, 2) NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_customer_transactions_customer_id ON customer_transactions(customer_id);
CREATE INDEX idx_customer_transactions_user_id ON customer_transactions(user_id);
CREATE INDEX idx_customer_transactions_date ON customer_transactions(transaction_date DESC);
CREATE INDEX idx_customer_transactions_type ON customer_transactions(transaction_type);
CREATE INDEX idx_customer_transactions_composite ON customer_transactions(customer_id, user_id, transaction_date DESC);

-- Enable Row Level Security
ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own transactions" ON customer_transactions;
CREATE POLICY "Users can view their own transactions" ON customer_transactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own transactions" ON customer_transactions;
CREATE POLICY "Users can create their own transactions" ON customer_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own transactions" ON customer_transactions;
CREATE POLICY "Users can update their own transactions" ON customer_transactions
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own transactions" ON customer_transactions;
CREATE POLICY "Users can delete their own transactions" ON customer_transactions
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 3. TRIGGER: Auto-update customer due balance
-- ============================================================================

DROP FUNCTION IF EXISTS update_customer_due_balance() CASCADE;

CREATE FUNCTION update_customer_due_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Update customer's total_due and is_paid status based on latest transaction
  UPDATE customers
  SET
    total_due = NEW.balance,
    is_paid = (NEW.balance <= 0),
    last_transaction_date = NEW.transaction_date,
    updated_at = NOW()
  WHERE id = NEW.customer_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on customer_transactions
DROP TRIGGER IF EXISTS trg_update_customer_due ON customer_transactions;
CREATE TRIGGER trg_update_customer_due
  AFTER INSERT OR UPDATE ON customer_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_due_balance();

-- ============================================================================
-- 4. TRIGGER: Auto-update updated_at column
-- ============================================================================

DROP FUNCTION IF EXISTS update_updated_at_column_customers() CASCADE;

CREATE FUNCTION update_updated_at_column_customers()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to customers table
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column_customers();

-- ============================================================================
-- 5. RPC FUNCTION: Add customer transaction with balance calculation
-- ============================================================================

DROP FUNCTION IF EXISTS add_customer_transaction(UUID, VARCHAR, DECIMAL, TEXT, TIMESTAMPTZ);

CREATE FUNCTION add_customer_transaction(
  p_customer_id UUID,
  p_transaction_type VARCHAR(20),
  p_amount DECIMAL(12, 2),
  p_note TEXT DEFAULT NULL,
  p_transaction_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS UUID AS $$
DECLARE
  v_current_balance DECIMAL(12, 2);
  v_new_balance DECIMAL(12, 2);
  v_transaction_id UUID;
BEGIN
  -- Validate transaction type
  IF p_transaction_type NOT IN ('GIVEN', 'RECEIVED') THEN
    RAISE EXCEPTION 'Invalid transaction type. Must be GIVEN or RECEIVED.';
  END IF;

  -- Get current balance from customer
  SELECT COALESCE(total_due, 0) INTO v_current_balance
  FROM customers
  WHERE id = p_customer_id AND user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer not found or access denied.';
  END IF;

  -- Calculate new balance
  -- GIVEN increases the due (customer owes more)
  -- RECEIVED decreases the due (customer paid back)
  IF p_transaction_type = 'GIVEN' THEN
    v_new_balance := v_current_balance + p_amount;
  ELSE
    v_new_balance := v_current_balance - p_amount;
  END IF;

  -- Insert transaction
  INSERT INTO customer_transactions (
    customer_id,
    user_id,
    transaction_date,
    transaction_type,
    amount,
    note,
    balance
  ) VALUES (
    p_customer_id,
    auth.uid(),
    p_transaction_date,
    p_transaction_type,
    p_amount,
    p_note,
    v_new_balance
  ) RETURNING id INTO v_transaction_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. RPC FUNCTION: Get customer transaction summary
-- ============================================================================

DROP FUNCTION IF EXISTS get_customer_transaction_summary(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

CREATE FUNCTION get_customer_transaction_summary(
  p_customer_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS TABLE(
  total_received DECIMAL(12, 2),
  total_given DECIMAL(12, 2),
  current_balance DECIMAL(12, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(CASE WHEN transaction_type = 'RECEIVED' THEN amount ELSE 0 END), 0) as total_received,
    COALESCE(SUM(CASE WHEN transaction_type = 'GIVEN' THEN amount ELSE 0 END), 0) as total_given,
    (SELECT total_due FROM customers WHERE id = p_customer_id) as current_balance
  FROM customer_transactions
  WHERE customer_id = p_customer_id
    AND transaction_date >= p_start_date
    AND transaction_date <= p_end_date
    AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. RPC FUNCTION: Get all transactions for a customer
-- ============================================================================

DROP FUNCTION IF EXISTS get_customer_transactions(UUID, TIMESTAMPTZ, TIMESTAMPTZ);

CREATE FUNCTION get_customer_transactions(
  p_customer_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE(
  id UUID,
  transaction_date TIMESTAMPTZ,
  transaction_type VARCHAR(20),
  amount DECIMAL(12, 2),
  note TEXT,
  balance DECIMAL(12, 2),
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ct.id,
    ct.transaction_date,
    ct.transaction_type,
    ct.amount,
    ct.note,
    ct.balance,
    ct.created_at
  FROM customer_transactions ct
  WHERE ct.customer_id = p_customer_id
    AND ct.user_id = auth.uid()
    AND (p_start_date IS NULL OR ct.transaction_date >= p_start_date)
    AND (p_end_date IS NULL OR ct.transaction_date <= p_end_date)
  ORDER BY ct.transaction_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. RPC FUNCTION: Get customers with outstanding dues
-- ============================================================================

DROP FUNCTION IF EXISTS get_customers_with_dues(BOOLEAN);

CREATE FUNCTION get_customers_with_dues(
  p_include_paid BOOLEAN DEFAULT false
)
RETURNS TABLE(
  id UUID,
  name VARCHAR,
  phone VARCHAR,
  email VARCHAR,
  total_due DECIMAL(12, 2),
  is_paid BOOLEAN,
  last_transaction_date TIMESTAMPTZ,
  transaction_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.phone,
    c.email,
    c.total_due,
    c.is_paid,
    c.last_transaction_date,
    COUNT(ct.id) as transaction_count
  FROM customers c
  LEFT JOIN customer_transactions ct ON c.id = ct.customer_id
  WHERE c.user_id = auth.uid()
    AND (p_include_paid = true OR c.is_paid = false)
  GROUP BY c.id, c.name, c.phone, c.email, c.total_due, c.is_paid, c.last_transaction_date
  ORDER BY c.total_due DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 9. HELPER VIEWS
-- ============================================================================

DROP VIEW IF EXISTS customer_dues_summary;

CREATE VIEW customer_dues_summary AS
SELECT
  c.id,
  c.name,
  c.phone,
  c.total_due,
  c.is_paid,
  c.last_transaction_date,
  COUNT(ct.id) as transaction_count,
  COALESCE(SUM(CASE WHEN ct.transaction_type = 'RECEIVED' THEN ct.amount ELSE 0 END), 0) as total_received,
  COALESCE(SUM(CASE WHEN ct.transaction_type = 'GIVEN' THEN ct.amount ELSE 0 END), 0) as total_given
FROM customers c
LEFT JOIN customer_transactions ct ON c.id = ct.customer_id AND c.user_id = ct.user_id
WHERE c.user_id = auth.uid()
GROUP BY c.id, c.name, c.phone, c.total_due, c.is_paid, c.last_transaction_date;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- You can now:
-- 1. Add new customers in your Flutter app
-- 2. Create customer transactions (GIVEN/RECEIVED)
-- 3. View customer dues summary
-- 4. Track customer payment history
-- ============================================================================

-- Verification Queries (run these to test):
-- SELECT * FROM customers;
-- SELECT * FROM customer_transactions;
-- SELECT * FROM customer_dues_summary;
-- SELECT * FROM get_customers_with_dues(false);
-- ============================================================================
