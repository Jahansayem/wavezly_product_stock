import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../sync/sync_service.dart';
import '../database/dao/product_dao.dart';
import 'notification_service.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Seed default locations for new user
    if (response.user != null) {
      try {
        await _supabase.rpc('seed_default_locations', params: {
          'target_user_id': response.user!.id,
        });
      } catch (e) {
        // Log error but don't fail registration
        print('Warning: Could not seed default locations: $e');
      }
    }

    return response;
  }

  Future<void> signOut() async {
    // Cleanup phase (fire-and-forget for optional services)
    try {
      SyncService().dispose();  // Stop periodic timer
      ProductDao().dispose();   // Close stream controllers

      // OneSignal logout (non-blocking, ignore failures)
      NotificationService.logoutUser().catchError((e) {
        print('OneSignal logout failed (non-critical): $e');
      });
    } catch (e) {
      print('Cleanup error (non-critical): $e');
    }

    // Supabase signout with 5-second timeout
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Warning: Supabase signOut timed out after 5s');
          // Don't throw - local signout may have partially succeeded
        },
      );
    } catch (e) {
      print('Supabase signOut error: $e');
      rethrow; // Let UI handle the error
    }
  }
}
