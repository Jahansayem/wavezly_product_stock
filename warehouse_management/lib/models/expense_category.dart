import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Expense category model for categorizing expenses
/// Supports both system categories (pre-defined) and user-created custom categories
class ExpenseCategory {
  final String? id;
  final String? userId;
  final String name;
  final String nameBengali;
  final String? description;
  final String? descriptionBengali;
  final String iconName;
  final String iconColor;
  final String bgColor;
  final bool isSystem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseCategory({
    this.id,
    this.userId,
    required this.name,
    required this.nameBengali,
    this.description,
    this.descriptionBengali,
    required this.iconName,
    required this.iconColor,
    required this.bgColor,
    this.isSystem = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create ExpenseCategory from Supabase JSON
  factory ExpenseCategory.fromMap(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? '',
      nameBengali: json['name_bengali'] as String? ?? '',
      description: json['description'] as String?,
      descriptionBengali: json['description_bengali'] as String?,
      iconName: json['icon_name'] as String? ?? 'category',
      iconColor: json['icon_color'] as String? ?? 'blue600',
      bgColor: json['bg_color'] as String? ?? 'blue100',
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ExpenseCategory to Supabase JSON
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'name_bengali': nameBengali,
      if (description != null) 'description': description,
      if (descriptionBengali != null) 'description_bengali': descriptionBengali,
      'icon_name': iconName,
      'icon_color': iconColor,
      'bg_color': bgColor,
      'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Get Flutter IconData from icon name string
  /// Maps Material Icons names to IconData constants
  IconData getIconData() {
    switch (iconName) {
      case 'payments':
        return Icons.payments;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'receipt':
        return Icons.receipt;
      case 'storefront':
        return Icons.storefront;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'category':
        return Icons.category;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'build':
        return Icons.build;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'phone':
        return Icons.phone;
      case 'wifi':
        return Icons.wifi;
      case 'electric_bolt':
        return Icons.electric_bolt;
      case 'water_drop':
        return Icons.water_drop;
      case 'celebration':
        return Icons.celebration;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }

  /// Get Flutter Color from color name string (icon color)
  Color getIconColor() {
    switch (iconColor) {
      case 'blue600':
        return ColorPalette.blue600;
      case 'orange600':
        return ColorPalette.orange600;
      case 'purple600':
        return ColorPalette.purple600;
      case 'emerald600':
        return ColorPalette.emerald600;
      case 'red600':
        return ColorPalette.red600;
      case 'teal600':
        return ColorPalette.teal600;
      case 'indigo600':
        return ColorPalette.indigo600;
      case 'amber600':
        return ColorPalette.amber600;
      case 'lime600':
        return ColorPalette.lime600;
      case 'sky600':
        return ColorPalette.sky600;
      case 'violet600':
        return ColorPalette.violet600;
      case 'fuchsia600':
        return ColorPalette.fuchsia600;
      case 'cyan600':
        return ColorPalette.cyan600;
      case 'yellow600':
        return ColorPalette.yellow600;
      case 'green600':
        return ColorPalette.green600;
      case 'rose600':
        return ColorPalette.rose600;
      default:
        return ColorPalette.blue600;
    }
  }

  /// Get Flutter Color from color name string (background color)
  Color getBgColor() {
    switch (bgColor) {
      case 'blue100':
        return ColorPalette.blue100;
      case 'orange100':
        return ColorPalette.orange100;
      case 'purple100':
        return ColorPalette.purple100;
      case 'emerald100':
        return ColorPalette.emerald100;
      case 'red100':
        return ColorPalette.red100;
      case 'teal100':
        return ColorPalette.teal100;
      case 'indigo100':
        return ColorPalette.indigo100;
      case 'amber100':
        return ColorPalette.amber100;
      case 'lime100':
        return ColorPalette.lime100;
      case 'sky100':
        return ColorPalette.sky100;
      case 'violet100':
        return ColorPalette.violet100;
      case 'fuchsia100':
        return ColorPalette.fuchsia100;
      case 'cyan100':
        return ColorPalette.cyan100;
      case 'yellow100':
        return ColorPalette.yellow100;
      case 'rose100':
        return ColorPalette.rose100;
      default:
        return ColorPalette.blue100;
    }
  }

  /// Create a copy of this category with updated fields
  ExpenseCategory copyWith({
    String? id,
    String? userId,
    String? name,
    String? nameBengali,
    String? description,
    String? descriptionBengali,
    String? iconName,
    String? iconColor,
    String? bgColor,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      nameBengali: nameBengali ?? this.nameBengali,
      description: description ?? this.description,
      descriptionBengali: descriptionBengali ?? this.descriptionBengali,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      bgColor: bgColor ?? this.bgColor,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ExpenseCategory(id: $id, name: $name, nameBengali: $nameBengali, isSystem: $isSystem)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExpenseCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
