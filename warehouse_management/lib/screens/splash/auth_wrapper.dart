import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/features/auth/screens/login_screen.dart';
import 'package:wavezly/services/notification_service.dart';
import 'package:wavezly/services/bootstrap_cache.dart';
import 'package:wavezly/sync/sync_service.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Handles authentication state and routes to appropriate screen.
/// Routes based on authentication status only:
/// - Not authenticated → LoginScreen
/// - Authenticated → MainNavigation (always, no onboarding checks)
/// Onboarding routing is handled by OTP flow, not here.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Widget? _resolvedRoute;
  bool _isResolving = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Start bootstrap preload immediately (deduped, non-blocking)
    BootstrapCache().ensurePreloadStarted();
  }

  /// Resolve authenticated route synchronously using local data only.
  /// Returns MainNavigation immediately with available local data.
  /// No background onboarding checks - route is FINAL once set.
  void _resolveAuthenticatedRouteSync(User user) {
    // Guard: Only resolve once per user session
    if (_resolvedRoute != null && _currentUserId == user.id) {
      return;
    }

    if (_isResolving && _currentUserId == user.id) {
      return;
    }

    _isResolving = true;
    _currentUserId = user.id;

    debugPrint('🔐 [AuthWrapper] Resolving route for user: ${user.id}');
    debugPrint('🔐 [AuthWrapper] Current phone: ${user.phone}');

    // One-time side effects
    SyncService().syncNow();
    NotificationService.loginUser(user.id);
    debugPrint('🔐 [AuthWrapper] Sync and notifications triggered');

    // Local-first route resolution
    final bootstrapSummary = BootstrapCache().peekPreloadedSummary();
    final shopName = bootstrapSummary?.shopName;

    // FINAL ROUTE - no background changes allowed
    _resolvedRoute = MainNavigation(initialShopName: shopName);
    _isResolving = false;

    debugPrint(
        '🔐 [AuthWrapper] Immediate route: MainNavigation (shopName: ${shopName ?? "null"})');
    debugPrint('🔐 [AuthWrapper] Route is FINAL - no background changes');

    // Optional: Background fetch for cache refresh (no route mutation)
    _refreshProfileCacheInBackground(user.id);
  }

  /// Optional: Fetch profile data for logging/monitoring only.
  /// Does NOT update route or trigger setState() - purely informational.
  Future<void> _refreshProfileCacheInBackground(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_business_profiles')
          .select('shop_name')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (response != null && mounted && _currentUserId == userId) {
        final shopName = response['shop_name'] as String?;
        debugPrint(
            '🔄 [AuthWrapper] Background profile fetch result: shopName=$shopName');
      }
    } catch (e) {
      debugPrint('⚠️ [AuthWrapper] Background profile fetch failed: $e');
      // Silent fail, no action needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check authentication state
        final session = snapshot.data?.session;
        final user = session?.user;

        if (user != null) {
          // User authenticated - resolve route synchronously
          _resolveAuthenticatedRouteSync(user);

          if (_resolvedRoute != null) {
            return _resolvedRoute!;
          } else {
            // Very brief resolving state - show splash background (no spinner)
            return Scaffold(
              backgroundColor: ColorPalette.amberYellow,
              body: const SizedBox.shrink(),
            );
          }
        } else {
          // Not authenticated - go to login
          _resolvedRoute = null;
          _isResolving = false;
          _currentUserId = null;
          return const LoginScreen();
        }
      },
    );
  }
}
