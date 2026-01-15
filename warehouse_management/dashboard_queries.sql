-- ============================================================================
-- DASHBOARD SUMMARY QUERIES FOR SUPABASE
-- Execute these in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- OPTION 1: Dashboard Summary Function (Recommended)
-- Returns all dashboard metrics in a single call
-- ============================================================================

CREATE OR REPLACE FUNCTION get_dashboard_summary(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    -- Balance: Net amount (receivable - payable from customers)
    'balance', COALESCE((
      SELECT SUM(
        CASE
          WHEN total_due > 0 THEN total_due  -- Receivable (positive)
          ELSE total_due                      -- Payable (negative)
        END
      )
      FROM customers
      WHERE user_id = p_user_id
    ), 0),

    -- Today's Sales: Sum of sales from today
    'today_sales', COALESCE((
      SELECT SUM(total_amount)
      FROM sales
      WHERE user_id = p_user_id
      AND DATE(created_at) = CURRENT_DATE
    ), 0),

    -- Monthly Sales: Sum of sales from current month
    'month_sales', COALESCE((
      SELECT SUM(total_amount)
      FROM sales
      WHERE user_id = p_user_id
      AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
    ), 0),

    -- Today's Expenses: Placeholder (expand when expense feature is added)
    'today_expenses', 0,

    -- Dues Given: Total payable to suppliers (negative balances)
    'dues_given', COALESCE((
      SELECT SUM(ABS(total_due))
      FROM customers
      WHERE user_id = p_user_id
      AND total_due < 0
    ), 0),

    -- Dues to Receive: Total receivable from customers (positive balances)
    'dues_receive', COALESCE((
      SELECT SUM(total_due)
      FROM customers
      WHERE user_id = p_user_id
      AND total_due > 0
    ), 0),

    -- Stock Count: Total number of product records
    'stock_count', COALESCE((
      SELECT COUNT(*)
      FROM products
      WHERE user_id = p_user_id
    ), 0),

    -- Total Stock Quantity: Sum of all product quantities
    'total_stock_quantity', COALESCE((
      SELECT SUM(quantity)
      FROM products
      WHERE user_id = p_user_id
    ), 0)

  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_dashboard_summary(UUID) TO authenticated;


-- ============================================================================
-- OPTION 2: Individual Helper Functions
-- Useful if you need granular control or want to call specific metrics
-- ============================================================================

-- Get today's sales for a user
CREATE OR REPLACE FUNCTION get_today_sales(p_user_id UUID)
RETURNS NUMERIC AS $$
BEGIN
  RETURN COALESCE((
    SELECT SUM(total_amount)
    FROM sales
    WHERE user_id = p_user_id
    AND DATE(created_at) = CURRENT_DATE
  ), 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get monthly sales for a user
CREATE OR REPLACE FUNCTION get_monthly_sales(p_user_id UUID)
RETURNS NUMERIC AS $$
BEGIN
  RETURN COALESCE((
    SELECT SUM(total_amount)
    FROM sales
    WHERE user_id = p_user_id
    AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)
  ), 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get customer balance summary
CREATE OR REPLACE FUNCTION get_customer_balance_summary(p_user_id UUID)
RETURNS JSON AS $$
BEGIN
  RETURN json_build_object(
    'to_receive', COALESCE((
      SELECT SUM(total_due)
      FROM customers
      WHERE user_id = p_user_id AND total_due > 0
    ), 0),
    'to_give', COALESCE((
      SELECT SUM(ABS(total_due))
      FROM customers
      WHERE user_id = p_user_id AND total_due < 0
    ), 0),
    'net_balance', COALESCE((
      SELECT SUM(total_due)
      FROM customers
      WHERE user_id = p_user_id
    ), 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get stock summary
CREATE OR REPLACE FUNCTION get_stock_summary(p_user_id UUID)
RETURNS JSON AS $$
BEGIN
  RETURN json_build_object(
    'total_products', COALESCE((
      SELECT COUNT(*) FROM products WHERE user_id = p_user_id
    ), 0),
    'total_quantity', COALESCE((
      SELECT SUM(quantity) FROM products WHERE user_id = p_user_id
    ), 0),
    'low_stock_count', COALESCE((
      SELECT COUNT(*) FROM products
      WHERE user_id = p_user_id AND quantity <= 5
    ), 0),
    'out_of_stock_count', COALESCE((
      SELECT COUNT(*) FROM products
      WHERE user_id = p_user_id AND quantity = 0
    ), 0),
    'expiring_soon', COALESCE((
      SELECT COUNT(*) FROM products
      WHERE user_id = p_user_id
      AND expiry_date IS NOT NULL
      AND expiry_date <= CURRENT_DATE + INTERVAL '30 days'
    ), 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_today_sales(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_monthly_sales(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_customer_balance_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_stock_summary(UUID) TO authenticated;


-- ============================================================================
-- OPTION 3: Dashboard Summary View (Alternative to functions)
-- Creates a view that can be queried directly
-- ============================================================================

-- Note: Views don't support RLS filtering by user_id automatically,
-- so functions are preferred for multi-tenant data.
-- This view is shown for reference only.

-- CREATE OR REPLACE VIEW dashboard_summary_view AS
-- SELECT
--   p.id as user_id,
--   COALESCE((SELECT SUM(total_due) FROM customers WHERE user_id = p.id), 0) as balance,
--   COALESCE((SELECT SUM(total_amount) FROM sales WHERE user_id = p.id AND DATE(created_at) = CURRENT_DATE), 0) as today_sales,
--   COALESCE((SELECT COUNT(*) FROM products WHERE user_id = p.id), 0) as stock_count
-- FROM profiles p;


-- ============================================================================
-- SAMPLE USAGE IN FLUTTER (for reference)
-- ============================================================================

-- In Dart code:
--
-- // Call the main dashboard function
-- final response = await supabase.rpc('get_dashboard_summary', params: {
--   'p_user_id': supabase.auth.currentUser!.id,
-- });
--
-- // Parse the result
-- final Map<String, dynamic> data = response as Map<String, dynamic>;
-- final double balance = (data['balance'] as num).toDouble();
-- final double todaySales = (data['today_sales'] as num).toDouble();
-- final int stockCount = data['stock_count'] as int;
--
-- // Or call individual functions
-- final todaySales = await supabase.rpc('get_today_sales', params: {
--   'p_user_id': supabase.auth.currentUser!.id,
-- });


-- ============================================================================
-- MIGRATION: Add expense tracking table (optional, for future use)
-- ============================================================================

-- Uncomment and run this if you want to track expenses

-- CREATE TABLE IF NOT EXISTS expenses (
--   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--   user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--   amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
--   category TEXT,
--   description TEXT,
--   expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
--   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
--   updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- -- Enable RLS
-- ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- -- RLS Policy: Users can only see their own expenses
-- CREATE POLICY "Users can manage their own expenses"
--   ON expenses
--   FOR ALL
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

-- -- Add index for faster queries
-- CREATE INDEX idx_expenses_user_date ON expenses(user_id, expense_date);

-- -- Updated get_dashboard_summary to include expenses (if expenses table exists)
-- -- Replace the 'today_expenses' line in get_dashboard_summary with:
-- -- 'today_expenses', COALESCE((
-- --   SELECT SUM(amount)
-- --   FROM expenses
-- --   WHERE user_id = p_user_id
-- --   AND expense_date = CURRENT_DATE
-- -- ), 0),
