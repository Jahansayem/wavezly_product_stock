import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

/// UserService
/// Handles all user management operations including CRUD for profiles
/// Supports multi-tenant staff management (OWNER + STAFF roles)

class UserService {
  final _supabase = SupabaseConfig.client;

  /// Get all users (owner + their staff)
  /// RLS automatically filters to show only business-related users
  Future<List<UserProfile>> getUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserProfile?> getUserById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? UserProfile.fromJson(response) : null;
    } catch (e) {
      print('Error fetching user by ID: $e');
      rethrow;
    }
  }

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      return getUserById(userId);
    } catch (e) {
      print('Error fetching current user profile: $e');
      rethrow;
    }
  }

  /// Create staff user (owner only)
  /// Note: This creates a profile entry, but auth.users entry must exist first
  /// For full staff creation, you need to:
  /// 1. Create auth.users entry via Supabase Auth
  /// 2. Call this method to set up the staff profile
  Future<void> createStaff({
    required String authUserId,
    required String name,
    String? phone,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('Not authenticated');
      }

      await _supabase.from('profiles').insert({
        'id': authUserId,
        'name': name,
        'phone': phone,
        'role': 'STAFF',
        'owner_id': currentUserId,
        'is_active': true,
      });
    } catch (e) {
      print('Error creating staff: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUser(UserProfile user) async {
    try {
      await _supabase
          .from('profiles')
          .update(user.toJson())
          .eq('id', user.id);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Update user name
  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'name': newName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error updating user name: $e');
      rethrow;
    }
  }

  /// Update user phone
  Future<void> updateUserPhone(String userId, String? newPhone) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'phone': newPhone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error updating user phone: $e');
      rethrow;
    }
  }

  /// Toggle user active status
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Error toggling user status: $e');
      rethrow;
    }
  }

  /// Delete user (owner can delete staff)
  /// Note: This only deletes the profile, not the auth.users entry
  /// To fully delete a user, you need to delete from auth.users as well
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', userId);
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Search users by name, phone, or role
  /// Returns all users if query is empty
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return getUsers();

      final response = await _supabase
          .from('profiles')
          .select()
          .or('name.ilike.%$query%,phone.ilike.%$query%,role.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  /// Get active users count
  Future<int> getActiveUsersCount() async {
    try {
      final users = await getUsers();
      return users.where((u) => u.isActive).length;
    } catch (e) {
      print('Error getting active users count: $e');
      return 0;
    }
  }

  /// Get staff count (excluding owners)
  Future<int> getStaffCount() async {
    try {
      final users = await getUsers();
      return users.where((u) => u.isStaff).length;
    } catch (e) {
      print('Error getting staff count: $e');
      return 0;
    }
  }

  /// Get only active users
  Future<List<UserProfile>> getActiveUsers() async {
    try {
      final users = await getUsers();
      return users.where((u) => u.isActive).toList();
    } catch (e) {
      print('Error getting active users: $e');
      rethrow;
    }
  }

  /// Get only staff users
  Future<List<UserProfile>> getStaffUsers() async {
    try {
      final users = await getUsers();
      return users.where((u) => u.isStaff).toList();
    } catch (e) {
      print('Error getting staff users: $e');
      rethrow;
    }
  }

  /// Check if current user is owner
  Future<bool> isCurrentUserOwner() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isOwner ?? false;
    } catch (e) {
      print('Error checking if current user is owner: $e');
      return false;
    }
  }

  /// Check if current user is staff
  Future<bool> isCurrentUserStaff() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isStaff ?? false;
    } catch (e) {
      print('Error checking if current user is staff: $e');
      return false;
    }
  }
}
