-- Purchase Book Screen SQL Setup
-- This file contains any database verification queries needed for the Purchase Book feature
-- Run these queries in your Supabase SQL Editor to verify the setup

-- ============================================================================
-- VERIFICATION QUERIES (No changes needed - just verify existing schema)
-- ============================================================================

-- 1. Verify purchases table exists with all required columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'purchases'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Expected columns:
-- - id (uuid)
-- - purchase_number (text)
-- - user_id (uuid)
-- - supplier_id (text)
-- - supplier_name (text)
-- - total_amount (numeric)
-- - paid_amount (numeric)
-- - due_amount (numeric)
-- - cash_given (numeric)
-- - change_amount (numeric)
-- - payment_method (varchar) - 'cash', 'mobile_banking', 'due', 'bank_check'
-- - payment_status (varchar) - 'paid', 'partial', 'due'
-- - purchase_date (date)
-- - receipt_image_path (text)
-- - comment (text)
-- - sms_enabled (boolean)
-- - created_at (timestamptz)
-- - updated_at (timestamptz)

-- 2. Verify RLS (Row Level Security) is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'purchases';

-- 3. Check existing purchases count
SELECT COUNT(*) as total_purchases,
       COUNT(DISTINCT supplier_name) as unique_suppliers,
       SUM(total_amount) as total_purchase_value
FROM purchases;

-- 4. Verify generate_purchase_number RPC function exists
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'generate_purchase_number';

-- 5. Sample query to test data retrieval (same as PurchaseService.getAllPurchases())
SELECT id, purchase_number, supplier_name, total_amount, payment_method, payment_status, purchase_date
FROM purchases
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- OPTIONAL: CREATE SAMPLE DATA FOR TESTING (Development Only)
-- ============================================================================

-- Uncomment below to create sample purchase data for testing
-- WARNING: Only run this in development environment, not production!

/*
-- Insert sample purchases
INSERT INTO purchases (
  purchase_number,
  user_id,
  supplier_id,
  supplier_name,
  total_amount,
  paid_amount,
  due_amount,
  payment_method,
  payment_status,
  purchase_date,
  comment
) VALUES
  ('PBZSFVQP0A1DXNH', auth.uid(), 'SUP001', 'বেঙ্গল ট্রেডিং কোং', 1333.9, 0, 1333.9, 'due', 'due', '2026-01-13', 'Stock replenishment'),
  ('0F01YN3W82045RJ', auth.uid(), 'SUP002', 'স্টার এন্টারপ্রাইজ', 3547.7, 3547.7, 0, 'mobile_banking', 'paid', '2026-01-10', 'Stock replenishment'),
  ('0WRWRNR1F9W3DVS', auth.uid(), 'SUP003', 'গোল্ডেন ট্রেড হাউস', 5229.7, 5229.7, 0, 'cash', 'paid', '2026-01-09', 'Stock replenishment'),
  ('DBHX1RRGF4R33DQ', auth.uid(), 'SUP004', 'মেট্রো ট্রেডিং', 7307.4, 0, 7307.4, 'due', 'due', '2026-01-07', 'Stock replenishment'),
  ('5KWQQ3Q28SWKDZJ', auth.uid(), 'SUP001', 'বেঙ্গল ট্রেডিং কোং', 5690.2, 5690.2, 0, 'mobile_banking', 'paid', '2026-01-04', 'Stock replenishment');
*/

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. NO DATABASE SCHEMA CHANGES REQUIRED
--    The purchases table already has all necessary columns for the Purchase Book feature.
--
-- 2. RLS POLICIES
--    Row Level Security should already be configured to filter purchases by user_id.
--    Users will only see their own purchases.
--
-- 3. INDEXES (Optional Performance Optimization)
--    Consider adding these indexes if you have 1000+ purchases:
--
--    CREATE INDEX IF NOT EXISTS idx_purchases_user_date
--    ON purchases(user_id, purchase_date DESC);
--
--    CREATE INDEX IF NOT EXISTS idx_purchases_supplier_search
--    ON purchases(supplier_name);
--
--    CREATE INDEX IF NOT EXISTS idx_purchases_number_search
--    ON purchases(purchase_number);
--
-- 4. PAYMENT METHOD VALUES
--    Ensure payment_method column accepts these values:
--    - 'cash' (নগদ টাকা - blue chip)
--    - 'mobile_banking' (বিকাশ/নগদ কিউ আর - orange chip)
--    - 'due' (বাকি - red chip)
--    - 'bank_check' (ব্যাংক চেক - indigo chip)
--
-- 5. SUPABASE RPC FUNCTIONS REQUIRED
--    - generate_purchase_number() - Already exists in purchase_service.dart
--    - process_purchase(p_purchase_data, p_purchase_items) - Already exists
