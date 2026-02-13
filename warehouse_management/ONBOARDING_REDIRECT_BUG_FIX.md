# Critical Onboarding Redirect Bug Fix

**Date:** 2026-02-11
**Status:** ✅ Implemented
**Branch:** feature/royal-blue-theme-and-halkhata-icon

## Problem Summary

On cold start, existing users experienced a critical UX bug:
1. Splash screen appears
2. Home Dashboard (MainNavigation) renders
3. **After 1-2 seconds**, user is wrongly redirected to BusinessInfo onboarding screen
4. This happened EVERY TIME on app restart for existing users

## Root Cause

The bug was caused by **deliberate two-phase routing in AuthWrapper**:

**Phase 1 (Immediate):**
- AuthWrapper sets `_resolvedRoute = MainNavigation`
- User sees Home Dashboard immediately ✅

**Phase 2 (Background, 1-2 seconds later):**
- `_verifyOnboardingWithRetry()` runs async
- Queries `user_business_profiles` with 1-second timeout
- If onboarding appears "incomplete", calls `setState()`
- Changes `_resolvedRoute` to `BusinessInfoScreen`
- User redirected to onboarding ❌

**The problematic setState() call at auth_wrapper.dart:170-172:**
```dart
if (!isCompleteRetry) {
  setState(() {
    _resolvedRoute = BusinessInfoScreen(phoneNumber: userPhone);  // ← THE BUG
  });
}
```

## Solution Implemented

### 1. AuthWrapper Changes (lib/screens/splash/auth_wrapper.dart)

**REMOVED:**
- ❌ `isProfileOnboardingComplete()` helper function (lines 16-36)
- ❌ `_verifyOnboardingWithRetry()` method (lines 103-192)
- ❌ `_checkOnboardingRemote()` method (lines 194-236)
- ❌ All background onboarding verification logic
- ❌ All setState() calls that mutate route to BusinessInfoScreen
- ❌ Unused import: `package:wavezly/services/dashboard_service.dart`
- ❌ Unused import: `package:wavezly/features/onboarding/screens/business_info_screen.dart`

**SIMPLIFIED:**
- ✅ Immediate MainNavigation routing (no delays)
- ✅ One-time sync and notification triggers
- ✅ Race guards for mounted/userId
- ✅ Optional background profile fetch for logging only (no route mutation)

**New Behavior:**
```dart
void _resolveAuthenticatedRouteSync(User user) {
  // Guard: Only resolve once per user session
  if (_resolvedRoute != null && _currentUserId == user.id) {
    return;
  }

  // One-time side effects
  SyncService().syncNow();
  NotificationService.loginUser(user.id);

  // Local-first route resolution
  final bootstrapSummary = BootstrapCache().peekPreloadedSummary();
  final shopName = bootstrapSummary?.shopName;

  // FINAL ROUTE - no background changes allowed
  _resolvedRoute = MainNavigation(initialShopName: shopName);
  _isResolving = false;

  // Optional: Background fetch for logging only (no route mutation)
  _refreshProfileCacheInBackground(user.id);
}
```

**Key Changes:**
- No setState() after initial route resolution
- Background fetch is optional and only for logging
- Route is stable indefinitely

### 2. OTP Verification Changes (lib/features/auth/screens/otp_verification_screen.dart)

**REMOVED:**
- ❌ `_isProfileOnboardingComplete()` helper function (lines 22-42)
- ❌ Database query with timeout (lines 334-349)
- ❌ Onboarding status check based on database fields

**NEW APPROACH: Use Auth Path as Source of Truth**

```dart
Future<void> _handleSignupLoginAuth() async {
  final supabase = SupabaseConfig.client;
  final email = 'phone-${widget.phoneNumber}@halkhata.app';
  final password = _generateSecurePassword(widget.phoneNumber, _currentOtp);

  bool isNewUser = false;

  // Try signIn first (existing user)
  try {
    await supabase.auth.signInWithPassword(email: email, password: password);
    debugPrint('✅ [OTP] Existing user - signIn succeeded');
    isNewUser = false;  // ← DETERMINISTIC: signIn success = existing user
  } catch (signInError) {
    debugPrint('⚠️ [OTP] signIn failed, attempting signUp');

    // Try signUp (new user)
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'phone': widget.phoneNumber,
          'phone_verified': true,
        },
      );

      debugPrint('✅ [OTP] New user - signUp succeeded');
      isNewUser = true;  // ← DETERMINISTIC: signUp success = new user

      // Sign in after sign up
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (signUpError) {
      // Handle user_already_exists edge case
      if (signUpError is AuthApiException &&
          signUpError.code == 'user_already_exists') {
        // Redirect to PIN verification
        Navigator.pushReplacement(context, ...);
        return;
      }
      throw signUpError;
    }
  }

  // ROUTE BASED ON AUTH PATH (deterministic, no timeout queries)
  if (mounted) {
    if (isNewUser) {
      // NEW USER → Onboarding
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => BusinessInfoScreen(phoneNumber: widget.phoneNumber),
      ));
    } else {
      // EXISTING USER → PIN verification
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => PinVerificationScreen(phoneNumber: widget.phoneNumber),
      ));
    }
  }
}
```

**Key Changes:**
- Use `isNewUser` boolean flag based on signUp vs signIn success
- Remove timeout-prone database query
- Deterministic routing: signUp success → BusinessInfo, signIn success → PIN
- No fail-open logic needed (auth API is reliable)

## Why the Bug Can't Happen Anymore

### Code Path Elimination

1. **setState() Removed:**
   - The ONLY line that redirected to BusinessInfo from AuthWrapper was line 171
   - The entire `_verifyOnboardingWithRetry()` method is **deleted**
   - No other code in AuthWrapper can set `_resolvedRoute = BusinessInfoScreen`

2. **Build() Protection:**
   - AuthWrapper's build() returns `_resolvedRoute` directly
   - Without setState(), build() never rebuilds with different route
   - Once MainNavigation is returned, it stays MainNavigation

3. **Async Task Constraints:**
   - `_refreshProfileCacheInBackground()` has NO route mutation code
   - Even if it fetches data, it can't change what user sees
   - Race guards prevent stale callbacks

### Mathematical Proof

```
Let R = _resolvedRoute
Let t = time

At t=0 (auth detected):
  R = MainNavigation

At t=∞ (any future time):
  R = MainNavigation  (unchanged)

Proof by contradiction:
  Assume R changes from MainNavigation to BusinessInfoScreen at some t>0
  → This requires setState() call that assigns BusinessInfoScreen
  → No such setState() exists in modified code
  → Contradiction
  → Therefore R never changes from MainNavigation
  QED
```

## Verification

### Files Modified
1. ✅ `lib/screens/splash/auth_wrapper.dart` (~150 lines removed/modified)
2. ✅ `lib/features/auth/screens/otp_verification_screen.dart` (~60 lines removed/modified)

### Code Analysis
```bash
flutter analyze lib/screens/splash/auth_wrapper.dart lib/features/auth/screens/otp_verification_screen.dart
```
Result: ✅ No errors, only linter warnings (import ordering, unused variables)

### Expected Behavior

**Scenario 1: Existing User Cold Start**
- Splash screen appears
- Home Dashboard (MainNavigation) appears
- User stays on Home Dashboard forever
- No redirect to BusinessInfo

**Scenario 2: New User Registration**
- Login with new phone number → OTP screen
- Enter OTP → signUp succeeds → `isNewUser = true`
- Navigate to BusinessInfoScreen
- Complete onboarding

**Scenario 3: Existing User Login**
- Login screen RPC detects existing user
- Navigate to PinVerificationScreen (no OTP)
- Enter PIN → Navigate to MainNavigation
- Stay on MainNavigation

## Testing Checklist

- [ ] Fresh install + existing account: Splash → Home only (no onboarding redirect)
- [ ] App stays on Home after 10+ seconds
- [ ] First-time registration goes to BusinessInfo onboarding
- [ ] Existing account login goes to PIN flow
- [ ] Kill app during async operations → no effect on next launch
- [ ] Network timeout during profile fetch → no redirect

## Deployment Notes

**Risk Level:** Medium (changing core routing logic)

**Rollback Plan:**
- Keep git commit hash for quick revert
- Monitor crash reports after deployment
- Track navigation events to detect routing issues

**Success Metrics:**
- Zero reports of "Home → Onboarding redirect" from existing users
- New user registration flow success rate maintained
- No increase in crash reports related to authentication

## References

- Original issue: Delayed redirect from Home to BusinessInfo for existing users
- Root cause: Background `setState()` in `_verifyOnboardingWithRetry()`
- Solution: Remove all background route mutations, use auth path as source of truth
