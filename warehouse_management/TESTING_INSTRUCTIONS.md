# Testing Instructions: Forgot PIN Authentication Fix

## Overview
This document provides step-by-step instructions for testing the forgot PIN authentication fix.

## Prerequisites
- ✅ Supabase migration deployed (20260208_reset_password_function_fix)
- ✅ Pgcrypto schema issue fixed (extensions.crypt, extensions.gen_salt)
- ✅ Code changes applied to otp_verification_screen.dart
- ✅ RPC function tested and verified working
- ⏳ Flutter app built and ready to test
- ⏳ Test device or emulator available

## Test Environment Setup

### 1. Verify Migration Deployment
```bash
# Check if RPC function exists in Supabase
# Run this SQL in Supabase SQL Editor:
SELECT proname, proargnames
FROM pg_proc
WHERE proname = 'reset_user_password_by_phone';

# Expected output: Function should exist with args: {user_phone, new_password}
```

### 2. Build and Run App
```bash
# Navigate to project directory
cd warehouse_management

# Get dependencies
flutter pub get

# Run app on connected device/emulator
flutter run
```

### 3. Enable Debug Logging
Ensure debug prints are visible in your terminal/IDE console to monitor the auth flow.

---

## Test Case 1: Forgot PIN Flow (Primary Test)

### User Details
- **Phone Number**: 01724879113
- **Existing User**: Yes (created 2026-01-29)
- **Current OTP**: Check your SMS/console for latest OTP

### Steps to Test

#### Step 1: Trigger Forgot PIN Flow
1. Launch the app
2. You should see the PIN verification screen
3. Tap "পিন ভুলে গেছেন?" (Forgot PIN button)
4. **Expected**: Navigate to OTP verification screen
5. **Debug Log**: Look for OTP sent confirmation

#### Step 2: Enter OTP and Verify
1. Check SMS or debug console for OTP code (e.g., 730244)
2. Enter the OTP in the verification screen
3. Tap verify/submit button
4. **Expected Debug Logs** (in this order):
   ```
   🔄 Forgot PIN: Resetting password for phone-8801724879113@halkhata.app
   ✅ Forgot PIN: Password reset successful
   ✅ Forgot PIN: Sign in successful
   ✅ Auth session created for user: <some-uuid>
   ```
5. **Expected UI**: Navigate to PIN Setup screen (reset mode)

#### Step 3: Set New PIN
1. On PIN Setup screen, enter a new PIN (e.g., 1234)
2. Confirm the PIN
3. Tap submit/save
4. **Expected**: PIN saved successfully
5. **Expected**: Navigate to main app screen (MainNavigation)

#### Step 4: Verify New PIN Works
1. Log out from the app (or restart app)
2. Enter phone number: 01724879113
3. Enter the NEW PIN you just set (e.g., 1234)
4. **Expected**: Successfully log in to app
5. **Expected**: Access main dashboard without errors

### Success Indicators
- ✅ No error message: "লগইন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন"
- ✅ All debug logs appear in correct sequence
- ✅ Successfully navigate to PIN setup screen
- ✅ New PIN saves without errors
- ✅ Can log in with new PIN on next session

### Failure Indicators
- ❌ Error message appears after OTP verification
- ❌ Debug log shows: "❌ Forgot PIN auth error"
- ❌ Stuck on OTP screen, no navigation
- ❌ Cannot log in with new PIN

---

## Test Case 2: Database Verification

### Verify User Data
Run this query in Supabase SQL Editor:

```sql
-- Check user exists with correct email format
SELECT
  id,
  email,
  phone,
  created_at,
  updated_at
FROM auth.users
WHERE email = 'phone-8801724879113@halkhata.app';
```

**Expected Result**:
- Email: `phone-8801724879113@halkhata.app` (lowercase 'phone-')
- Phone: null (or 8801724879113 if populated)
- Updated_at: Should change after password reset

### Verify Password Changed
After forgot PIN flow completes:

```sql
-- Check that password was updated (timestamp should be recent)
SELECT
  email,
  updated_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'phone-8801724879113@halkhata.app';
```

**Expected**:
- `updated_at` should be recent (within last few minutes)
- `last_sign_in_at` should also be recent

---

## Test Case 3: RPC Function Direct Test

### Test RPC Function Independently
Run this in Supabase SQL Editor:

```sql
-- Test password reset function directly
SELECT reset_user_password_by_phone(
  '8801724879113',
  'temporary_test_password_123'
);
```

**Expected Output**:
```json
{
  "success": true,
  "email": "phone-8801724879113@halkhata.app",
  "user_id": "<uuid-of-user>"
}
```

**If User Not Found**:
```json
{
  "success": false,
  "error": "User not found"
}
```

---

## Test Case 4: Regression Testing

### Test A: New User Signup
**Purpose**: Ensure signup flow still works

1. Use a different phone number (e.g., 01712345678)
2. Go through signup flow
3. Enter phone number → Get OTP → Verify OTP → Set PIN
4. **Verify**: User created in database with lowercase email
5. **Verify**: Can log in with PIN after signup

**Database Check**:
```sql
SELECT email FROM auth.users
WHERE email LIKE '%01712345678%';
-- Expected: phone-8801712345678@halkhata.app
```

### Test B: Existing User Login
**Purpose**: Ensure normal login still works

1. Use an existing user (not the forgot PIN test user)
2. Enter phone number
3. Enter correct PIN
4. **Verify**: Login successful without errors

### Test C: Forgot PIN for Different User
**Purpose**: Ensure forgot PIN works universally

1. Use a different existing user
2. Trigger forgot PIN flow
3. Complete OTP verification
4. Set new PIN
5. **Verify**: Process completes without errors

---

## Test Case 5: Error Scenarios

### Test A: Non-Existent User
1. Try forgot PIN with unregistered phone number (e.g., 01799999999)
2. Request OTP (if OTP is sent for non-existent users)
3. Enter OTP
4. **Expected**: RPC should return "User not found" error
5. **Expected**: Display appropriate error message

### Test B: Invalid OTP
1. Trigger forgot PIN for existing user
2. Enter WRONG OTP code
3. **Expected**: OTP validation fails BEFORE password reset
4. **Expected**: User remains on OTP screen with error

### Test C: Network Interruption
1. Trigger forgot PIN flow
2. Turn off network/WiFi during OTP verification
3. Try to verify OTP
4. **Expected**: Network error displayed
5. Turn network back on
6. Retry OTP verification
7. **Expected**: Should work after network restored

---

## Monitoring and Debugging

### Key Debug Logs to Watch

**Success Path**:
```
🔄 Forgot PIN: Resetting password for phone-8801724879113@halkhata.app
✅ Forgot PIN: Password reset successful
✅ Forgot PIN: Sign in successful
✅ Auth session created for user: <uuid>
```

**Failure Indicators**:
```
❌ Forgot PIN auth error: <error-message>
```

### Common Issues and Solutions

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| "User not found" error | Email case mismatch | Verify email is lowercase in code |
| "Invalid credentials" error | Password generation mismatch | Check RPC function deployed |
| RPC function not found | Migration not applied | Re-run migration deployment |
| No navigation after OTP | Exception thrown | Check debug logs for error |
| Cannot log in with new PIN | PIN not saved | Check PIN setup screen logs |

### Debug Checklist
- [ ] Migration applied successfully
- [ ] RPC function exists in Supabase
- [ ] Email case is lowercase in all code locations
- [ ] Debug logs appear in console
- [ ] No exceptions thrown during auth flow
- [ ] Session created successfully
- [ ] Navigation occurs after auth

---

## Test Results Documentation

### Template for Recording Results

```markdown
## Test Results - [Date]

### Test Case 1: Forgot PIN Flow
- **Status**: ✅ PASS / ❌ FAIL
- **Phone**: 01724879113
- **OTP Used**: [otp-code]
- **New PIN Set**: [yes/no]
- **Login with New PIN**: ✅ PASS / ❌ FAIL
- **Issues Found**: [describe any issues]

### Test Case 2: Database Verification
- **Email Format**: ✅ CORRECT / ❌ INCORRECT
- **Updated Timestamp**: ✅ RECENT / ❌ OLD
- **Issues Found**: [describe any issues]

### Test Case 3: RPC Direct Test
- **Status**: ✅ PASS / ❌ FAIL
- **Response**: [json-response]
- **Issues Found**: [describe any issues]

### Test Case 4: Regression Tests
- **New User Signup**: ✅ PASS / ❌ FAIL
- **Existing User Login**: ✅ PASS / ❌ FAIL
- **Forgot PIN (Other User)**: ✅ PASS / ❌ FAIL

### Test Case 5: Error Scenarios
- **Non-Existent User**: ✅ PASS / ❌ FAIL
- **Invalid OTP**: ✅ PASS / ❌ FAIL
- **Network Interruption**: ✅ PASS / ❌ FAIL

### Overall Assessment
- **All Tests Passed**: ✅ YES / ❌ NO
- **Ready for Production**: ✅ YES / ❌ NO / ⏳ NEEDS FIXES
- **Additional Notes**: [any other observations]
```

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Update FORGOT_PIN_FIX_SUMMARY.md with test results
2. Commit changes with descriptive message
3. Create pull request for review
4. Deploy to production after approval
5. Monitor production logs for any issues

### If Tests Fail ❌
1. Document failure details
2. Check debug logs for exact error
3. Verify migration deployment
4. Verify code changes applied correctly
5. Test RPC function independently
6. Fix identified issues
7. Re-run tests

### Rollback Plan
If critical issues found:
1. Revert code changes:
   ```bash
   git checkout HEAD~1 lib/features/auth/screens/otp_verification_screen.dart
   ```
2. Optionally drop RPC function:
   ```sql
   DROP FUNCTION IF EXISTS reset_user_password_by_phone(TEXT, TEXT);
   ```
3. Deploy old version
4. Re-investigate and fix properly

---

## Support and Troubleshooting

### Where to Get Help
- Check debug logs first
- Review FORGOT_PIN_FIX_SUMMARY.md for implementation details
- Check Supabase dashboard for auth logs
- Verify migration status in Supabase

### Useful Supabase Queries
```sql
-- Check all users with specific phone pattern
SELECT email, created_at FROM auth.users
WHERE email LIKE '%01724879113%';

-- Check recent password updates
SELECT email, updated_at FROM auth.users
ORDER BY updated_at DESC LIMIT 10;

-- Test RPC function
SELECT reset_user_password_by_phone(
  '8801724879113',
  'test_password'
);
```

---

**Last Updated**: 2026-02-08
**Implementation Status**: ✅ Code Deployed, ✅ Pgcrypto Fix Applied, ⏳ Awaiting Flutter Testing
**Migration Applied**: 20260208_reset_password_function_fix
**RPC Test Result**: ✅ PASSED (Direct SQL test successful)
**Next Action**: Run Test Case 1 with phone 01724879113 in Flutter app
