-- ============================================================================
-- Expense Management Schema Setup for ShopStock
-- ============================================================================
-- This script creates the necessary tables, indexes, and policies for
-- expense tracking functionality
--
-- IMPORTANT: Execute this script in Supabase SQL Editor
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create update_updated_at_column() function (if not exists)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. Create expense_categories table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expense_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_bengali TEXT NOT NULL,
  description TEXT,
  description_bengali TEXT,
  icon_name TEXT NOT NULL,
  icon_color TEXT NOT NULL,
  bg_color TEXT NOT NULL,
  is_system BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for expense_categories
CREATE INDEX IF NOT EXISTS idx_expense_categories_user ON expense_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_categories_system ON expense_categories(is_system);

-- Enable RLS for expense_categories
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for expense_categories
DROP POLICY IF EXISTS "Users can view their own categories and system categories" ON expense_categories;
CREATE POLICY "Users can view their own categories and system categories"
  ON expense_categories FOR SELECT
  USING (auth.uid() = user_id OR is_system = TRUE);

DROP POLICY IF EXISTS "Users can insert their own categories" ON expense_categories;
CREATE POLICY "Users can insert their own categories"
  ON expense_categories FOR INSERT
  WITH CHECK (auth.uid() = user_id AND is_system = FALSE);

DROP POLICY IF EXISTS "Users can update their own categories" ON expense_categories;
CREATE POLICY "Users can update their own categories"
  ON expense_categories FOR UPDATE
  USING (auth.uid() = user_id AND is_system = FALSE);

DROP POLICY IF EXISTS "Users can delete their own categories" ON expense_categories;
CREATE POLICY "Users can delete their own categories"
  ON expense_categories FOR DELETE
  USING (auth.uid() = user_id AND is_system = FALSE);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_expense_categories_updated_at ON expense_categories;
CREATE TRIGGER update_expense_categories_updated_at
  BEFORE UPDATE ON expense_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- 3. Create expenses table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  description TEXT,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for expenses
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, expense_date DESC);

-- Enable RLS for expenses
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- RLS Policies for expenses
DROP POLICY IF EXISTS "Users can view their own expenses" ON expenses;
CREATE POLICY "Users can view their own expenses"
  ON expenses FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own expenses" ON expenses;
CREATE POLICY "Users can insert their own expenses"
  ON expenses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own expenses" ON expenses;
CREATE POLICY "Users can update their own expenses"
  ON expenses FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own expenses" ON expenses;
CREATE POLICY "Users can delete their own expenses"
  ON expenses FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_expenses_updated_at ON expenses;
CREATE TRIGGER update_expenses_updated_at
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- 4. Seed system categories (visible to all users)
-- ----------------------------------------------------------------------------
-- Note: Using a special system user UUID (all zeros)
-- These categories are read-only for users (is_system = TRUE)

INSERT INTO expense_categories (id, user_id, name, name_bengali, description, description_bengali, icon_name, icon_color, bg_color, is_system)
VALUES
  (
    '550e8400-e29b-41d4-a716-446655440001'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'Salary',
    'বেতন',
    'Employee salaries and allowances',
    'কর্মচারী বেতন ও ভাতা',
    'payments',
    'blue600',
    'blue100',
    TRUE
  ),
  (
    '550e8400-e29b-41d4-a716-446655440002'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'Purchase',
    'কেনা',
    'Product purchases and supplies',
    'পণ্য ক্রয় ও সরবরাহ',
    'inventory_2',
    'orange600',
    'orange100',
    TRUE
  ),
  (
    '550e8400-e29b-41d4-a716-446655440003'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'Bills',
    'বিল',
    'Electricity, water and other bills',
    'বিদ্যুৎ, পানি ও অন্যান্য বিল',
    'receipt',
    'purple600',
    'purple100',
    TRUE
  ),
  (
    '550e8400-e29b-41d4-a716-446655440004'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'Rent',
    'ভাড়া',
    'Shop or warehouse rent',
    'দোকান বা গোডাউন ভাড়া',
    'storefront',
    'emerald600',
    'emerald100',
    TRUE
  ),
  (
    '550e8400-e29b-41d4-a716-446655440005'::UUID,
    '00000000-0000-0000-0000-000000000000'::UUID,
    'Transport',
    'পরিবহন',
    'Travel and transport costs',
    'যাতায়াত ও পরিবহন খরচ',
    'local_shipping',
    'red600',
    'red100',
    TRUE
  )
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. Verification queries (run these to test)
-- ----------------------------------------------------------------------------
-- View all system categories
-- SELECT * FROM expense_categories WHERE is_system = TRUE;

-- Check RLS policies
-- SELECT schemaname, tablename, policyname FROM pg_policies
-- WHERE tablename IN ('expenses', 'expense_categories');

-- Test expenses query for current month
-- SELECT
--   SUM(amount) as total,
--   COUNT(*) as count
-- FROM expenses
-- WHERE expense_date >= date_trunc('month', CURRENT_DATE)
--   AND expense_date < date_trunc('month', CURRENT_DATE) + interval '1 month';
