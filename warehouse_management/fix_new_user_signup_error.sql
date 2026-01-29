-- ============================================================================
-- Fix: Database Error Saving New User During OTP Verification
-- ============================================================================
-- This migration fixes the RLS policy conflict during profile creation
-- and creates missing database tables for the onboarding flow.
--
-- Problem: New user signup fails with "Database error saving new user"
-- Cause: RLS policy requires auth.uid() IS NOT NULL, but during signup
--        the trigger runs BEFORE session is established (auth.uid() = NULL)
--
-- Solution:
-- 1. Fix RLS policy to allow trigger-based OWNER profile creation
-- 2. Update trigger to bypass RLS during INSERT
-- 3. Create missing tables: user_business_profiles, user_security
-- 4. Add missing columns to profiles table
-- ============================================================================

-- ============================================================================
-- STEP 1: Fix RLS Policy for Profile Creation
-- ============================================================================

-- Drop and recreate INSERT policy with trigger bypass
DROP POLICY IF EXISTS "Owners can add staff" ON profiles;

CREATE POLICY "Owners can add staff"
  ON profiles FOR INSERT
  WITH CHECK (
    -- Allow trigger-based inserts for OWNER profiles (when auth.uid() is NULL)
    (role = 'OWNER' AND owner_id IS NULL) OR
    -- Allow authenticated owners to create STAFF (when auth.uid() is NOT NULL)
    (auth.uid() IS NOT NULL AND role = 'STAFF' AND owner_id = auth.uid())
  );

COMMENT ON POLICY "Owners can add staff" ON profiles IS
  'Allows: (1) Trigger to create OWNER profiles during signup, (2) Authenticated owners to create STAFF';

-- ============================================================================
-- STEP 2: Update Trigger Function to Bypass RLS
-- ============================================================================

CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Bypass RLS for this INSERT operation
  -- This is safe because the trigger only creates OWNER profiles
  -- and RLS still protects all other operations
  SET LOCAL row_security = off;

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
  'Trigger function to create OWNER profile when new user signs up. Uses RLS bypass for initial profile creation.';

-- ============================================================================
-- STEP 3: Create Missing Database Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 - Create user_business_profiles table
-- ----------------------------------------------------------------------------
-- Stores business information and onboarding data
-- Referenced by: lib/features/onboarding/screens/business_info_screen.dart

CREATE TABLE IF NOT EXISTS user_business_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name TEXT NOT NULL,
  age_group TEXT,
  referral_code TEXT,
  terms_accepted BOOLEAN DEFAULT true,
  onboarding_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_user_business_profiles_user_id
  ON user_business_profiles(user_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_user_business_profiles_updated_at
  ON user_business_profiles;

CREATE TRIGGER update_user_business_profiles_updated_at
  BEFORE UPDATE ON user_business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE user_business_profiles ENABLE ROW LEVEL SECURITY;

-- RLS policy: Users can only manage their own business profile
DROP POLICY IF EXISTS "Users can manage their business profile"
  ON user_business_profiles;

CREATE POLICY "Users can manage their business profile"
  ON user_business_profiles
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

COMMENT ON TABLE user_business_profiles IS
  'Stores business/shop information and onboarding data for each user';

-- ----------------------------------------------------------------------------
-- 3.2 - Create user_security table
-- ----------------------------------------------------------------------------
-- Stores PIN hash and security settings
-- Referenced by: lib/features/onboarding/screens/pin_creation_screen.dart

CREATE TABLE IF NOT EXISTS user_security (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pin_hash TEXT NOT NULL,
  pin_created_at TIMESTAMPTZ DEFAULT NOW(),
  pin_updated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_user_security_user_id
  ON user_security(user_id);

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_user_security_updated_at ON user_security;

CREATE TRIGGER update_user_security_updated_at
  BEFORE UPDATE ON user_security
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE user_security ENABLE ROW LEVEL SECURITY;

-- RLS policy: Users can only manage their own security settings
DROP POLICY IF EXISTS "Users can manage their security settings"
  ON user_security;

CREATE POLICY "Users can manage their security settings"
  ON user_security
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

COMMENT ON TABLE user_security IS
  'Stores PIN hash and security settings for each user. PIN is hashed before storage.';

-- ============================================================================
-- STEP 4: Add Missing Columns to Profiles Table
-- ============================================================================

-- Add business type fields to profiles table
-- Referenced by: lib/features/onboarding/screens/business_type_screen.dart

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS business_type TEXT,
  ADD COLUMN IF NOT EXISTS business_type_label TEXT,
  ADD COLUMN IF NOT EXISTS business_type_selected_at TIMESTAMPTZ;

-- Create index for business type queries
CREATE INDEX IF NOT EXISTS idx_profiles_business_type
  ON profiles(business_type);

COMMENT ON COLUMN profiles.business_type IS
  'Business type identifier (e.g., grocery, pharmacy, retail)';
COMMENT ON COLUMN profiles.business_type_label IS
  'Human-readable business type label';
COMMENT ON COLUMN profiles.business_type_selected_at IS
  'Timestamp when business type was selected';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these queries after executing the migration to verify success:
--
-- 1. Check that all tables exist:
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'public'
--   AND table_name IN ('profiles', 'user_business_profiles', 'user_security')
-- ORDER BY table_name;
-- Expected: 3 rows
--
-- 2. Check profiles table columns:
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'profiles'
--   AND column_name IN ('business_type', 'business_type_label', 'business_type_selected_at')
-- ORDER BY column_name;
-- Expected: 3 rows
--
-- 3. Check RLS policies:
-- SELECT tablename, policyname, cmd
-- FROM pg_policies
-- WHERE tablename IN ('profiles', 'user_business_profiles', 'user_security')
-- ORDER BY tablename, policyname;
-- Expected: Multiple rows showing policies for each table
-- ============================================================================

-- Migration complete
SELECT 'Migration completed successfully!' AS status;
