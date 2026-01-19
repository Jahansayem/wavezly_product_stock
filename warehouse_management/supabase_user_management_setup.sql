-- =====================================================
-- Warehouse Management - User Management & Multi-Tenancy Setup
-- =====================================================
-- This script implements a multi-user staff management system
-- where OWNERs can invite STAFF members who share access to
-- business data (products, sales, customers, expenses, etc.)
--
-- ⚠️ CRITICAL WARNING ⚠️
-- This script REPLACES existing RLS policies on ALL tables!
-- Backup your database before executing.
--
-- Run this script in your Supabase SQL Editor
-- URL: https://ozadmtmkrkwbolzbqtif.supabase.co
-- =====================================================

-- =====================================================
-- 1. Create Profiles Table
-- =====================================================
-- Stores user metadata (name, phone, role, owner relationship)
-- Maps 1:1 with auth.users table

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('OWNER', 'STAFF')),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraint: OWNERs have null owner_id, STAFF must have owner_id
  CONSTRAINT owner_id_null_for_owners CHECK (
    (role = 'OWNER' AND owner_id IS NULL) OR
    (role = 'STAFF' AND owner_id IS NOT NULL)
  )
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_owner_id ON profiles(owner_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);

-- Add trigger for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE profiles IS 'User profiles with role-based multi-tenancy support';
COMMENT ON COLUMN profiles.owner_id IS 'NULL for OWNER role, points to owner auth.users.id for STAFF role';

-- =====================================================
-- 2. Create Helper Functions
-- =====================================================

-- Get effective owner for a given user UUID
-- Returns: owner_id for STAFF, or the user's own id for OWNER
CREATE OR REPLACE FUNCTION get_effective_owner(user_uuid UUID)
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (SELECT owner_id FROM profiles WHERE id = user_uuid),
    user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_effective_owner IS 'Returns effective owner: owner_id for STAFF, self for OWNER';

-- Shorthand for current user's effective owner
CREATE OR REPLACE FUNCTION current_effective_owner()
RETURNS UUID AS $$
BEGIN
  RETURN get_effective_owner(auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION current_effective_owner IS 'Returns effective owner for currently authenticated user';

-- =====================================================
-- 3. Auto-Profile Creation Trigger
-- =====================================================
-- Automatically creates a profile when a new user signs up

CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, role, owner_id, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, 'User'),
    'OWNER',  -- Default to OWNER, can be changed later
    NULL,
    true
  )
  ON CONFLICT (id) DO NOTHING;  -- Avoid errors if profile already exists

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users;
CREATE TRIGGER create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();

COMMENT ON FUNCTION create_profile_for_new_user IS 'Auto-creates OWNER profile for new auth.users';

-- =====================================================
-- 4. RLS Policies for Profiles Table
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile, their staff profiles, and their owner's profile
DROP POLICY IF EXISTS "Users can view their business profiles" ON profiles;
CREATE POLICY "Users can view their business profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid() OR                           -- Own profile
    owner_id = auth.uid() OR                     -- Owner viewing staff
    id IN (SELECT owner_id FROM profiles WHERE id = auth.uid())  -- Staff viewing owner
  );

-- Only authenticated users can insert, and only OWNERs can create STAFF profiles
DROP POLICY IF EXISTS "Owners can add staff" ON profiles;
CREATE POLICY "Owners can add staff"
  ON profiles FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND (
      (role = 'OWNER' AND owner_id IS NULL) OR   -- Creating owner profile
      (role = 'STAFF' AND owner_id = auth.uid()) -- Owner creating staff
    )
  );

-- Users can update their own profile, owners can update their staff profiles
DROP POLICY IF EXISTS "Users can update business profiles" ON profiles;
CREATE POLICY "Users can update business profiles"
  ON profiles FOR UPDATE
  USING (
    id = auth.uid() OR                           -- Own profile
    (owner_id = auth.uid() AND role = 'STAFF')   -- Owner updating staff
  );

-- Only owners can delete staff profiles, users can delete their own profile
DROP POLICY IF EXISTS "Owners can delete staff" ON profiles;
CREATE POLICY "Owners can delete staff"
  ON profiles FOR DELETE
  USING (
    id = auth.uid() OR                           -- Own profile (for self-deletion)
    (owner_id = auth.uid() AND role = 'STAFF')   -- Owner deleting staff
  );

-- =====================================================
-- 5. Update RLS Policies for Products Table
-- =====================================================

-- DROP existing policies
DROP POLICY IF EXISTS "Users can view their own products" ON products;
DROP POLICY IF EXISTS "Users can insert their own products" ON products;
DROP POLICY IF EXISTS "Users can update their own products" ON products;
DROP POLICY IF EXISTS "Users can delete their own products" ON products;

-- CREATE new policies supporting staff access
CREATE POLICY "Users can view their business products"
  ON products FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business products"
  ON products FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business products"
  ON products FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business products"
  ON products FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 6. Update RLS Policies for Product Groups Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own groups" ON product_groups;
DROP POLICY IF EXISTS "Users can insert their own groups" ON product_groups;
DROP POLICY IF EXISTS "Users can update their own groups" ON product_groups;
DROP POLICY IF EXISTS "Users can delete their own groups" ON product_groups;

CREATE POLICY "Users can view their business groups"
  ON product_groups FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business groups"
  ON product_groups FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business groups"
  ON product_groups FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business groups"
  ON product_groups FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 7. Update RLS Policies for Locations Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own locations" ON locations;
DROP POLICY IF EXISTS "Users can insert their own locations" ON locations;
DROP POLICY IF EXISTS "Users can update their own locations" ON locations;
DROP POLICY IF EXISTS "Users can delete their own locations" ON locations;

CREATE POLICY "Users can view their business locations"
  ON locations FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business locations"
  ON locations FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business locations"
  ON locations FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business locations"
  ON locations FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 8. Update RLS Policies for Sales Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own sales" ON sales;
DROP POLICY IF EXISTS "Users can insert their own sales" ON sales;
DROP POLICY IF EXISTS "Users can update their own sales" ON sales;
DROP POLICY IF EXISTS "Users can delete their own sales" ON sales;

CREATE POLICY "Users can view their business sales"
  ON sales FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business sales"
  ON sales FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business sales"
  ON sales FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business sales"
  ON sales FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 9. Update RLS Policies for Sale Items Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own sale items" ON sale_items;
DROP POLICY IF EXISTS "Users can insert their own sale items" ON sale_items;
DROP POLICY IF EXISTS "Users can update their own sale items" ON sale_items;
DROP POLICY IF EXISTS "Users can delete their own sale items" ON sale_items;

CREATE POLICY "Users can view their business sale items"
  ON sale_items FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business sale items"
  ON sale_items FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business sale items"
  ON sale_items FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business sale items"
  ON sale_items FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 10. Update RLS Policies for Purchases Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own purchases" ON purchases;
DROP POLICY IF EXISTS "Users can insert their own purchases" ON purchases;
DROP POLICY IF EXISTS "Users can update their own purchases" ON purchases;
DROP POLICY IF EXISTS "Users can delete their own purchases" ON purchases;

CREATE POLICY "Users can view their business purchases"
  ON purchases FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business purchases"
  ON purchases FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business purchases"
  ON purchases FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business purchases"
  ON purchases FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 11. Update RLS Policies for Purchase Items Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own purchase items" ON purchase_items;
DROP POLICY IF EXISTS "Users can insert their own purchase items" ON purchase_items;
DROP POLICY IF EXISTS "Users can update their own purchase items" ON purchase_items;
DROP POLICY IF EXISTS "Users can delete their own purchase items" ON purchase_items;

CREATE POLICY "Users can view their business purchase items"
  ON purchase_items FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business purchase items"
  ON purchase_items FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business purchase items"
  ON purchase_items FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business purchase items"
  ON purchase_items FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 12. Update RLS Policies for Customers Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own customers" ON customers;
DROP POLICY IF EXISTS "Users can insert their own customers" ON customers;
DROP POLICY IF EXISTS "Users can update their own customers" ON customers;
DROP POLICY IF EXISTS "Users can delete their own customers" ON customers;

CREATE POLICY "Users can view their business customers"
  ON customers FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business customers"
  ON customers FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business customers"
  ON customers FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business customers"
  ON customers FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 13. Update RLS Policies for Customer Transactions Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own customer transactions" ON customer_transactions;
DROP POLICY IF EXISTS "Users can insert their own customer transactions" ON customer_transactions;
DROP POLICY IF EXISTS "Users can update their own customer transactions" ON customer_transactions;
DROP POLICY IF EXISTS "Users can delete their own customer transactions" ON customer_transactions;

CREATE POLICY "Users can view their business customer transactions"
  ON customer_transactions FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business customer transactions"
  ON customer_transactions FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business customer transactions"
  ON customer_transactions FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business customer transactions"
  ON customer_transactions FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 14. Update RLS Policies for Expenses Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can insert their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can update their own expenses" ON expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses" ON expenses;

CREATE POLICY "Users can view their business expenses"
  ON expenses FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business expenses"
  ON expenses FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business expenses"
  ON expenses FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business expenses"
  ON expenses FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 15. Update RLS Policies for Expense Categories Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can insert their own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can update their own expense categories" ON expense_categories;
DROP POLICY IF EXISTS "Users can delete their own expense categories" ON expense_categories;

CREATE POLICY "Users can view their business expense categories"
  ON expense_categories FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business expense categories"
  ON expense_categories FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business expense categories"
  ON expense_categories FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business expense categories"
  ON expense_categories FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 16. Update RLS Policies for Cashbox Transactions Table
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own cashbox transactions" ON cashbox_transactions;
DROP POLICY IF EXISTS "Users can insert their own cashbox transactions" ON cashbox_transactions;
DROP POLICY IF EXISTS "Users can update their own cashbox transactions" ON cashbox_transactions;
DROP POLICY IF EXISTS "Users can delete their own cashbox transactions" ON cashbox_transactions;

CREATE POLICY "Users can view their business cashbox transactions"
  ON cashbox_transactions FOR SELECT
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can insert their business cashbox transactions"
  ON cashbox_transactions FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can update their business cashbox transactions"
  ON cashbox_transactions FOR UPDATE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

CREATE POLICY "Users can delete their business cashbox transactions"
  ON cashbox_transactions FOR DELETE
  USING (
    user_id = auth.uid() OR
    user_id = current_effective_owner()
  );

-- =====================================================
-- 17. Update RLS Policies for Selling Carts Table (if exists)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'selling_carts') THEN
    DROP POLICY IF EXISTS "Users can view their own selling carts" ON selling_carts;
    DROP POLICY IF EXISTS "Users can insert their own selling carts" ON selling_carts;
    DROP POLICY IF EXISTS "Users can update their own selling carts" ON selling_carts;
    DROP POLICY IF EXISTS "Users can delete their own selling carts" ON selling_carts;

    EXECUTE '
    CREATE POLICY "Users can view their business selling carts"
      ON selling_carts FOR SELECT
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can insert their business selling carts"
      ON selling_carts FOR INSERT
      WITH CHECK (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can update their business selling carts"
      ON selling_carts FOR UPDATE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can delete their business selling carts"
      ON selling_carts FOR DELETE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';
  END IF;
END $$;

-- =====================================================
-- 18. Update RLS Policies for Suppliers Table (if exists)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'suppliers') THEN
    DROP POLICY IF EXISTS "Users can view their own suppliers" ON suppliers;
    DROP POLICY IF EXISTS "Users can insert their own suppliers" ON suppliers;
    DROP POLICY IF EXISTS "Users can update their own suppliers" ON suppliers;
    DROP POLICY IF EXISTS "Users can delete their own suppliers" ON suppliers;

    EXECUTE '
    CREATE POLICY "Users can view their business suppliers"
      ON suppliers FOR SELECT
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can insert their business suppliers"
      ON suppliers FOR INSERT
      WITH CHECK (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can update their business suppliers"
      ON suppliers FOR UPDATE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can delete their business suppliers"
      ON suppliers FOR DELETE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';
  END IF;
END $$;

-- =====================================================
-- 19. Update RLS Policies for SMS Logs Table (if exists)
-- =====================================================

DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sms_logs') THEN
    DROP POLICY IF EXISTS "Users can view their own sms logs" ON sms_logs;
    DROP POLICY IF EXISTS "Users can insert their own sms logs" ON sms_logs;
    DROP POLICY IF EXISTS "Users can update their own sms logs" ON sms_logs;
    DROP POLICY IF EXISTS "Users can delete their own sms logs" ON sms_logs;

    EXECUTE '
    CREATE POLICY "Users can view their business sms logs"
      ON sms_logs FOR SELECT
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can insert their business sms logs"
      ON sms_logs FOR INSERT
      WITH CHECK (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can update their business sms logs"
      ON sms_logs FOR UPDATE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';

    EXECUTE '
    CREATE POLICY "Users can delete their business sms logs"
      ON sms_logs FOR DELETE
      USING (
        user_id = auth.uid() OR
        user_id = current_effective_owner()
      )';
  END IF;
END $$;

-- =====================================================
-- 20. Data Migration: Create Profiles for Existing Users
-- =====================================================
-- Run this to migrate existing auth.users to profiles table
-- This creates OWNER profiles for all existing users

INSERT INTO profiles (id, name, role, owner_id, is_active)
SELECT
  id,
  COALESCE(raw_user_meta_data->>'name', email, 'User'),
  'OWNER',
  NULL,
  true
FROM auth.users
WHERE id NOT IN (SELECT id FROM profiles)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 21. Verification Queries
-- =====================================================
-- Run these queries to verify the setup

-- Check profiles table
-- SELECT * FROM profiles ORDER BY created_at DESC;

-- Check if helper functions work
-- SELECT current_effective_owner();

-- Test RLS: View products (should see owner + staff data)
-- SELECT COUNT(*) FROM products;

-- View all users in your business
-- SELECT p.name, p.role, p.phone, p.is_active,
--        u.email, p.created_at
-- FROM profiles p
-- JOIN auth.users u ON p.id = u.id
-- ORDER BY p.created_at DESC;

-- =====================================================
-- Setup Complete!
-- =====================================================
-- Next Steps:
-- 1. Verify profiles table has entries for all auth.users
-- 2. Test creating a STAFF user through the Flutter app
-- 3. Verify STAFF can see OWNER's data
-- 4. Test RLS policies on different tables
-- =====================================================
