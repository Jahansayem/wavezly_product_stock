-- =====================================================
-- Rollback: RLS Recursion Fix
-- =====================================================
-- Use this script ONLY if the fix causes issues
-- This restores the original (problematic) policies
-- Date: 2026-01-29
-- =====================================================

-- WARNING: This rollback script restores the policies that cause infinite recursion
-- Only use this if the new policies cause unexpected issues and you need to revert

-- Rollback: Restore original profiles SELECT policy (with recursion)
DROP POLICY IF EXISTS "Users can view their business profiles" ON profiles;
CREATE POLICY "Users can view their business profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid() OR
    owner_id = auth.uid() OR
    id IN (SELECT owner_id FROM profiles WHERE id = auth.uid())  -- This causes recursion
  );

-- Rollback: Restore original helper function (without RLS bypass)
CREATE OR REPLACE FUNCTION get_effective_owner(user_uuid UUID)
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (SELECT owner_id FROM profiles WHERE id = user_uuid),
    user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Note: The user_business_profiles and user_security policies
-- created by the fix are safe and should NOT be rolled back.
-- They simply allow users to manage their own data.
