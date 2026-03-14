/// UserProfile Model
/// Represents a user in the multi-tenant staff management system
/// Maps to the 'profiles' table in Supabase

class UserProfile {
  final String id; // UUID from auth.users
  final String name; // Display name
  final String? phone; // Phone number (optional)
  final String? address; // Address (optional)
  final String? email; // Email (optional)
  final DateTime? birthday; // Birthday (optional)
  final String? gender; // Gender (optional)
  final String? avatarUrl; // Profile image (optional)
  final String role; // 'OWNER' or 'STAFF'
  final String? ownerId; // null for OWNER, UUID for STAFF
  final bool isActive; // Active status
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.birthday,
    this.gender,
    this.avatarUrl,
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
      address: json['address'] as String?,
      email: json['email'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
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
      'address': address,
      'email': email,
      'birthday': birthday != null ? _formatDateOnly(birthday!) : null,
      'gender': gender,
      'avatar_url': avatarUrl,
      'role': role,
      'owner_id': ownerId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert the mutable profile fields to a Supabase update payload.
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'birthday': birthday != null ? _formatDateOnly(birthday!) : null,
      'gender': gender,
      'avatar_url': avatarUrl,
      'role': role,
      'owner_id': ownerId,
      'is_active': isActive,
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
    String? address,
    String? email,
    DateTime? birthday,
    bool clearBirthday = false,
    String? gender,
    bool clearGender = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? role,
    String? ownerId,
    bool? isActive,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      gender: clearGender ? null : (gender ?? this.gender),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      role: role ?? this.role,
      ownerId: ownerId ?? this.ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, role: $role, phone: $phone, email: $email, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.address == address &&
        other.email == email &&
        other.birthday == birthday &&
        other.gender == gender &&
        other.avatarUrl == avatarUrl &&
        other.role == role &&
        other.ownerId == ownerId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        phone.hashCode ^
        address.hashCode ^
        email.hashCode ^
        birthday.hashCode ^
        gender.hashCode ^
        avatarUrl.hashCode ^
        role.hashCode ^
        ownerId.hashCode ^
        isActive.hashCode;
  }

  static String _formatDateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
