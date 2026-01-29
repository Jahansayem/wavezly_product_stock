-- =====================================================
-- Fix Infinite Recursion in RLS Policies
-- =====================================================
-- Issue: Circular dependency in profiles SELECT policy
-- Solution: Remove self-referencing subquery and update helper functions
-- Date: 2026-01-29
-- =====================================================

-- 1. Fix profiles SELECT policy (remove recursion)
DROP POLICY IF EXISTS "Users can view their business profiles" ON profiles;
CREATE POLICY "Users can view their business profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid() OR               -- Own profile
    owner_id = auth.uid()            -- Owner viewing staff
  );

COMMENT ON POLICY "Users can view their business profiles" ON profiles IS
  'Simplified policy without recursive subquery to prevent infinite recursion';

-- 2. Update get_effective_owner() function with explicit RLS bypass
CREATE OR REPLACE FUNCTION get_effective_owner(user_uuid UUID)
RETURNS UUID AS $$
DECLARE
  result UUID;
BEGIN
  -- Disable RLS within this function to prevent recursion
  SET LOCAL row_security = off;

  -- Get owner_id from profiles, or return user_uuid if they are the owner
  SELECT COALESCE(owner_id, user_uuid)
  INTO result
  FROM profiles
  WHERE id = user_uuid;

  RETURN COALESCE(result, user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_effective_owner IS
  'Returns effective owner with explicit RLS bypass to prevent recursion';

-- 3. Verify/Create RLS policies for onboarding tables
-- user_business_profiles
ALTER TABLE user_business_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their business profile" ON user_business_profiles;
CREATE POLICY "Users can manage their business profile"
  ON user_business_profiles
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- user_security
ALTER TABLE user_security ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their security settings" ON user_security;
CREATE POLICY "Users can manage their security settings"
  ON user_security
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- 4. Verification query - should return rows without errors
SELECT
  p.id,
  p.name,
  p.role,
  ubp.shop_name,
  us.pin_hash IS NOT NULL as has_pin
FROM profiles p
LEFT JOIN user_business_profiles ubp ON p.id = ubp.user_id
LEFT JOIN user_security us ON p.id = us.user_id
WHERE p.id = auth.uid();

-- =====================================================
-- Additional Verification Queries (Run After Migration)
-- =====================================================

-- Test helper function (should work without recursion)
-- SELECT current_effective_owner();

-- Test viewing own profile (should work)
-- SELECT * FROM profiles WHERE id = auth.uid();

-- Test viewing business profile (should work)
-- SELECT * FROM user_business_profiles WHERE user_id = auth.uid();

-- Test viewing security settings (should work)
-- SELECT * FROM user_security WHERE user_id = auth.uid();

-- Check all onboarding data for current user
-- SELECT
--   u.email,
--   p.name,
--   p.role,
--   p.business_type,
--   p.business_type_label,
--   ubp.shop_name,
--   ubp.age_group,
--   ubp.referral_code,
--   ubp.onboarding_completed_at,
--   us.pin_hash IS NOT NULL as has_pin
-- FROM auth.users u
-- JOIN profiles p ON u.id = p.id
-- LEFT JOIN user_business_profiles ubp ON u.id = ubp.user_id
-- LEFT JOIN user_security us ON u.id = us.user_id
-- WHERE u.email LIKE 'Phone-%@halkhata.app'
-- ORDER BY u.created_at DESC
-- LIMIT 5;
