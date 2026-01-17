-- ================================================================
-- PURCHASE DETAILS MIGRATION FIX
-- ================================================================
-- This script adds missing columns to the existing purchases table
-- and creates the suppliers table and view needed for PurchaseDetailsScreen
--
-- IMPORTANT: Run this AFTER purchase_migration.sql has been executed
-- ================================================================

-- ================================================================
-- 1. Add missing columns to existing purchases table
-- ================================================================

-- Add receipt_number column (alias for purchase_number for compatibility)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'receipt_number') THEN
        ALTER TABLE purchases ADD COLUMN receipt_number TEXT;

        -- Copy existing purchase_number values to receipt_number
        UPDATE purchases SET receipt_number = purchase_number WHERE receipt_number IS NULL;

        -- Make it NOT NULL after copying data
        ALTER TABLE purchases ALTER COLUMN receipt_number SET NOT NULL;

        -- Add unique constraint
        ALTER TABLE purchases ADD CONSTRAINT purchases_user_id_receipt_number_unique
            UNIQUE (user_id, receipt_number);
    END IF;
END $$;

-- Add subtotal column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'subtotal') THEN
        ALTER TABLE purchases ADD COLUMN subtotal DECIMAL(15, 2) DEFAULT 0;

        -- Calculate subtotal from existing total_amount (assuming no delivery/discount)
        UPDATE purchases SET subtotal = total_amount WHERE subtotal = 0;
    END IF;
END $$;

-- Add delivery_charge column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'delivery_charge') THEN
        ALTER TABLE purchases ADD COLUMN delivery_charge DECIMAL(15, 2) DEFAULT 0;
    END IF;
END $$;

-- Add discount column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'discount') THEN
        ALTER TABLE purchases ADD COLUMN discount DECIMAL(15, 2) DEFAULT 0;
    END IF;
END $$;

-- Add notes column if it doesn't exist (rename from comment)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'notes') THEN
        ALTER TABLE purchases ADD COLUMN notes TEXT;

        -- Copy comment to notes if comment exists
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'comment') THEN
            UPDATE purchases SET notes = comment WHERE notes IS NULL AND comment IS NOT NULL;
        END IF;
    END IF;
END $$;

-- Add receipt_image_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'receipt_image_url') THEN
        ALTER TABLE purchases ADD COLUMN receipt_image_url TEXT;

        -- Copy receipt_image_path to receipt_image_url if it exists
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchases' AND column_name = 'receipt_image_path') THEN
            UPDATE purchases SET receipt_image_url = receipt_image_path
            WHERE receipt_image_url IS NULL AND receipt_image_path IS NOT NULL;
        END IF;
    END IF;
END $$;

-- Update payment_method to use Bengali text
DO $$
BEGIN
    -- Add mapping for existing values to Bengali
    UPDATE purchases
    SET payment_method = CASE
        WHEN payment_method = 'cash' THEN 'নগদ'
        WHEN payment_method = 'due' THEN 'বাকি'
        WHEN payment_method = 'mobile_banking' THEN 'মোবাইল ব্যাংকিং'
        WHEN payment_method = 'bank_check' THEN 'ব্যাংক চেক'
        ELSE payment_method
    END
    WHERE payment_method IN ('cash', 'due', 'mobile_banking', 'bank_check');
END $$;

-- Update payment_status to use Bengali text
DO $$
BEGIN
    UPDATE purchases
    SET payment_status = CASE
        WHEN payment_status = 'paid' THEN 'সম্পূর্ণ পরিশোধিত'
        WHEN payment_status = 'partial' THEN 'আংশিক পরিশোধিত'
        WHEN payment_status = 'due' THEN 'পরিশোধ করা হয়নি'
        ELSE payment_status
    END
    WHERE payment_status IN ('paid', 'partial', 'due');
END $$;

-- ================================================================
-- 2. Create SUPPLIERS table (separate from customers)
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name);

-- Add index for receipt_number
CREATE INDEX IF NOT EXISTS idx_purchases_receipt_number ON purchases(receipt_number);

-- ================================================================
-- 3. Add compatibility columns to purchase_items
-- ================================================================

-- Add product_name if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchase_items' AND column_name = 'product_name') THEN
        ALTER TABLE purchase_items ADD COLUMN product_name TEXT;

        -- Fetch product names from products table
        UPDATE purchase_items pi
        SET product_name = p.name
        FROM products p
        WHERE pi.product_id = p.id AND pi.product_name IS NULL;
    END IF;
END $$;

-- Add unit_price column (alias for cost_price)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchase_items' AND column_name = 'unit_price') THEN
        ALTER TABLE purchase_items ADD COLUMN unit_price DECIMAL(15, 2);

        -- Copy cost_price to unit_price if cost_price exists
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchase_items' AND column_name = 'cost_price') THEN
            UPDATE purchase_items SET unit_price = cost_price WHERE unit_price IS NULL;
        END IF;
    END IF;
END $$;

-- Add total_price column (alias for total_cost)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchase_items' AND column_name = 'total_price') THEN
        ALTER TABLE purchase_items ADD COLUMN total_price DECIMAL(15, 2);

        -- Copy total_cost to total_price if total_cost exists
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'purchase_items' AND column_name = 'total_cost') THEN
            UPDATE purchase_items SET total_price = total_cost WHERE total_price IS NULL;
        END IF;
    END IF;
END $$;

-- ================================================================
-- 4. Create VIEW for PurchaseDetailsScreen
-- ================================================================
CREATE OR REPLACE VIEW purchase_details_view AS
SELECT
  p.id,
  p.receipt_number,
  COALESCE(p.payment_method, 'বাকি') AS payment_method,
  COALESCE(p.payment_status, 'পরিশোধ করা হয়নি') AS payment_status,
  COALESCE(p.subtotal, p.total_amount) AS subtotal,
  COALESCE(p.delivery_charge, 0) AS delivery_charge,
  COALESCE(p.discount, 0) AS discount,
  p.total_amount,
  p.paid_amount,
  p.due_amount,
  p.notes,
  p.receipt_image_url,
  p.purchase_date,
  p.user_id,
  -- Try suppliers table first, fall back to customers table
  COALESCE(s.id, p.supplier_id) AS supplier_id,
  COALESCE(s.name, p.supplier_name, c.name) AS supplier_name,
  COALESCE(s.phone, c.phone) AS supplier_phone,
  COALESCE(s.address, c.address) AS supplier_address,
  COALESCE(s.balance, 0) AS supplier_balance,
  (
    SELECT json_agg(
      json_build_object(
        'id', pi.id,
        'product_name', COALESCE(pi.product_name, pr.name),
        'quantity', pi.quantity,
        'unit_price', COALESCE(pi.unit_price, pi.cost_price),
        'total_price', COALESCE(pi.total_price, pi.total_cost)
      )
      ORDER BY pi.created_at
    )
    FROM purchase_items pi
    LEFT JOIN products pr ON pi.product_id = pr.id
    WHERE pi.purchase_id = p.id
  ) AS items
FROM purchases p
LEFT JOIN suppliers s ON p.supplier_id = s.id AND s.user_id = p.user_id
LEFT JOIN customers c ON p.supplier_id = c.id AND c.user_id = p.user_id;

-- Grant access to the view
GRANT SELECT ON purchase_details_view TO authenticated;

-- ================================================================
-- 5. Insert Sample Data
-- ================================================================

-- Insert sample supplier
INSERT INTO suppliers (user_id, name, phone, address, balance)
SELECT
  auth.uid(),
  'স্টার এন্টারপ্রাইজ',
  '+8801914794604',
  'Dhaka, Bangladesh',
  0
WHERE NOT EXISTS (
  SELECT 1 FROM suppliers
  WHERE name = 'স্টার এন্টারপ্রাইজ'
  AND user_id = auth.uid()
);

-- Insert sample purchase
INSERT INTO purchases (
  user_id,
  supplier_id,
  purchase_number,
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

-- Insert sample purchase items (only if products exist)
DO $$
DECLARE
  v_purchase_id UUID;
  v_product_id UUID;
BEGIN
  -- Get the sample purchase ID
  SELECT id INTO v_purchase_id
  FROM purchases
  WHERE receipt_number = '9216735951270'
  AND user_id = auth.uid()
  LIMIT 1;

  IF v_purchase_id IS NOT NULL THEN
    -- Insert items with generic product references
    INSERT INTO purchase_items (purchase_id, product_id, product_name, quantity, unit_price, total_price, cost_price, total_cost)
    SELECT
      v_purchase_id,
      NULL, -- No specific product
      product_name,
      quantity,
      unit_price,
      total_price,
      unit_price, -- cost_price = unit_price
      total_price -- total_cost = total_price
    FROM (VALUES
      ('আপেল', 16, 127.2, 2035.2),
      ('আলু', 12, 30.47, 365.6),
      ('দই', 45, 229.74, 10338.1),
      ('সাবান', 32, 12.13, 388.3)
    ) AS items(product_name, quantity, unit_price, total_price)
    WHERE NOT EXISTS (
      SELECT 1 FROM purchase_items
      WHERE purchase_id = v_purchase_id
    );
  END IF;
END $$;

-- ================================================================
-- 6. Verification Queries
-- ================================================================

-- Check if columns exist
/*
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'purchases'
AND column_name IN ('receipt_number', 'subtotal', 'delivery_charge', 'discount', 'notes', 'receipt_image_url')
ORDER BY column_name;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'purchase_items'
AND column_name IN ('product_name', 'unit_price', 'total_price')
ORDER BY column_name;

-- Test the view
SELECT
  receipt_number,
  supplier_name,
  total_amount,
  payment_status,
  items
FROM purchase_details_view
WHERE user_id = auth.uid()
LIMIT 5;
*/

-- ================================================================
-- NOTES:
-- ================================================================
-- 1. This script adds compatibility columns without breaking existing data
-- 2. It creates aliases (receipt_number for purchase_number, etc.)
-- 3. The view handles both old and new column names
-- 4. Bengali text is added for payment methods and status
-- 5. Sample data uses the new structure but works with old schema
-- ================================================================
