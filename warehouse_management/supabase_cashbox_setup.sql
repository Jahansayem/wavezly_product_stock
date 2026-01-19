-- ============================================================================
-- Cashbox Management Schema Setup for ShopStock
-- ============================================================================
-- This script creates the necessary tables, indexes, and policies for
-- cashbox (cash flow) tracking functionality
--
-- IMPORTANT: Execute this script in Supabase SQL Editor
-- URL: https://ozadmtmkrkwbolzbqtif.supabase.co
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Verify update_updated_at_column() function exists (from expense setup)
-- ----------------------------------------------------------------------------
-- This function should already exist from supabase_expense_setup.sql
-- If not, run that script first, or uncomment below:

-- CREATE OR REPLACE FUNCTION update_updated_at_column()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   NEW.updated_at = NOW();
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 2. Create cashbox_transactions table
-- ----------------------------------------------------------------------------
-- Tracks all cash inflow and outflow transactions
-- Transaction types: 'cash_in' (incoming cash) or 'cash_out' (outgoing cash)

CREATE TABLE IF NOT EXISTS cashbox_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('cash_in', 'cash_out')),
  amount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
  description TEXT NOT NULL,
  category TEXT, -- Optional categorization (e.g., 'Sales', 'Payment', 'Withdrawal', 'Deposit')
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. Create indexes for performance
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_cashbox_user_id ON cashbox_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_cashbox_date ON cashbox_transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_cashbox_type ON cashbox_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_cashbox_user_date ON cashbox_transactions(user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_cashbox_user_type ON cashbox_transactions(user_id, transaction_type);

-- ----------------------------------------------------------------------------
-- 4. Enable Row Level Security
-- ----------------------------------------------------------------------------
ALTER TABLE cashbox_transactions ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 5. Create RLS Policies for cashbox_transactions
-- ----------------------------------------------------------------------------

-- Policy: Users can view their own cashbox transactions
DROP POLICY IF EXISTS "Users can view their own cashbox transactions" ON cashbox_transactions;
CREATE POLICY "Users can view their own cashbox transactions"
  ON cashbox_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own cashbox transactions
DROP POLICY IF EXISTS "Users can insert their own cashbox transactions" ON cashbox_transactions;
CREATE POLICY "Users can insert their own cashbox transactions"
  ON cashbox_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own cashbox transactions
DROP POLICY IF EXISTS "Users can update their own cashbox transactions" ON cashbox_transactions;
CREATE POLICY "Users can update their own cashbox transactions"
  ON cashbox_transactions FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can delete their own cashbox transactions
DROP POLICY IF EXISTS "Users can delete their own cashbox transactions" ON cashbox_transactions;
CREATE POLICY "Users can delete their own cashbox transactions"
  ON cashbox_transactions FOR DELETE
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. Create trigger for automatic updated_at timestamp
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS update_cashbox_transactions_updated_at ON cashbox_transactions;
CREATE TRIGGER update_cashbox_transactions_updated_at
  BEFORE UPDATE ON cashbox_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- 7. Verification queries (run these to test after execution)
-- ----------------------------------------------------------------------------

-- View table structure
-- \d cashbox_transactions

-- Check RLS policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename = 'cashbox_transactions';

-- Test query: Get total cash in vs cash out for current month
-- SELECT
--   transaction_type,
--   COUNT(*) as transaction_count,
--   SUM(amount) as total_amount
-- FROM cashbox_transactions
-- WHERE transaction_date >= date_trunc('month', CURRENT_DATE)
--   AND transaction_date < date_trunc('month', CURRENT_DATE) + interval '1 month'
-- GROUP BY transaction_type;

-- Test query: Calculate current balance (cash_in - cash_out)
-- SELECT
--   COALESCE(SUM(CASE WHEN transaction_type = 'cash_in' THEN amount ELSE 0 END), 0) -
--   COALESCE(SUM(CASE WHEN transaction_type = 'cash_out' THEN amount ELSE 0 END), 0) as balance
-- FROM cashbox_transactions
-- WHERE transaction_date <= CURRENT_DATE;

-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- Next steps:
-- 1. Create Flutter models: CashboxTransaction, CashboxSummary
-- 2. Create Flutter service: CashboxService
-- 3. Create UI screens: CashboxScreenV2, CashboxEntryScreen
-- ============================================================================
