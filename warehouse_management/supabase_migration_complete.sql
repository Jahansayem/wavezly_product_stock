-- ================================================================
-- SHOPSTOCK COMPLETE DATABASE MIGRATION SCRIPT
-- Execute this in Supabase SQL Editor
-- Safe to run multiple times - uses IF NOT EXISTS / DO blocks
-- ================================================================

-- ================================================================
-- PRIORITY 1: Add Missing Columns to sales table (Quick Sell)
-- ================================================================

ALTER TABLE sales ADD COLUMN IF NOT EXISTS is_quick_sale BOOLEAN DEFAULT false;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cash_received DECIMAL(10, 2);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(10, 2);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS product_details TEXT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS receipt_sms_sent BOOLEAN DEFAULT false;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS sale_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id) ON DELETE SET NULL;

-- Comments for documentation
COMMENT ON COLUMN sales.is_quick_sale IS 'Flag to identify quick cash sales from regular sales';
COMMENT ON COLUMN sales.cash_received IS 'Amount of cash received in the transaction';
COMMENT ON COLUMN sales.profit_margin IS 'Expected profit margin for the sale';
COMMENT ON COLUMN sales.product_details IS 'Free-text description of products sold';
COMMENT ON COLUMN sales.receipt_sms_sent IS 'Flag indicating if SMS receipt was sent to customer';
COMMENT ON COLUMN sales.sale_date IS 'Date of sale (can differ from created_at for backdated entries)';
COMMENT ON COLUMN sales.photo_url IS 'URL to photo attached to sale';

-- ================================================================
-- PRIORITY 1: Add Missing Columns to purchases table
-- ================================================================

ALTER TABLE purchases ADD COLUMN IF NOT EXISTS receipt_number TEXT;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS subtotal DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS delivery_charge DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS discount DECIMAL(15, 2) DEFAULT 0;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE purchases ADD COLUMN IF NOT EXISTS receipt_image_url TEXT;

-- Copy purchase_number to receipt_number where null
UPDATE purchases SET receipt_number = purchase_number WHERE receipt_number IS NULL;

-- Copy comment to notes where applicable
UPDATE purchases SET notes = comment WHERE notes IS NULL AND comment IS NOT NULL;

-- Copy receipt_image_path to receipt_image_url where applicable
UPDATE purchases SET receipt_image_url = receipt_image_path WHERE receipt_image_url IS NULL AND receipt_image_path IS NOT NULL;

-- Calculate subtotal from total_amount where subtotal is 0
UPDATE purchases SET subtotal = total_amount WHERE subtotal = 0 OR subtotal IS NULL;

-- ================================================================
-- PRIORITY 1: Add Missing Columns to purchase_items table
-- ================================================================

ALTER TABLE purchase_items ADD COLUMN IF NOT EXISTS unit_price DECIMAL(15, 2);
ALTER TABLE purchase_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(15, 2);

-- Copy cost_price to unit_price where null
UPDATE purchase_items SET unit_price = cost_price WHERE unit_price IS NULL;

-- Copy total_cost to total_price where null
UPDATE purchase_items SET total_price = total_cost WHERE total_price IS NULL;

-- ================================================================
-- PRIORITY 1: Create Missing Indexes for Quick Sell
-- ================================================================

CREATE INDEX IF NOT EXISTS idx_sales_quick_sale ON sales(is_quick_sale, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON sales(sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_sms_sent ON sales(receipt_sms_sent) WHERE receipt_sms_sent = false;
CREATE INDEX IF NOT EXISTS idx_sales_user_quick ON sales(user_id, is_quick_sale, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id);

-- ================================================================
-- PRIORITY 1: Add Missing Triggers
-- ================================================================

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

-- ================================================================
-- PRIORITY 1: Create Missing Quick Sell Functions
-- ================================================================

-- Function: Create quick cash sale
CREATE OR REPLACE FUNCTION create_quick_cash_sale(
  p_user_id UUID,
  p_customer_mobile TEXT DEFAULT NULL,
  p_cash_received DECIMAL(10, 2),
  p_profit_margin DECIMAL(10, 2) DEFAULT 0,
  p_product_details TEXT DEFAULT NULL,
  p_receipt_sms_enabled BOOLEAN DEFAULT true,
  p_sale_date DATE DEFAULT CURRENT_DATE,
  p_photo_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_sale_id UUID;
  v_customer_id UUID := NULL;
  v_sale_number TEXT;
BEGIN
  -- Find customer by mobile number if provided
  IF p_customer_mobile IS NOT NULL AND p_customer_mobile != '' THEN
    SELECT id INTO v_customer_id
    FROM customers
    WHERE user_id = p_user_id
      AND (phone = p_customer_mobile OR phone = '+88' || p_customer_mobile)
    LIMIT 1;
  END IF;

  -- Generate sale number
  SELECT generate_sale_number() INTO v_sale_number;

  -- Create sale record
  INSERT INTO sales (
    sale_number, user_id, customer_id,
    total_amount, subtotal, tax_amount,
    cash_received, profit_margin, product_details,
    receipt_sms_sent, sale_date, photo_url,
    is_quick_sale, payment_method, payment_status
  ) VALUES (
    v_sale_number, p_user_id, v_customer_id,
    p_cash_received, p_cash_received, 0,
    p_cash_received, p_profit_margin, p_product_details,
    false, p_sale_date, p_photo_url,
    true, 'cash', 'paid'
  ) RETURNING id INTO v_sale_id;

  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Function: Get today's quick sales total for user
CREATE OR REPLACE FUNCTION get_daily_quick_sales_total(p_user_id UUID)
RETURNS TABLE (
  total_sales BIGINT,
  total_amount DECIMAL(10, 2),
  total_profit DECIMAL(10, 2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_sales,
    COALESCE(SUM(s.total_amount), 0) AS total_amount,
    COALESCE(SUM(s.profit_margin), 0) AS total_profit
  FROM sales s
  WHERE s.user_id = p_user_id
    AND s.is_quick_sale = true
    AND s.sale_date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Function: Get quick sales by date range
CREATE OR REPLACE FUNCTION get_quick_sales_by_date_range(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  sale_id UUID,
  sale_date DATE,
  cash_received DECIMAL(10, 2),
  profit_margin DECIMAL(10, 2),
  product_details TEXT,
  customer_mobile TEXT,
  receipt_sms_sent BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id AS sale_id,
    s.sale_date,
    s.cash_received,
    s.profit_margin,
    s.product_details,
    c.phone AS customer_mobile,
    s.receipt_sms_sent,
    s.created_at
  FROM sales s
  LEFT JOIN customers c ON s.customer_id = c.id
  WHERE s.user_id = p_user_id
    AND s.is_quick_sale = true
    AND s.sale_date BETWEEN p_start_date AND p_end_date
  ORDER BY s.sale_date DESC, s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Function: Mark SMS as sent for a sale
CREATE OR REPLACE FUNCTION mark_sms_sent(p_sale_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE sales
  SET receipt_sms_sent = true
  WHERE id = p_sale_id AND user_id = p_user_id AND is_quick_sale = true;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Function: Get unsent SMS receipts
CREATE OR REPLACE FUNCTION get_unsent_sms_receipts(p_user_id UUID)
RETURNS TABLE (
  sale_id UUID,
  customer_mobile TEXT,
  cash_received DECIMAL(10, 2),
  sale_date DATE,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id AS sale_id,
    c.phone AS customer_mobile,
    s.cash_received,
    s.sale_date,
    s.created_at
  FROM sales s
  LEFT JOIN customers c ON s.customer_id = c.id
  WHERE s.user_id = p_user_id
    AND s.is_quick_sale = true
    AND s.receipt_sms_sent = false
    AND c.phone IS NOT NULL
  ORDER BY s.created_at ASC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Function: Calculate purchase totals
CREATE OR REPLACE FUNCTION calculate_purchase_totals(purchase_uuid UUID)
RETURNS void AS $$
DECLARE
  items_subtotal DECIMAL(15, 2);
BEGIN
  SELECT COALESCE(SUM(total_cost), 0)
  INTO items_subtotal
  FROM purchase_items
  WHERE purchase_id = purchase_uuid;

  UPDATE purchases
  SET
    subtotal = items_subtotal,
    total_amount = items_subtotal + COALESCE(delivery_charge, 0) - COALESCE(discount, 0),
    due_amount = items_subtotal + COALESCE(delivery_charge, 0) - COALESCE(discount, 0) - COALESCE(paid_amount, 0)
  WHERE id = purchase_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ================================================================
-- PRIORITY 2: Fix Views to use SECURITY INVOKER
-- ================================================================

-- Recreate customer_dues_summary with SECURITY INVOKER
DROP VIEW IF EXISTS customer_dues_summary;
CREATE VIEW customer_dues_summary AS
SELECT
  c.id,
  c.name,
  c.phone,
  c.total_due,
  c.is_paid,
  c.last_transaction_date,
  count(ct.id) AS transaction_count,
  COALESCE(sum(CASE WHEN ct.transaction_type = 'RECEIVED' THEN ct.amount ELSE 0 END), 0) AS total_received,
  COALESCE(sum(CASE WHEN ct.transaction_type = 'GIVEN' THEN ct.amount ELSE 0 END), 0) AS total_given
FROM customers c
LEFT JOIN customer_transactions ct ON c.id = ct.customer_id AND c.user_id = ct.user_id
WHERE c.user_id = auth.uid()
GROUP BY c.id, c.name, c.phone, c.total_due, c.is_paid, c.last_transaction_date;

ALTER VIEW customer_dues_summary SET (security_invoker = true);

-- Recreate customer_due_summary with SECURITY INVOKER
DROP VIEW IF EXISTS customer_due_summary;
CREATE VIEW customer_due_summary AS
SELECT
  c.id,
  c.name,
  c.phone,
  c.total_due,
  c.last_transaction_date,
  count(ct.id) AS transaction_count,
  COALESCE(sum(CASE WHEN ct.transaction_subtype = 'give_due' THEN ct.amount ELSE 0 END), 0) AS total_given,
  COALESCE(sum(CASE WHEN ct.transaction_subtype = 'take_due' THEN abs(ct.amount) ELSE 0 END), 0) AS total_received,
  COALESCE(max(ct.created_at), c.created_at) AS last_activity
FROM customers c
LEFT JOIN customer_transactions ct ON c.id = ct.customer_id
  AND ct.transaction_subtype IN ('give_due', 'take_due')
WHERE c.user_id = auth.uid()
GROUP BY c.id, c.name, c.phone, c.total_due, c.last_transaction_date, c.created_at
ORDER BY c.total_due DESC;

ALTER VIEW customer_due_summary SET (security_invoker = true);

-- ================================================================
-- PRIORITY 3: Create purchase_details_view (Optional)
-- ================================================================

CREATE OR REPLACE VIEW purchase_details_view AS
SELECT
  p.id,
  COALESCE(p.receipt_number, p.purchase_number) AS receipt_number,
  p.payment_method,
  p.payment_status,
  COALESCE(p.subtotal, p.total_amount) AS subtotal,
  COALESCE(p.delivery_charge, 0) AS delivery_charge,
  COALESCE(p.discount, 0) AS discount,
  p.total_amount,
  p.paid_amount,
  p.due_amount,
  COALESCE(p.notes, p.comment) AS notes,
  COALESCE(p.receipt_image_url, p.receipt_image_path) AS receipt_image_url,
  p.purchase_date,
  p.user_id,
  p.supplier_id,
  p.supplier_name,
  c.phone AS supplier_phone,
  c.address AS supplier_address,
  (
    SELECT json_agg(
      json_build_object(
        'id', pi.id,
        'product_name', pi.product_name,
        'quantity', pi.quantity,
        'unit_price', COALESCE(pi.unit_price, pi.cost_price),
        'total_price', COALESCE(pi.total_price, pi.total_cost)
      )
      ORDER BY pi.created_at
    )
    FROM purchase_items pi
    WHERE pi.purchase_id = p.id
  ) AS items
FROM purchases p
LEFT JOIN customers c ON p.supplier_id = c.id AND c.user_id = p.user_id;

ALTER VIEW purchase_details_view SET (security_invoker = true);

-- ================================================================
-- Grant execute permissions
-- ================================================================

GRANT EXECUTE ON FUNCTION create_quick_cash_sale TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_quick_sales_total TO authenticated;
GRANT EXECUTE ON FUNCTION get_quick_sales_by_date_range TO authenticated;
GRANT EXECUTE ON FUNCTION mark_sms_sent TO authenticated;
GRANT EXECUTE ON FUNCTION get_unsent_sms_receipts TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_purchase_totals TO authenticated;

-- ================================================================
-- VERIFICATION QUERIES (Run after migration to confirm)
-- ================================================================

-- Verify new columns on sales
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sales'
AND column_name IN ('is_quick_sale', 'cash_received', 'profit_margin', 'sale_date', 'receipt_sms_sent', 'product_details', 'photo_url', 'customer_id')
ORDER BY column_name;

-- Verify new columns on purchases
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'purchases'
AND column_name IN ('receipt_number', 'subtotal', 'delivery_charge', 'discount', 'notes', 'receipt_image_url')
ORDER BY column_name;

-- Verify new functions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('create_quick_cash_sale', 'get_daily_quick_sales_total', 'get_quick_sales_by_date_range', 'mark_sms_sent', 'get_unsent_sms_receipts', 'calculate_purchase_totals')
ORDER BY routine_name;

-- Verify indexes
SELECT indexname
FROM pg_indexes
WHERE tablename = 'sales'
AND indexname LIKE 'idx_sales_%'
ORDER BY indexname;

-- ================================================================
-- END OF MIGRATION SCRIPT
-- ================================================================
