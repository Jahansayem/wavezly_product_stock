/// Cashbox summary model for analytics and dashboard display
/// Aggregates cash flow data for a specific date range
/// Includes balance (cash_in - cash_out), totals, and transaction count

class CashboxSummary {
  final double balance;
  final double totalCashIn;
  final double totalCashOut;
  final int transactionCount;
  final DateTime startDate;
  final DateTime endDate;

  CashboxSummary({
    required this.balance,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.transactionCount,
    required this.startDate,
    required this.endDate,
  });

  /// Create empty summary (all zeros)
  factory CashboxSummary.empty(DateTime startDate, DateTime endDate) {
    return CashboxSummary(
      balance: 0.0,
      totalCashIn: 0.0,
      totalCashOut: 0.0,
      transactionCount: 0,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Create summary from individual values
  factory CashboxSummary.fromValues({
    required double cashIn,
    required double cashOut,
    required int count,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return CashboxSummary(
      balance: cashIn - cashOut,
      totalCashIn: cashIn,
      totalCashOut: cashOut,
      transactionCount: count,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Check if there are any transactions
  bool get hasTransactions => transactionCount > 0;

  /// Check if balance is positive (more cash in than out)
  bool get isPositiveBalance => balance > 0;

  /// Check if balance is negative (more cash out than in)
  bool get isNegativeBalance => balance < 0;

  /// Check if balance is zero (equal cash in and out)
  bool get isBalanced => balance == 0;

  /// Get date range description in days
  int get rangeDays => endDate.difference(startDate).inDays + 1;

  /// Create a copy with updated fields
  CashboxSummary copyWith({
    double? balance,
    double? totalCashIn,
    double? totalCashOut,
    int? transactionCount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CashboxSummary(
      balance: balance ?? this.balance,
      totalCashIn: totalCashIn ?? this.totalCashIn,
      totalCashOut: totalCashOut ?? this.totalCashOut,
      transactionCount: transactionCount ?? this.transactionCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  String toString() {
    return 'CashboxSummary(balance: $balance, cashIn: $totalCashIn, cashOut: $totalCashOut, count: $transactionCount, range: $startDate to $endDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CashboxSummary &&
        other.balance == balance &&
        other.totalCashIn == totalCashIn &&
        other.totalCashOut == totalCashOut &&
        other.transactionCount == transactionCount &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      balance,
      totalCashIn,
      totalCashOut,
      transactionCount,
      startDate,
      endDate,
    );
  }
}
