import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

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
    await _supabase.auth.signOut();
  }
}
