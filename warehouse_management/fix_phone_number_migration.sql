-- =====================================================
-- Fix Phone Number Migration
-- =====================================================
-- This migration fixes the user existence check by ensuring
-- phone numbers are properly stored in the profiles table.
--
-- Problem: The trigger create_profile_for_new_user() was not
-- extracting phone numbers from auth.users metadata, causing
-- all login attempts to be treated as new users.
--
-- Solution:
-- 1. Update trigger to include phone extraction
-- 2. Backfill phone numbers for existing users
--
-- Execute this in Supabase SQL Editor
-- URL: https://ozadmtmkrkwbolzbqtif.supabase.co
-- =====================================================

-- =====================================================
-- Step 1: Update Trigger to Include Phone Number
-- =====================================================

CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create profile with phone number from auth metadata
  INSERT INTO profiles (id, name, phone, role, owner_id, is_active)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, 'User'),
    NEW.raw_user_meta_data->>'phone',  -- Extract phone from signup metadata
    'OWNER',  -- Default to OWNER, can be changed later
    NULL,
    true
  )
  ON CONFLICT (id) DO NOTHING;  -- Avoid errors if profile already exists

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_profile_for_new_user IS 'Auto-creates OWNER profile with phone for new auth.users';

-- =====================================================
-- Step 2: Backfill Phone Numbers for Existing Users
-- =====================================================

-- Update profiles table to populate phone from auth.users metadata
-- This only updates rows where phone is NULL and metadata has phone
UPDATE profiles p
SET phone = (
  SELECT raw_user_meta_data->>'phone'
  FROM auth.users u
  WHERE u.id = p.id
)
WHERE phone IS NULL
  AND EXISTS (
    SELECT 1
    FROM auth.users u
    WHERE u.id = p.id
    AND raw_user_meta_data->>'phone' IS NOT NULL
  );

-- =====================================================
-- Step 3: Verification Queries
-- =====================================================

-- Verify the migration results
SELECT
  COUNT(*) as total_users,
  COUNT(phone) as users_with_phone,
  COUNT(*) - COUNT(phone) as users_without_phone
FROM profiles;

-- Show sample of users with phone numbers
SELECT id, name, phone, role, created_at
FROM profiles
WHERE phone IS NOT NULL
LIMIT 10;

-- Check trigger function definition
SELECT pg_get_functiondef('create_profile_for_new_user'::regproc);

-- =====================================================
-- Step 4: Test New User Signup (Optional)
-- =====================================================

-- After creating a test user via app, verify phone is populated:
-- SELECT id, name, phone, role FROM profiles WHERE phone = '8801712345678';

-- =====================================================
-- Migration Complete!
-- =====================================================
-- Expected Results:
-- ✅ Trigger function includes phone column in INSERT
-- ✅ Existing users' profiles have phone numbers populated
-- ✅ New signups will create profiles with phone numbers
--
-- Next Steps:
-- 1. Test existing user login → Should go to PIN screen (not OTP)
-- 2. Test new user signup → Should send OTP and proceed to verification
-- 3. Check debug logs for "User exists" vs "New user" detection
-- =====================================================
