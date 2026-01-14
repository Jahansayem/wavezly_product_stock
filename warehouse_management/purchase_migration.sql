-- Purchase Migration SQL
-- Run this in Supabase SQL Editor to create purchase tables and functions
-- This enables product buying/procurement functionality with supplier management

-- Purchases table (header records)
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_number TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Supplier information (references customers table with type='supplier')
  supplier_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  supplier_name TEXT,

  -- Amount breakdown
  total_amount DECIMAL(12, 2) NOT NULL CHECK (total_amount >= 0),
  paid_amount DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  due_amount DECIMAL(12, 2) NOT NULL DEFAULT 0 CHECK (due_amount >= 0),
  cash_given DECIMAL(12, 2),
  change_amount DECIMAL(12, 2),

  -- Payment details
  payment_method VARCHAR(50) NOT NULL DEFAULT 'cash'
    CHECK (payment_method IN ('cash', 'due', 'mobile_banking', 'bank_check')),
  payment_status VARCHAR(50) NOT NULL DEFAULT 'paid'
    CHECK (payment_status IN ('paid', 'partial', 'due')),

  -- Additional information
  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  receipt_image_path TEXT,
  comment TEXT,
  sms_enabled BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  UNIQUE(purchase_number, user_id),
  CONSTRAINT valid_amounts CHECK (total_amount = paid_amount + due_amount)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_created_at ON purchases(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchases_purchase_date ON purchases(purchase_date DESC);

-- Purchase items table (line items)
CREATE TABLE IF NOT EXISTS purchase_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,

  product_name TEXT NOT NULL,
  cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  total_cost DECIMAL(12, 2) NOT NULL CHECK (total_cost >= 0),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_total CHECK (total_cost = cost_price * quantity)
);

-- Indexes for purchase items
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON purchase_items(product_id);

-- Enable Row Level Security
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for purchases table
DROP POLICY IF EXISTS "Users view own purchases" ON purchases;
CREATE POLICY "Users view own purchases"
  ON purchases FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own purchases" ON purchases;
CREATE POLICY "Users insert own purchases"
  ON purchases FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own purchases" ON purchases;
CREATE POLICY "Users update own purchases"
  ON purchases FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for purchase_items table
DROP POLICY IF EXISTS "Users view own purchase_items" ON purchase_items;
CREATE POLICY "Users view own purchase_items"
  ON purchase_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM purchases
    WHERE purchases.id = purchase_items.purchase_id
    AND purchases.user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Users insert own purchase_items" ON purchase_items;
CREATE POLICY "Users insert own purchase_items"
  ON purchase_items FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM purchases
    WHERE purchases.id = purchase_items.purchase_id
    AND purchases.user_id = auth.uid()
  ));

-- Function to generate unique purchase numbers
-- Format: PURCHASE-YYYYMMDD-0001
CREATE OR REPLACE FUNCTION generate_purchase_number()
RETURNS TEXT AS $$
DECLARE
  v_date TEXT;
  v_count INT;
BEGIN
  v_date := TO_CHAR(NOW(), 'YYYYMMDD');

  SELECT COUNT(*) INTO v_count
  FROM purchases
  WHERE user_id = auth.uid()
    AND DATE(created_at) = CURRENT_DATE;

  RETURN 'PURCHASE-' || v_date || '-' || LPAD((v_count + 1)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to process purchase transaction atomically
-- This function handles:
-- 1. Creating purchase record
-- 2. Creating purchase item records
-- 3. ADDING to product inventory (opposite of sales)
-- 4. Updating supplier due balance (if applicable)
-- 5. Creating customer transaction record (if supplier + due payment)
CREATE OR REPLACE FUNCTION process_purchase(
  p_purchase_data JSONB,
  p_purchase_items JSONB[]
) RETURNS UUID AS $$
DECLARE
  v_purchase_id UUID;
  v_item JSONB;
  v_product_id UUID;
  v_quantity INT;
  v_supplier_id UUID;
  v_due_amount DECIMAL;
  v_payment_method TEXT;
  v_current_due DECIMAL;
BEGIN
  -- Extract key values
  v_supplier_id := (p_purchase_data->>'supplier_id')::UUID;
  v_due_amount := (p_purchase_data->>'due_amount')::DECIMAL;
  v_payment_method := p_purchase_data->>'payment_method';

  -- Insert purchase record
  INSERT INTO purchases (
    purchase_number, user_id, supplier_id, supplier_name,
    total_amount, paid_amount, due_amount, cash_given, change_amount,
    payment_method, payment_status, purchase_date,
    receipt_image_path, comment, sms_enabled
  ) VALUES (
    p_purchase_data->>'purchase_number',
    auth.uid(),
    v_supplier_id,
    p_purchase_data->>'supplier_name',
    (p_purchase_data->>'total_amount')::DECIMAL,
    (p_purchase_data->>'paid_amount')::DECIMAL,
    v_due_amount,
    (p_purchase_data->>'cash_given')::DECIMAL,
    (p_purchase_data->>'change_amount')::DECIMAL,
    v_payment_method,
    CASE
      WHEN v_due_amount > 0 THEN 'due'
      WHEN (p_purchase_data->>'paid_amount')::DECIMAL < (p_purchase_data->>'total_amount')::DECIMAL THEN 'partial'
      ELSE 'paid'
    END,
    (p_purchase_data->>'purchase_date')::DATE,
    p_purchase_data->>'receipt_image_path',
    p_purchase_data->>'comment',
    (p_purchase_data->>'sms_enabled')::BOOLEAN
  ) RETURNING id INTO v_purchase_id;

  -- Process each purchase item
  FOREACH v_item IN ARRAY p_purchase_items LOOP
    v_product_id := (v_item->>'product_id')::UUID;
    v_quantity := (v_item->>'quantity')::INT;

    -- Insert purchase item
    INSERT INTO purchase_items (
      purchase_id, product_id, product_name,
      cost_price, quantity, total_cost
    ) VALUES (
      v_purchase_id,
      v_product_id,
      v_item->>'product_name',
      (v_item->>'cost_price')::DECIMAL,
      v_quantity,
      (v_item->>'total_cost')::DECIMAL
    );

    -- ADD to inventory (opposite of sales which SUBTRACT)
    UPDATE products
    SET quantity = quantity + v_quantity,
        updated_at = NOW()
    WHERE id = v_product_id
      AND user_id = auth.uid();

    -- Verify product update succeeded
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Product not found: %', v_item->>'product_name';
    END IF;
  END LOOP;

  -- Update supplier due balance and create transaction (if applicable)
  -- Convention: negative total_due means we owe the supplier
  -- Purchase on due = subtract from total_due (makes it more negative)
  IF v_supplier_id IS NOT NULL AND v_payment_method = 'due' AND v_due_amount > 0 THEN
    -- Get current due balance
    SELECT total_due INTO v_current_due
    FROM customers
    WHERE id = v_supplier_id AND user_id = auth.uid();

    -- Update supplier due balance
    UPDATE customers
    SET total_due = total_due - v_due_amount,
        last_transaction_date = NOW(),
        updated_at = NOW()
    WHERE id = v_supplier_id
      AND user_id = auth.uid();

    -- Create customer transaction record
    INSERT INTO customer_transactions (
      customer_id,
      user_id,
      transaction_date,
      transaction_type,
      amount,
      balance,
      note
    ) VALUES (
      v_supplier_id,
      auth.uid(),
      NOW(),
      'GIVEN',
      v_due_amount,
      v_current_due - v_due_amount,
      'Purchase: ' || (p_purchase_data->>'purchase_number')
    );
  END IF;

  RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on functions
GRANT EXECUTE ON FUNCTION generate_purchase_number() TO authenticated;
GRANT EXECUTE ON FUNCTION process_purchase(JSONB, JSONB[]) TO authenticated;

-- Verification queries (run these after migration to verify setup)
-- SELECT table_name FROM information_schema.tables WHERE table_name IN ('purchases', 'purchase_items');
-- SELECT proname FROM pg_proc WHERE proname IN ('generate_purchase_number', 'process_purchase');
