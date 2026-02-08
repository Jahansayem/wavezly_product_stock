# Pgcrypto Schema Fix Summary

## Issue Description

The forgot PIN RPC function (`reset_user_password_by_phone`) was failing with:
```
Exception: function gen_salt(unknown) does not exist
```

## Root Cause

The RPC function used pgcrypto functions (`gen_salt()` and `crypt()`) without properly referencing the schema where pgcrypto is installed.

**Problem Details**:
1. Pgcrypto extension is installed in the `extensions` schema (not `public`)
2. RPC function had `SET search_path = public` (doesn't include `extensions`)
3. Function called `crypt()` and `gen_salt()` without schema prefix
4. PostgreSQL couldn't find the functions in the search path

## Solution Applied

Updated the RPC function to use fully qualified function names with schema prefix:

**Before (Broken)**:
```sql
encrypted_password = crypt(new_password, gen_salt('bf'))
```

**After (Fixed)**:
```sql
encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf'))
```

## Implementation Details

### File Modified
- `supabase/migrations/20260208_reset_password_function.sql` (line 46)

### Migration Applied
- **Migration Name**: `20260208_reset_password_function_fix`
- **Applied Date**: 2026-02-08
- **Status**: ✅ Successfully deployed to Supabase

### Changes Made
```diff
- encrypted_password = crypt(new_password, gen_salt('bf')),
+ encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
```

## Verification

### Direct SQL Test
```sql
SELECT reset_user_password_by_phone('8801724879113', 'test_password_reset_123');
```

**Result**: ✅ PASSED
```json
{
  "success": true,
  "email": "phone-8801724879113@halkhata.app",
  "user_id": "0e5064bb-2373-4882-bfc4-578ff43b59f7"
}
```

### Success Indicators
- ✅ No "function gen_salt(unknown) does not exist" error
- ✅ RPC function returns success response
- ✅ User ID and email correctly returned
- ✅ Password update executes without errors

## Why This Approach

**Option A: Schema-Qualified Names (Chosen)**
- ✅ Explicit and clear about dependencies
- ✅ Works regardless of search_path configuration
- ✅ No ambiguity about function resolution
- ✅ Best practice for production code

**Option B: Update search_path (Not Chosen)**
- Would require: `SET search_path = public, extensions`
- Less explicit about dependencies
- Could cause confusion if search_path changes

## Impact Assessment

### Affected Components
- Forgot PIN authentication flow
- `reset_user_password_by_phone` RPC function
- OTP verification screen (calls this RPC)

### No Impact On
- ✅ New user signup
- ✅ Existing user login
- ✅ Other authentication flows
- ✅ PIN verification flow
- ✅ Other database functions

## Next Steps

### Immediate
1. ✅ Migration deployed
2. ✅ RPC function tested (SQL level)
3. ⏳ Test forgot PIN flow in Flutter app
4. ⏳ Verify end-to-end functionality

### Testing Checklist
- [ ] Test forgot PIN with user 01724879113
- [ ] Verify OTP verification succeeds
- [ ] Verify password reset completes
- [ ] Verify sign-in after reset works
- [ ] Verify new PIN can be set
- [ ] Verify login with new PIN works

### Post-Testing
- [ ] Update FORGOT_PIN_FIX_SUMMARY.md with test results
- [ ] Commit changes
- [ ] Deploy to production
- [ ] Monitor production logs

## Technical Notes

### Pgcrypto Extension Location
```sql
-- Verify pgcrypto extension schema
SELECT extname, nspname
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
WHERE extname = 'pgcrypto';

-- Expected: pgcrypto in 'extensions' schema
```

### Function Search Path
```sql
-- View function's search_path setting
SELECT proname, prosecdef, proconfig
FROM pg_proc
WHERE proname = 'reset_user_password_by_phone';

-- proconfig should show: {search_path=public}
-- Function uses SECURITY DEFINER (prosecdef = true)
```

### Why gen_salt('bf') Uses Blowfish
- Blowfish ('bf') is a secure password hashing algorithm
- Recommended for password storage in PostgreSQL
- Compatible with Supabase auth system
- Provides good security vs performance balance

## References

### Related Files
- `supabase/migrations/20260208_reset_password_function.sql`
- `lib/features/auth/screens/otp_verification_screen.dart`
- `FORGOT_PIN_FIX_SUMMARY.md`
- `TESTING_INSTRUCTIONS.md`

### Related Migrations
1. `20260208_reset_password_function` - Initial RPC creation (had bug)
2. `20260208_reset_password_function_fix` - Fixed pgcrypto schema issue

### Supabase Project
- **Project ID**: ozadmtmkrkwbolzbqtif
- **Region**: ap-northeast-1
- **Database Version**: 17.6.1.063

---

**Fix Applied**: 2026-02-08
**Status**: ✅ Deployed and Verified (SQL Level)
**Next**: Flutter App Testing Required
