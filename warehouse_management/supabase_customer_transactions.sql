-- ============================================================================
-- Supabase Schema: Customer Transactions & Dues Management
-- ============================================================================
-- This file contains all database schema for customer due/receivable tracking
-- Execute this in Supabase SQL Editor before using the Due Details screen
-- ============================================================================

-- ============================================================================
-- 1. CUSTOMER TRANSACTIONS TABLE
-- ============================================================================
-- Stores all customer due transactions (money given/received)

-- Drop existing table and related objects if they exist
DROP TRIGGER IF EXISTS trg_update_customer_due ON customer_transactions;
DROP TABLE IF EXISTS customer_transactions CASCADE;

-- Create the table from scratch
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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Indexes for performance
CREATE INDEX idx_customer_transactions_customer_id ON customer_transactions(customer_id);
CREATE INDEX idx_customer_transactions_user_id ON customer_transactions(user_id);
CREATE INDEX idx_customer_transactions_date ON customer_transactions(transaction_date DESC);
CREATE INDEX idx_customer_transactions_type ON customer_transactions(transaction_type);
CREATE INDEX idx_customer_transactions_composite ON customer_transactions(customer_id, user_id, transaction_date DESC);

-- Row Level Security (RLS) policies
ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own transactions
DROP POLICY IF EXISTS "Users can view their own transactions" ON customer_transactions;
CREATE POLICY "Users can view their own transactions" ON customer_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can create their own transactions
DROP POLICY IF EXISTS "Users can create their own transactions" ON customer_transactions;
CREATE POLICY "Users can create their own transactions" ON customer_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own transactions
DROP POLICY IF EXISTS "Users can update their own transactions" ON customer_transactions;
CREATE POLICY "Users can update their own transactions" ON customer_transactions
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own transactions
DROP POLICY IF EXISTS "Users can delete their own transactions" ON customer_transactions;
CREATE POLICY "Users can delete their own transactions" ON customer_transactions
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 2. UPDATE CUSTOMERS TABLE
-- ============================================================================
-- Add due-related columns to existing customers table if they don't exist

ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_due DECIMAL(12, 2) DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT true;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_transaction_date TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing customers to have default values
UPDATE customers SET total_due = 0 WHERE total_due IS NULL;
UPDATE customers SET is_paid = true WHERE is_paid IS NULL;
UPDATE customers SET updated_at = NOW() WHERE updated_at IS NULL;

-- ============================================================================
-- 3. TRIGGER FUNCTION: Auto-update customer due balance
-- ============================================================================
-- Automatically updates customer's total_due, is_paid status after transaction

-- Drop existing function (trigger already dropped with table)
DROP FUNCTION IF EXISTS update_customer_due_balance();

-- Create the trigger function
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
CREATE TRIGGER trg_update_customer_due
  AFTER INSERT OR UPDATE ON customer_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_due_balance();

-- ============================================================================
-- 4. RPC FUNCTION: Get transaction summary for date range
-- ============================================================================
-- Returns total received, total given, and current balance for a customer

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
-- 5. RPC FUNCTION: Add new customer transaction with balance calculation
-- ============================================================================
-- Safely adds a new transaction and automatically calculates the new balance

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
-- 6. RPC FUNCTION: Get all transactions for a customer with date filtering
-- ============================================================================
-- Returns list of transactions for a customer within a date range

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
-- 7. SAMPLE DATA (Optional - for testing)
-- ============================================================================
-- Uncomment below to insert sample transactions for testing

/*
-- Sample: Add a customer transaction (GIVEN)
SELECT add_customer_transaction(
  '<customer-uuid-here>',
  'GIVEN',
  4000.00,
  'fitra',
  '2025-03-28 15:40:00'::TIMESTAMPTZ
);

-- Sample: Add a customer transaction (RECEIVED)
SELECT add_customer_transaction(
  '<customer-uuid-here>',
  'RECEIVED',
  1000.00,
  'Rakib',
  '2025-03-30 23:08:00'::TIMESTAMPTZ
);

-- Sample: Add another GIVEN transaction
SELECT add_customer_transaction(
  '<customer-uuid-here>',
  'GIVEN',
  70000.00,
  'cycle babod',
  '2025-04-27 22:37:00'::TIMESTAMPTZ
);
*/

-- ============================================================================
-- 8. HELPER VIEWS (Optional)
-- ============================================================================

-- View: Customer dues summary
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
-- 9. UTILITY FUNCTIONS
-- ============================================================================

-- Function: Get customers with outstanding dues
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
-- SETUP COMPLETE
-- ============================================================================
-- All tables, indexes, triggers, and functions have been created.
-- Run this SQL in Supabase SQL Editor, then use the Due Details screen in Flutter.
-- ============================================================================
