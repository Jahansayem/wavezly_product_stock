/// Expense model for tracking business expenses
/// Each expense is linked to a category and user
class Expense {
  final String? id;
  final String? userId;
  final String? categoryId;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense({
    this.id,
    this.userId,
    this.categoryId,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Expense from Supabase JSON
  factory Expense.fromMap(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      categoryId: json['category_id'] as String?,
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Expense to Supabase JSON
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      'amount': amount,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0], // Date only
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Check if expense has a description
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Check if expense is linked to a category
  bool get hasCategory => categoryId != null;

  /// Check if expense is from today
  bool get isToday {
    final now = DateTime.now();
    return expenseDate.year == now.year &&
        expenseDate.month == now.month &&
        expenseDate.day == now.day;
  }

  /// Check if expense is from this month
  bool get isThisMonth {
    final now = DateTime.now();
    return expenseDate.year == now.year && expenseDate.month == now.month;
  }

  /// Create a copy of this expense with updated fields
  Expense copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, categoryId: $categoryId, date: $expenseDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
