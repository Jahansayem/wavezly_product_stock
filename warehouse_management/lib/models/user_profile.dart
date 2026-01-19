/// UserProfile Model
/// Represents a user in the multi-tenant staff management system
/// Maps to the 'profiles' table in Supabase

class UserProfile {
  final String id;              // UUID from auth.users
  final String name;            // Display name
  final String? phone;          // Phone number (optional)
  final String role;            // 'OWNER' or 'STAFF'
  final String? ownerId;        // null for OWNER, UUID for STAFF
  final bool isActive;          // Active status
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    this.ownerId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserProfile from Supabase JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      ownerId: json['owner_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert UserProfile to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'owner_id': ownerId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper getters
  bool get isOwner => role == 'OWNER';
  bool get isStaff => role == 'STAFF';

  /// Copy with method for updates
  UserProfile copyWith({
    String? name,
    String? phone,
    String? role,
    String? ownerId,
    bool? isActive,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      ownerId: ownerId ?? this.ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, role: $role, phone: $phone, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.role == role &&
        other.ownerId == ownerId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        role.hashCode ^
        ownerId.hashCode ^
        isActive.hashCode;
  }
}
