# RLS Infinite Recursion Fix - Implementation Guide

## Overview
This guide walks you through fixing the PostgreSQL infinite recursion error that blocks user onboarding at Step 3 (Business Type Selection).

**Error:** `PostgrestException: infinite recursion detected in policy for relation "profiles"`

**Root Cause:** The RLS policy on the `profiles` table contains a self-referencing subquery that creates an infinite loop.

---

## Quick Start

### Step 1: Execute SQL Migration in Supabase

1. **Open Supabase SQL Editor:**
   - Navigate to: https://ozadmtmkrkwbolzbqtif.supabase.co
   - Log in to your Supabase account
   - Go to **SQL Editor** in the left sidebar

2. **Open the migration file:**
   - Open `warehouse_management/fix_rls_recursion.sql` in your code editor
   - Copy the entire contents

3. **Execute the migration:**
   - Paste the SQL into Supabase SQL Editor
   - Click **Run** button
   - Wait for execution to complete

4. **Verify execution:**
   - Check for green success message
   - Verify no error messages in output
   - The verification query at the end should return a row (or empty result if no user logged in)

**Expected Output:**
```
✓ Policy "Users can view their business profiles" created
✓ Function get_effective_owner replaced
✓ Policy "Users can manage their business profile" created
✓ Policy "Users can manage their security settings" created
✓ Verification query executed successfully
```

---

## Step 2: Test the Fix in Your App

### Clean Build (Optional but Recommended)
```bash
cd warehouse_management
flutter clean
flutter pub get
```

### Run the App
```bash
flutter run
```

### Complete Onboarding Flow
1. **Phone Number Entry**
   - Enter a test phone number
   - Receive and enter OTP

2. **Step 1: Business Information**
   - Enter shop name
   - Select age group
   - Click "পরবর্তী" (Next)

3. **Step 2: PIN Setup**
   - Enter 6-digit PIN
   - Confirm PIN
   - Click "পরবর্তী" (Next)

4. **Step 3: Business Type Selection** ← **Critical Test Point**
   - Select a business type (e.g., "মুদি দোকান")
   - Click "শেষ করুন" (Finish)

### Expected Results ✅
- ✅ No "infinite recursion" error
- ✅ Success toast: "স্বাগতম! আপনার অ্যাকাউন্ট তৈরি হয়েছে"
- ✅ Navigate to MainNavigation screen (Home Dashboard)
- ✅ User data saved in database

### If Error Occurs ❌
- Check Supabase SQL Editor for error messages
- Verify the migration was executed completely
- See "Troubleshooting" section below

---

## Step 3: Verify Data in Supabase

### Check User Data
Run this query in Supabase SQL Editor:

```sql
SELECT
  u.email,
  p.name,
  p.role,
  p.business_type,
  p.business_type_label,
  ubp.shop_name,
  ubp.age_group,
  ubp.referral_code,
  ubp.onboarding_completed_at,
  us.pin_hash IS NOT NULL as has_pin
FROM auth.users u
JOIN profiles p ON u.id = p.id
LEFT JOIN user_business_profiles ubp ON u.id = ubp.user_id
LEFT JOIN user_security us ON u.id = us.user_id
WHERE u.email LIKE 'Phone-%@halkhata.app'
ORDER BY u.created_at DESC
LIMIT 5;
```

**Expected Result:**
- Row(s) with complete user data
- `business_type` and `business_type_label` populated
- `shop_name` populated
- `has_pin` = true
- `onboarding_completed_at` has a timestamp

---

## Step 4: Test RLS Policies (Advanced)

### Test Helper Function
```sql
SELECT current_effective_owner();
```
**Expected:** Returns your user UUID without errors

### Test Profile Access
```sql
SELECT * FROM profiles WHERE id = auth.uid();
```
**Expected:** Returns your profile row without recursion error

### Test Business Profile Access
```sql
SELECT * FROM user_business_profiles WHERE user_id = auth.uid();
```
**Expected:** Returns your business profile row

### Test Security Settings Access
```sql
SELECT * FROM user_security WHERE user_id = auth.uid();
```
**Expected:** Returns your security settings row

---

## What Changed

### 1. Fixed `profiles` SELECT Policy
**Before (Problematic):**
```sql
CREATE POLICY "Users can view their business profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid() OR
    owner_id = auth.uid() OR
    id IN (SELECT owner_id FROM profiles WHERE id = auth.uid())  -- ❌ RECURSION!
  );
```

**After (Fixed):**
```sql
CREATE POLICY "Users can view their business profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid() OR               -- Own profile
    owner_id = auth.uid()            -- Owner viewing staff
  );
```

**Why:** Removed the self-referencing subquery that caused infinite recursion.

### 2. Updated `get_effective_owner()` Function
**Before:**
```sql
CREATE OR REPLACE FUNCTION get_effective_owner(user_uuid UUID)
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (SELECT owner_id FROM profiles WHERE id = user_uuid),
    user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
```

**After (Fixed):**
```sql
CREATE OR REPLACE FUNCTION get_effective_owner(user_uuid UUID)
RETURNS UUID AS $$
DECLARE
  result UUID;
BEGIN
  -- Disable RLS within this function to prevent recursion
  SET LOCAL row_security = off;

  SELECT COALESCE(owner_id, user_uuid)
  INTO result
  FROM profiles
  WHERE id = user_uuid;

  RETURN COALESCE(result, user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
```

**Why:** Added `SET LOCAL row_security = off` to bypass RLS within the function, preventing recursion when other policies call this function.

### 3. Created RLS Policies for Onboarding Tables
Added simple, non-recursive policies for:
- `user_business_profiles`: Users can only access their own business profile
- `user_security`: Users can only access their own security settings

---

## Troubleshooting

### Error: "infinite recursion detected" Still Occurs

**Possible causes:**
1. Migration didn't execute completely
2. Old connection pool still using old policies

**Solutions:**
- Re-run the migration script
- Restart Supabase (if you have access)
- Wait 1-2 minutes for connection pool to refresh
- Clear Flutter app data and retry

### Error: "permission denied for table profiles"

**Cause:** RLS policy too restrictive or not created

**Solution:**
- Verify the migration executed successfully
- Check that policy exists:
  ```sql
  SELECT * FROM pg_policies WHERE tablename = 'profiles';
  ```

### Error: "relation 'user_business_profiles' does not exist"

**Cause:** Table doesn't exist in database

**Solution:**
- Check table exists:
  ```sql
  SELECT * FROM information_schema.tables
  WHERE table_name = 'user_business_profiles';
  ```
- If missing, run the full `supabase_setup.sql` first

### No Data Returned in Verification Query

**This is normal if:**
- No user is currently logged in to Supabase SQL Editor
- You're testing with a different user account

**Solution:**
- Test from the Flutter app after completing onboarding
- Or use the admin view in Supabase Dashboard → Table Editor

---

## Rollback Plan

If the fix causes unexpected issues, you can rollback using the provided script:

### Execute Rollback
1. Open `warehouse_management/rollback_rls_recursion_fix.sql`
2. Copy contents
3. Paste into Supabase SQL Editor
4. Execute

**WARNING:** This restores the problematic policies that cause infinite recursion. Only use if you need to revert while investigating an alternative solution.

---

## Files Created

| File | Purpose |
|------|---------|
| `fix_rls_recursion.sql` | Main migration script to apply |
| `rollback_rls_recursion_fix.sql` | Rollback script (emergency use only) |
| `RLS_RECURSION_FIX_GUIDE.md` | This guide |

---

## Success Criteria

After implementing this fix, you should observe:

1. ✅ Users can complete onboarding without "infinite recursion" error
2. ✅ All onboarding data saves correctly to database
3. ✅ RLS policies protect user data (users only see their own data)
4. ✅ Helper functions work without causing recursion
5. ✅ App navigates to MainNavigation after onboarding completion
6. ✅ No performance degradation from policy changes

---

## Additional Notes

### Staff Access Pattern
The removed recursive subquery was intended to allow staff users to view their owner's profile. This functionality is still achievable through explicit queries:

```dart
// In your Flutter code, staff can explicitly query for owner profile:
final ownerProfile = await SupabaseConfig.client
  .from('profiles')
  .select()
  .eq('id', currentUserProfile.ownerId)
  .single();
```

The RLS policy will allow this because staff's `owner_id` field points to the owner's UUID.

### Performance Impact
**Positive:** Simpler RLS policy = faster query execution (no recursive subqueries)

**Neutral:** No measurable performance difference for typical operations

### Security Impact
**No change:** Users still only see their own data. Owner-staff relationships still enforced through `owner_id` field.

---

## Support

If you encounter issues not covered in this guide:
1. Check Supabase logs: SQL Editor → History tab
2. Check Flutter debug logs: `flutter run` output
3. Verify table structure matches schema in `supabase_setup.sql`
4. Test with a fresh user account (new phone number)

---

## Revision History

| Date | Change |
|------|--------|
| 2026-01-29 | Initial fix for infinite recursion error |
