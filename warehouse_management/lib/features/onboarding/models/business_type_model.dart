import 'package:flutter/material.dart';

/// Enum representing different business types with their display properties
enum BusinessType {
  grocery(
    label: 'মুদিখানা',
    emoji: '🍞',
    iconBgColor: Color(0xFFFED7AA), // orange-100
    iconBgColorDark: Color(0xFF7C2D12), // orange-900/30
  ),
  electronics(
    label: 'ইলেক্ট্রনিক্স',
    emoji: '🎧',
    iconBgColor: Color(0xFFE9D5FF), // purple-100
    iconBgColorDark: Color(0xFF581C87), // purple-900/30
  ),
  fashion(
    label: 'ফ্যাশন',
    emoji: '👕',
    iconBgColor: Color(0xFFDBEAFE), // blue-100
    iconBgColorDark: Color(0xFF1E3A8A), // blue-900/30
  ),
  hardware(
    label: 'হার্ডওয়্যার',
    emoji: '🔧',
    iconBgColor: Color(0xFFF3F4F6), // gray-100
    iconBgColorDark: Color(0xFF1F2937), // gray-800
  ),
  ecommerce(
    label: 'অনলাইন ব্যবসা\n(ই-কমার্স)',
    emoji: '🛒',
    iconBgColor: Color(0xFFFCE7F3), // pink-100
    iconBgColorDark: Color(0xFF831843), // pink-900/30
    useSmallText: true,
  ),
  dealer(
    label: 'ডিলার /\nডিস্ট্রিবিউটর',
    emoji: '📦',
    iconBgColor: Color(0xFFD1FAE5), // green-100
    iconBgColorDark: Color(0xFF14532D), // green-900/30
    useSmallText: true,
  ),
  pharmacy(
    label: 'ফার্মেসি',
    emoji: '💊',
    iconBgColor: Color(0xFFFEE2E2), // red-100
    iconBgColorDark: Color(0xFF7F1D1D), // red-900/30
  ),
  other(
    label: 'অন্যান্য',
    emoji: '📋',
    iconBgColor: Color(0xFFFEF9C3), // yellow-100
    iconBgColorDark: Color(0xFF713F12), // yellow-900/30
  );

  final String label;
  final String emoji;
  final Color iconBgColor;
  final Color iconBgColorDark;
  final bool useSmallText;

  const BusinessType({
    required this.label,
    required this.emoji,
    required this.iconBgColor,
    required this.iconBgColorDark,
    this.useSmallText = false,
  });
}

/// Model class for business type selection data
class BusinessTypeModel {
  final BusinessType businessType;
  final DateTime selectedAt;

  const BusinessTypeModel({
    required this.businessType,
    required this.selectedAt,
  });

  /// Convert model to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
        'business_type': businessType.label,
        'business_type_code': businessType.name,
        'selected_at': selectedAt.toIso8601String(),
      };

  /// Create model from JSON data
  factory BusinessTypeModel.fromJson(Map<String, dynamic> json) {
    return BusinessTypeModel(
      businessType: BusinessType.values.firstWhere(
        (e) => e.name == json['business_type_code'],
      ),
      selectedAt: DateTime.parse(json['selected_at'] as String),
    );
  }

  @override
  String toString() =>
      'BusinessTypeModel(type: ${businessType.label}, selectedAt: $selectedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessTypeModel &&
          runtimeType == other.runtimeType &&
          businessType == other.businessType &&
          selectedAt == other.selectedAt;

  @override
  int get hashCode => businessType.hashCode ^ selectedAt.hashCode;
}
