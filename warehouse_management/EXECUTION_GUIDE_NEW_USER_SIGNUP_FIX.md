# Execution Guide: Fix Database Error Saving New User

## Overview

This guide walks you through applying the SQL migration to fix the "Database error saving new user" error that occurs during OTP verification for new user registration.

## Files Created

1. **`fix_new_user_signup_error.sql`** - Main migration script
2. **`rollback_new_user_signup_fix.sql`** - Rollback script (if needed)
3. **`EXECUTION_GUIDE_NEW_USER_SIGNUP_FIX.md`** - This file

---

## Pre-Execution Checklist

- [ ] **Backup recommended:** Consider taking a Supabase snapshot before proceeding
- [ ] **Test environment:** If possible, test on a development Supabase project first
- [ ] **Low traffic period:** Execute during off-peak hours if in production
- [ ] **Read full plan:** Review the complete plan document to understand the changes

---

## Execution Steps

### Step 1: Access Supabase SQL Editor

1. Open Supabase Dashboard: https://ozadmtmkrkwbolzbqtif.supabase.co
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**

### Step 2: Execute Migration Script

**Option A: Copy-Paste Method**

1. Open `warehouse_management/fix_new_user_signup_error.sql` in your code editor
2. Copy the entire contents (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)
5. Wait for execution (should take 2-5 seconds)
6. Check for success message: "Migration completed successfully!"

**Option B: Using Supabase CLI (if installed)**

```bash
cd warehouse_management
supabase db execute -f fix_new_user_signup_error.sql
```

### Step 3: Verify Migration Success

Run these verification queries in Supabase SQL Editor:

**Query 1: Check all tables exist**
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'user_business_profiles', 'user_security')
ORDER BY table_name;
```
**Expected:** 3 rows (profiles, user_business_profiles, user_security)

**Query 2: Check profiles table columns**
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('business_type', 'business_type_label', 'business_type_selected_at')
ORDER BY column_name;
```
**Expected:** 3 rows (all 3 business type columns)

**Query 3: Check RLS policies**
```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('profiles', 'user_business_profiles', 'user_security')
ORDER BY tablename, policyname;
```
**Expected:** Multiple rows showing policies for each table

**Query 4: Check trigger function**
```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name = 'create_profile_for_new_user'
  AND routine_schema = 'public';
```
**Expected:** 1 row (create_profile_for_new_user function)

### Step 4: Test New User Registration

1. **Clear app data** (to test fresh registration):
   ```bash
   cd warehouse_management
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test registration flow:**
   - Open app
   - Click "Register" / "Sign Up"
   - Enter test phone number (e.g., `01707346633`)
   - Receive OTP and enter it
   - **Expected:** ✅ Successfully creates user and navigates to Business Info screen
   - **Previously:** ❌ "Database error saving new user"

3. **Complete onboarding:**
   - Step 1: Enter shop name, age group → Click Save
   - Step 2: Create 5-digit PIN → Click Save
   - Step 3: Select business type → Click Save
   - **Expected:** ✅ Navigate to Main Dashboard

4. **Test existing user login:**
   - Logout
   - Login with same phone number
   - Enter OTP
   - **Expected:** ✅ Navigate to PIN verification screen
   - Enter correct PIN
   - **Expected:** ✅ Navigate to Main Dashboard

### Step 5: Verify Database Records

After successful registration, run this query to verify data integrity:

```sql
-- Replace '880172346633' with your test phone number (with country code)
WITH test_user AS (
  SELECT id FROM profiles WHERE phone = '880172346633' LIMIT 1
)
SELECT
  'profiles' AS table_name,
  COUNT(*) AS record_count
FROM profiles
WHERE id = (SELECT id FROM test_user)
UNION ALL
SELECT
  'user_business_profiles' AS table_name,
  COUNT(*) AS record_count
FROM user_business_profiles
WHERE user_id = (SELECT id FROM test_user)
UNION ALL
SELECT
  'user_security' AS table_name,
  COUNT(*) AS record_count
FROM user_security
WHERE user_id = (SELECT id FROM test_user);
```

**Expected:** 1 record in each table (3 total)

---

## Success Criteria

Migration is successful if:
- ✅ All verification queries return expected results
- ✅ New user registration completes without errors
- ✅ User profile is created in `profiles` table
- ✅ Business info is saved in `user_business_profiles` table
- ✅ PIN hash is saved in `user_security` table
- ✅ Existing users can login normally
- ✅ No errors in Supabase logs

---

## Troubleshooting

### Error: "relation 'profiles' does not exist"

**Cause:** Base schema not yet executed
**Solution:** First execute `supabase_user_management_setup.sql`, then retry this migration

### Error: "function update_updated_at_column() does not exist"

**Cause:** Missing helper function
**Solution:** Add this function before running migration:

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Error: "duplicate key value violates unique constraint"

**Cause:** Tables already exist from previous attempt
**Solution:** Migration uses `IF NOT EXISTS`, so this should not occur. If it does, the migration is safe to re-run.

### New user registration still fails

**Check:**
1. Run all verification queries to ensure migration applied correctly
2. Check Supabase logs for detailed error message
3. Verify trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'create_profile_trigger';`
4. Check RLS policy: `SELECT * FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Owners can add staff';`

---

## Rollback Instructions

If you need to revert the changes:

### Step 1: Execute Rollback Script

1. Open Supabase SQL Editor
2. Open `warehouse_management/rollback_new_user_signup_fix.sql`
3. Copy and paste into SQL Editor
4. Click **Run**

### Step 2: Verify Rollback

```sql
-- Check that original policy was restored
SELECT policyname, qual
FROM pg_policies
WHERE tablename = 'profiles'
  AND policyname = 'Owners can add staff';
```

**Expected:** Policy should include `auth.uid() IS NOT NULL` in the qual field

### Important Notes on Rollback

- ⚠️ Rollback script does NOT drop tables (`user_business_profiles`, `user_security`)
- ⚠️ Rollback script does NOT remove columns from `profiles` table
- ⚠️ This is intentional to preserve user data
- ✅ If you need to drop tables, manually verify they are empty first

---

## Post-Execution Monitoring

### What to Monitor (First 24 Hours)

1. **Supabase Logs** - Check for any auth-related errors
2. **New User Registrations** - Monitor signup success rate
3. **Existing User Logins** - Ensure no impact on current users
4. **Database Size** - Minimal increase expected (3 new tables)

### Where to Check Logs

1. Supabase Dashboard → **Logs** → **Postgres Logs**
2. Filter for: `auth.users`, `profiles`, errors
3. Look for: "Database error saving new user" (should be GONE)

---

## Timeline

- **Migration Execution:** ~30 seconds
- **Verification Queries:** ~2 minutes
- **Manual Testing:** ~10 minutes
- **Total Time:** ~15 minutes

---

## Support

If you encounter issues:

1. **Check this guide's Troubleshooting section**
2. **Review Supabase logs** for detailed error messages
3. **Verify all pre-execution checklist items** were completed
4. **Consider rollback** if blocking issue in production

---

## Migration Details

**What Changed:**

| Component | Change |
|-----------|--------|
| RLS Policy | Removed `auth.uid() IS NOT NULL` requirement for OWNER creation |
| Trigger Function | Added `SET LOCAL row_security = off` to bypass RLS |
| Database Schema | Added 2 tables + 3 columns to profiles |

**What Stayed The Same:**

- Existing user data (unchanged)
- Staff creation policy (still requires authentication)
- All other RLS policies (unchanged)
- Auth flow (unchanged)
- Trigger execution timing (unchanged)

---

## Appendix: Quick Reference

**Migration File:** `warehouse_management/fix_new_user_signup_error.sql`
**Rollback File:** `warehouse_management/rollback_new_user_signup_fix.sql`
**Supabase URL:** https://ozadmtmkrkwbolzbqtif.supabase.co
**Project Root:** `warehouse_management/`

**Key Tables Modified/Created:**
- `profiles` (modified - 3 columns added, 1 policy changed, 1 trigger updated)
- `user_business_profiles` (created)
- `user_security` (created)

**Files Referenced in Code:**
- `lib/features/auth/screens/otp_verification_screen.dart:167-174`
- `lib/features/onboarding/screens/business_info_screen.dart:62-86`
- `lib/features/onboarding/screens/pin_creation_screen.dart:77`
- `lib/features/onboarding/screens/business_type_screen.dart`
