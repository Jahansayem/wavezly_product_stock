-- ================================================================
-- PURCHASE DETAILS SCHEMA FOR SUPABASE
-- ================================================================
-- Execute these queries in Supabase SQL Editor
-- This schema supports the PurchaseDetailsScreen functionality
--
-- IMPORTANT: This script is IDEMPOTENT - it can be run multiple times
-- safely without errors. It will:
-- - Create tables only if they don't exist
-- - Drop and recreate policies, triggers, and indexes
-- - Skip inserting duplicate sample data
-- ================================================================

-- ================================================================
-- 1. SUPPLIERS TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  balance DECIMAL(15, 2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT suppliers_user_id_name_unique UNIQUE (user_id, name)
);

-- Enable RLS for suppliers
DO $$ BEGIN
  ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Suppliers RLS Policies
DROP POLICY IF EXISTS "Users can view their own suppliers" ON suppliers;
CREATE POLICY "Users can view their own suppliers"
  ON suppliers FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own suppliers" ON suppliers;
CREATE POLICY "Users can insert their own suppliers"
  ON suppliers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own suppliers" ON suppliers;
CREATE POLICY "Users can update their own suppliers"
  ON suppliers FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own suppliers" ON suppliers;
CREATE POLICY "Users can delete their own suppliers"
  ON suppliers FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name);

-- ================================================================
-- 2. PURCHASES TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
  receipt_number TEXT NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'বাকি', -- বাকি (Credit) / নগদ (Cash) / মোবাইল ব্যাংকিং
  payment_status TEXT NOT NULL DEFAULT 'পরিশোধ করা হয়নি', -- পরিশোধ করা হয়নি / সম্পূর্ণ পরিশোধিত / আংশিক পরিশোধিত
  subtotal DECIMAL(15, 2) NOT NULL DEFAULT 0,
  delivery_charge DECIMAL(15, 2) DEFAULT 0,
  discount DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) NOT NULL,
  paid_amount DECIMAL(15, 2) DEFAULT 0,
  due_amount DECIMAL(15, 2) DEFAULT 0,
  notes TEXT,
  receipt_image_url TEXT,
  purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT purchases_user_id_receipt_number_unique UNIQUE (user_id, receipt_number)
);

-- Enable RLS for purchases
DO $$ BEGIN
  ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Purchases RLS Policies
DROP POLICY IF EXISTS "Users can view their own purchases" ON purchases;
CREATE POLICY "Users can view their own purchases"
  ON purchases FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own purchases" ON purchases;
CREATE POLICY "Users can insert their own purchases"
  ON purchases FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own purchases" ON purchases;
CREATE POLICY "Users can update their own purchases"
  ON purchases FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own purchases" ON purchases;
CREATE POLICY "Users can delete their own purchases"
  ON purchases FOR DELETE
  USING (auth.uid() = user_id);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON purchases(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchases_receipt_number ON purchases(receipt_number);
CREATE INDEX IF NOT EXISTS idx_purchases_purchase_date ON purchases(purchase_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_payment_status ON purchases(payment_status);

-- ================================================================
-- 3. PURCHASE_ITEMS TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS purchase_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(15, 2) NOT NULL,
  total_price DECIMAL(15, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for purchase_items
DO $$ BEGIN
  ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Purchase Items RLS Policies (inherit from purchases)
DROP POLICY IF EXISTS "Users can view their own purchase items" ON purchase_items;
CREATE POLICY "Users can view their own purchase items"
  ON purchase_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM purchases
      WHERE purchases.id = purchase_items.purchase_id
      AND purchases.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert their own purchase items" ON purchase_items;
CREATE POLICY "Users can insert their own purchase items"
  ON purchase_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM purchases
      WHERE purchases.id = purchase_items.purchase_id
      AND purchases.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update their own purchase items" ON purchase_items;
CREATE POLICY "Users can update their own purchase items"
  ON purchase_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM purchases
      WHERE purchases.id = purchase_items.purchase_id
      AND purchases.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete their own purchase items" ON purchase_items;
CREATE POLICY "Users can delete their own purchase items"
  ON purchase_items FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM purchases
      WHERE purchases.id = purchase_items.purchase_id
      AND purchases.user_id = auth.uid()
    )
  );

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id);
CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON purchase_items(product_id);

-- ================================================================
-- 4. FUNCTIONS & TRIGGERS
-- ================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_suppliers_updated_at ON suppliers;
CREATE TRIGGER update_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_purchases_updated_at ON purchases;
CREATE TRIGGER update_purchases_updated_at
  BEFORE UPDATE ON purchases
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_purchase_items_updated_at ON purchase_items;
CREATE TRIGGER update_purchase_items_updated_at
  BEFORE UPDATE ON purchase_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate purchase totals
CREATE OR REPLACE FUNCTION calculate_purchase_totals(purchase_uuid UUID)
RETURNS void AS $$
DECLARE
  items_subtotal DECIMAL(15, 2);
BEGIN
  -- Calculate subtotal from purchase items
  SELECT COALESCE(SUM(total_price), 0)
  INTO items_subtotal
  FROM purchase_items
  WHERE purchase_id = purchase_uuid;

  -- Update purchase totals
  UPDATE purchases
  SET
    subtotal = items_subtotal,
    total_amount = items_subtotal + COALESCE(delivery_charge, 0) - COALESCE(discount, 0),
    due_amount = items_subtotal + COALESCE(delivery_charge, 0) - COALESCE(discount, 0) - COALESCE(paid_amount, 0)
  WHERE id = purchase_uuid;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 5. SAMPLE DATA (Matching the UI)
-- ================================================================

-- Insert sample supplier
INSERT INTO suppliers (user_id, name, phone, address, balance)
VALUES (
  auth.uid(),
  'স্টার এন্টারপ্রাইজ',
  '+8801914794604',
  'Dhaka, Bangladesh',
  0
)
ON CONFLICT (user_id, name) DO NOTHING;

-- Insert sample purchase
INSERT INTO purchases (
  user_id,
  supplier_id,
  receipt_number,
  payment_method,
  payment_status,
  subtotal,
  delivery_charge,
  discount,
  total_amount,
  paid_amount,
  due_amount,
  notes,
  purchase_date
)
SELECT
  auth.uid(),
  (SELECT id FROM suppliers WHERE name = 'স্টার এন্টারপ্রাইজ' AND user_id = auth.uid() LIMIT 1),
  '9216735951270',
  'বাকি',
  'পরিশোধ করা হয়নি',
  13127.1,
  0,
  0,
  8865.3,
  0,
  8865.3,
  'Stock replenishment',
  '2026-01-09 00:00:00'::timestamp
WHERE NOT EXISTS (
  SELECT 1 FROM purchases
  WHERE receipt_number = '9216735951270'
  AND user_id = auth.uid()
);

-- Insert sample purchase items
INSERT INTO purchase_items (purchase_id, product_name, quantity, unit_price, total_price)
SELECT
  (SELECT id FROM purchases WHERE receipt_number = '9216735951270' AND user_id = auth.uid() LIMIT 1),
  product_name,
  quantity,
  unit_price,
  total_price
FROM (VALUES
  ('আপেল', 16, 127.2, 2035.2),
  ('আলু', 12, 30.47, 365.6),
  ('দই', 45, 229.74, 10338.1),
  ('সাবান', 32, 12.13, 388.3)
) AS items(product_name, quantity, unit_price, total_price)
WHERE NOT EXISTS (
  SELECT 1 FROM purchase_items pi
  JOIN purchases p ON pi.purchase_id = p.id
  WHERE p.receipt_number = '9216735951270'
  AND p.user_id = auth.uid()
);

-- ================================================================
-- 6. HELPER VIEWS (Optional, for easier queries)
-- ================================================================

-- View to get purchase details with supplier info
CREATE OR REPLACE VIEW purchase_details_view AS
SELECT
  p.id,
  p.receipt_number,
  p.payment_method,
  p.payment_status,
  p.subtotal,
  p.delivery_charge,
  p.discount,
  p.total_amount,
  p.paid_amount,
  p.due_amount,
  p.notes,
  p.receipt_image_url,
  p.purchase_date,
  s.id AS supplier_id,
  s.name AS supplier_name,
  s.phone AS supplier_phone,
  s.address AS supplier_address,
  s.balance AS supplier_balance,
  (
    SELECT json_agg(
      json_build_object(
        'id', pi.id,
        'product_name', pi.product_name,
        'quantity', pi.quantity,
        'unit_price', pi.unit_price,
        'total_price', pi.total_price
      )
      ORDER BY pi.created_at
    )
    FROM purchase_items pi
    WHERE pi.purchase_id = p.id
  ) AS items
FROM purchases p
LEFT JOIN suppliers s ON p.supplier_id = s.id;

-- Grant access to the view
ALTER VIEW purchase_details_view OWNER TO postgres;

-- ================================================================
-- 7. UTILITY QUERIES
-- ================================================================

-- Query to fetch a single purchase with all details
-- Usage: Replace 'YOUR_PURCHASE_ID' with actual purchase ID
/*
SELECT * FROM purchase_details_view
WHERE id = 'YOUR_PURCHASE_ID'
AND user_id = auth.uid();
*/

-- Query to fetch all purchases for a user
/*
SELECT
  p.id,
  p.receipt_number,
  p.total_amount,
  p.payment_status,
  p.purchase_date,
  s.name AS supplier_name
FROM purchases p
LEFT JOIN suppliers s ON p.supplier_id = s.id
WHERE p.user_id = auth.uid()
ORDER BY p.purchase_date DESC;
*/

-- Query to fetch purchase items for a specific purchase
/*
SELECT
  pi.product_name,
  pi.quantity,
  pi.unit_price,
  pi.total_price
FROM purchase_items pi
WHERE pi.purchase_id = 'YOUR_PURCHASE_ID'
ORDER BY pi.created_at;
*/

-- ================================================================
-- NOTES:
-- ================================================================
-- 1. All tables use UUID primary keys for better security
-- 2. RLS (Row Level Security) is enabled to ensure users only see their own data
-- 3. The schema uses Bengali text for payment methods and statuses to match the UI
-- 4. Indexes are created for commonly queried columns for better performance
-- 5. The purchase_details_view provides a convenient way to fetch all data in one query
-- 6. Make sure the 'products' table already exists before running this script
-- ================================================================
