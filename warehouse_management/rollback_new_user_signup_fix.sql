-- ============================================================================
-- Rollback: Fix for Database Error Saving New User
-- ============================================================================
-- This script rolls back the changes made by fix_new_user_signup_error.sql
--
-- IMPORTANT: Only execute this if you need to revert the changes
-- WARNING: Do NOT drop tables (user_business_profiles, user_security)
--          as they may already contain user data
-- ============================================================================

-- ============================================================================
-- STEP 1: Restore Original RLS Policy
-- ============================================================================

-- Restore original INSERT policy (with auth.uid() IS NOT NULL requirement)
DROP POLICY IF EXISTS "Owners can add staff" ON profiles;

CREATE POLICY "Owners can add staff"
  ON profiles FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL AND (
      (role = 'OWNER' AND owner_id IS NULL) OR
      (role = 'STAFF' AND owner_id = auth.uid())
    )
  );

COMMENT ON POLICY "Owners can add staff" ON profiles IS
  'Original policy: Requires auth.uid() for all inserts (REVERTED)';

-- ============================================================================
-- STEP 2: Restore Original Trigger Function
-- ============================================================================

-- Restore original trigger function (without RLS bypass)
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, phone, role, owner_id, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, 'User'),
    NEW.raw_user_meta_data->>'phone',
    'OWNER',
    NULL,
    true
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_profile_for_new_user() IS
  'Original trigger function without RLS bypass (REVERTED)';

-- ============================================================================
-- STEP 3: Remove Added Columns from Profiles Table (OPTIONAL)
-- ============================================================================
-- CAUTION: Only execute these if you want to remove the business type columns
-- This may break the application if data already exists

-- Uncomment these lines if you want to remove the columns:
-- ALTER TABLE profiles DROP COLUMN IF EXISTS business_type;
-- ALTER TABLE profiles DROP COLUMN IF EXISTS business_type_label;
-- ALTER TABLE profiles DROP COLUMN IF EXISTS business_type_selected_at;
-- DROP INDEX IF EXISTS idx_profiles_business_type;

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. DO NOT drop user_business_profiles table - may contain user data
-- 2. DO NOT drop user_security table - may contain user PIN hashes
-- 3. If you need to remove tables, manually verify they are empty first:
--
--    SELECT COUNT(*) FROM user_business_profiles;
--    SELECT COUNT(*) FROM user_security;
--
-- 4. To manually drop tables (only if confirmed empty):
--    DROP TABLE IF EXISTS user_business_profiles CASCADE;
--    DROP TABLE IF EXISTS user_security CASCADE;
-- ============================================================================

-- Rollback complete
SELECT 'Rollback completed. NOTE: Tables and columns were NOT dropped to preserve data.' AS status;
