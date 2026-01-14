-- =====================================================================
-- Quick Cash Sales Migration SQL
-- For QuickSellCashScreen
-- =====================================================================
--
-- IMPORTANT: This migration extends the existing sales table to support
-- quick cash sale metadata. The core sales/sale_items tables must already
-- exist from sales_migration.sql.
--
-- This migration is OPTIONAL and only needed if you want to track quick
-- sale specific metadata (cash received, profit margin, product details, etc.)
--
-- For the MVP implementation, you can use the existing sales table directly.
-- Execute this SQL only if you need the additional quick sale features.
-- =====================================================================

-- =====================================================================
-- 1. EXTEND SALES TABLE (Add Quick Sale Columns)
-- =====================================================================

-- Add quick sale specific columns to existing sales table
ALTER TABLE sales ADD COLUMN IF NOT EXISTS is_quick_sale BOOLEAN DEFAULT false;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cash_received DECIMAL(10, 2);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(10, 2);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS product_details TEXT;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS receipt_sms_sent BOOLEAN DEFAULT false;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS sale_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Add comments for documentation
COMMENT ON COLUMN sales.is_quick_sale IS 'Flag to identify quick cash sales from regular sales';
COMMENT ON COLUMN sales.cash_received IS 'Amount of cash received in the transaction';
COMMENT ON COLUMN sales.profit_margin IS 'Expected profit margin for the sale';
COMMENT ON COLUMN sales.product_details IS 'Free-text description of products sold';
COMMENT ON COLUMN sales.receipt_sms_sent IS 'Flag indicating if SMS receipt was sent to customer';
COMMENT ON COLUMN sales.sale_date IS 'Date of sale (can differ from created_at for backdated entries)';
COMMENT ON COLUMN sales.photo_url IS 'URL to photo attached to sale (from camera button)';

-- =====================================================================
-- 2. INDEXES for Performance
-- =====================================================================

-- Index for quick sales queries
CREATE INDEX IF NOT EXISTS idx_sales_quick_sale ON sales(is_quick_sale, created_at DESC);

-- Index for date-based queries
CREATE INDEX IF NOT EXISTS idx_sales_sale_date ON sales(sale_date DESC);

-- Index for SMS tracking
CREATE INDEX IF NOT EXISTS idx_sales_sms_sent ON sales(receipt_sms_sent) WHERE receipt_sms_sent = false;

-- Composite index for user quick sales
CREATE INDEX IF NOT EXISTS idx_sales_user_quick ON sales(user_id, is_quick_sale, sale_date DESC);

-- =====================================================================
-- 3. HELPER FUNCTIONS
-- =====================================================================

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
BEGIN
  -- Find customer by mobile number if provided
  IF p_customer_mobile IS NOT NULL AND p_customer_mobile != '' THEN
    SELECT id INTO v_customer_id
    FROM customers
    WHERE user_id = p_user_id
      AND (mobile = p_customer_mobile OR mobile = '+88' || p_customer_mobile)
    LIMIT 1;
  END IF;

  -- Create sale record
  INSERT INTO sales (
    user_id,
    customer_id,
    total_amount,
    cash_received,
    profit_margin,
    product_details,
    receipt_sms_sent,
    sale_date,
    photo_url,
    is_quick_sale,
    payment_method,
    status,
    created_at
  ) VALUES (
    p_user_id,
    v_customer_id,
    p_cash_received,  -- Total amount = cash received for quick sale
    p_cash_received,
    p_profit_margin,
    p_product_details,
    false,  -- Will be updated after SMS sent
    p_sale_date,
    p_photo_url,
    true,
    'cash',
    'completed',
    NOW()
  ) RETURNING id INTO v_sale_id;

  -- If SMS enabled, you can queue SMS send here
  -- Example: INSERT INTO sms_logs (sale_id, recipient, status) VALUES (...);
  -- Or trigger external SMS service

  RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    COALESCE(SUM(total_amount), 0) AS total_amount,
    COALESCE(SUM(profit_margin), 0) AS total_profit
  FROM sales
  WHERE user_id = p_user_id
    AND is_quick_sale = true
    AND sale_date = CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    c.mobile AS customer_mobile,
    s.receipt_sms_sent,
    s.created_at
  FROM sales s
  LEFT JOIN customers c ON s.customer_id = c.id
  WHERE s.user_id = p_user_id
    AND s.is_quick_sale = true
    AND s.sale_date BETWEEN p_start_date AND p_end_date
  ORDER BY s.sale_date DESC, s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Mark SMS as sent for a sale
CREATE OR REPLACE FUNCTION mark_sms_sent(p_sale_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE sales
  SET receipt_sms_sent = true
  WHERE id = p_sale_id AND user_id = p_user_id AND is_quick_sale = true;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    c.mobile AS customer_mobile,
    s.cash_received,
    s.sale_date,
    s.created_at
  FROM sales s
  LEFT JOIN customers c ON s.customer_id = c.id
  WHERE s.user_id = p_user_id
    AND s.is_quick_sale = true
    AND s.receipt_sms_sent = false
    AND c.mobile IS NOT NULL
  ORDER BY s.created_at ASC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 4. SAMPLE QUERIES (For Testing)
-- =====================================================================

-- Create a quick sale
-- SELECT create_quick_cash_sale(
--   auth.uid(),
--   '01712345678',
--   500.00,
--   50.00,
--   'Rice 5kg, Salt 1kg',
--   true,
--   '2026-01-14',
--   NULL
-- );

-- Get today's quick sales total
-- SELECT * FROM get_daily_quick_sales_total(auth.uid());

-- Get quick sales for current month
-- SELECT * FROM get_quick_sales_by_date_range(
--   auth.uid(),
--   date_trunc('month', CURRENT_DATE)::DATE,
--   CURRENT_DATE
-- );

-- Get all quick sales
-- SELECT * FROM sales
-- WHERE user_id = auth.uid() AND is_quick_sale = true
-- ORDER BY created_at DESC;

-- Get quick sales with customer info
-- SELECT
--   s.id,
--   s.sale_date,
--   s.cash_received,
--   s.profit_margin,
--   s.product_details,
--   c.name AS customer_name,
--   c.mobile AS customer_mobile,
--   s.receipt_sms_sent
-- FROM sales s
-- LEFT JOIN customers c ON s.customer_id = c.id
-- WHERE s.user_id = auth.uid() AND s.is_quick_sale = true
-- ORDER BY s.sale_date DESC, s.created_at DESC;

-- Mark SMS as sent
-- SELECT mark_sms_sent('sale-uuid-here', auth.uid());

-- Get pending SMS receipts
-- SELECT * FROM get_unsent_sms_receipts(auth.uid());

-- Get sales statistics by date
-- SELECT
--   sale_date,
--   COUNT(*) as sale_count,
--   SUM(cash_received) as total_revenue,
--   SUM(profit_margin) as total_profit,
--   AVG(cash_received) as avg_sale_amount
-- FROM sales
-- WHERE user_id = auth.uid() AND is_quick_sale = true
-- GROUP BY sale_date
-- ORDER BY sale_date DESC
-- LIMIT 30;

-- =====================================================================
-- 5. RLS POLICIES (Inherited from sales table)
-- =====================================================================

-- The existing RLS policies on sales table already cover quick sales
-- since they're just additional columns on the same table.
-- No additional policies needed.

-- Verify existing policies apply:
-- SELECT * FROM pg_policies WHERE tablename = 'sales';

-- =====================================================================
-- 6. DATA VALIDATION
-- =====================================================================

-- Verify migration applied successfully
-- SELECT
--   column_name,
--   data_type,
--   is_nullable,
--   column_default
-- FROM information_schema.columns
-- WHERE table_name = 'sales'
--   AND column_name IN (
--     'is_quick_sale',
--     'cash_received',
--     'profit_margin',
--     'product_details',
--     'receipt_sms_sent',
--     'sale_date',
--     'photo_url'
--   );

-- Verify functions exist
-- SELECT routine_name
-- FROM information_schema.routines
-- WHERE routine_schema = 'public'
--   AND routine_name IN (
--     'create_quick_cash_sale',
--     'get_daily_quick_sales_total',
--     'get_quick_sales_by_date_range',
--     'mark_sms_sent',
--     'get_unsent_sms_receipts'
--   );

-- Verify indexes exist
-- SELECT indexname
-- FROM pg_indexes
-- WHERE tablename = 'sales'
--   AND indexname LIKE '%quick%';

-- =====================================================================
-- 7. CLEANUP (Optional)
-- =====================================================================

-- Remove old quick sales (older than 1 year)
-- DELETE FROM sales
-- WHERE is_quick_sale = true
--   AND sale_date < CURRENT_DATE - INTERVAL '1 year'
--   AND user_id = auth.uid();

-- Reset SMS sent flags (for testing)
-- UPDATE sales
-- SET receipt_sms_sent = false
-- WHERE user_id = auth.uid() AND is_quick_sale = true;

-- =====================================================================
-- END OF MIGRATION
-- =====================================================================
