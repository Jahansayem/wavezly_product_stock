import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/features/auth/screens/login_screen.dart';
import 'package:wavezly/features/onboarding/screens/business_info_screen.dart';
import 'package:wavezly/services/notification_service.dart';
import 'package:wavezly/sync/sync_service.dart';

/// Handles authentication state and routes to appropriate screen.
/// Routes based on authentication and onboarding status:
/// - Not authenticated → LoginScreen
/// - Authenticated + onboarding incomplete → BusinessInfoScreen
/// - Authenticated + onboarding complete → MainNavigation
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkOnboardingCompleted(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_business_profiles')
          .select('onboarding_completed_at')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null && response['onboarding_completed_at'] != null;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false; // Assume onboarding not complete on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data!.session != null &&
            snapshot.data!.session!.user != null) {
          final user = snapshot.data!.session!.user!;

          // User authenticated - check onboarding status
          return FutureBuilder<bool>(
            future: _checkOnboardingCompleted(user.id),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState ==
                  ConnectionState.waiting) {
                // Show loading while checking onboarding
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final onboardingComplete = onboardingSnapshot.data ?? false;

              if (onboardingComplete) {
                // Onboarding complete - go to main app
                print('User authenticated, triggering sync...');
                SyncService().syncNow();

                // Login user to OneSignal for push targeting
                NotificationService.loginUser(user.id);

                return const MainNavigation();
              } else {
                // Onboarding not complete - go to onboarding
                return BusinessInfoScreen(
                  phoneNumber: user.phone ?? '',
                );
              }
            },
          );
        } else {
          // Not authenticated - go to login
          return const LoginScreen();
        }
      },
    );
  }
}
