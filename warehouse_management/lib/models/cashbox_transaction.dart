/// Cashbox transaction model for tracking cash flow
/// Tracks both incoming (cash_in) and outgoing (cash_out) cash transactions
/// Each transaction is linked to a user and includes amount, description, and category

enum TransactionType {
  cashIn('cash_in'),
  cashOut('cash_out');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String value) {
    switch (value) {
      case 'cash_in':
        return TransactionType.cashIn;
      case 'cash_out':
        return TransactionType.cashOut;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

class CashboxTransaction {
  final String? id;
  final String? userId;
  final TransactionType transactionType;
  final double amount;
  final String description;
  final String? category;
  final DateTime transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CashboxTransaction({
    this.id,
    this.userId,
    required this.transactionType,
    required this.amount,
    required this.description,
    this.category,
    required this.transactionDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Create CashboxTransaction from Supabase JSON
  factory CashboxTransaction.fromMap(Map<String, dynamic> json) {
    return CashboxTransaction(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      transactionType: TransactionType.fromString(json['transaction_type'] as String),
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert CashboxTransaction to Supabase JSON
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'transaction_type': transactionType.value,
      'amount': amount,
      'description': description,
      if (category != null && category!.isNotEmpty) 'category': category,
      'transaction_date': transactionDate.toIso8601String().split('T')[0], // Date only
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Check if transaction is cash in (incoming)
  bool get isCashIn => transactionType == TransactionType.cashIn;

  /// Check if transaction is cash out (outgoing)
  bool get isCashOut => transactionType == TransactionType.cashOut;

  /// Check if transaction has a category
  bool get hasCategory => category != null && category!.isNotEmpty;

  /// Check if transaction is from today
  bool get isToday {
    final now = DateTime.now();
    return transactionDate.year == now.year &&
        transactionDate.month == now.month &&
        transactionDate.day == now.day;
  }

  /// Check if transaction is from this month
  bool get isThisMonth {
    final now = DateTime.now();
    return transactionDate.year == now.year && transactionDate.month == now.month;
  }

  /// Check if transaction is from this year
  bool get isThisYear {
    final now = DateTime.now();
    return transactionDate.year == now.year;
  }

  /// Create a copy of this transaction with updated fields
  CashboxTransaction copyWith({
    String? id,
    String? userId,
    TransactionType? transactionType,
    double? amount,
    String? description,
    String? category,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CashboxTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CashboxTransaction(id: $id, type: ${transactionType.value}, amount: $amount, date: $transactionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CashboxTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
