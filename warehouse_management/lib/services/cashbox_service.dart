import 'package:wavezly/models/cashbox_transaction.dart';
import 'package:wavezly/models/cashbox_summary.dart';
import 'package:wavezly/repositories/cashbox_repository.dart';

/// Service for managing cashbox transactions and cash flow analytics
/// Provides CRUD operations and analytics for cash flow tracking
/// Now uses local-first repository with sync queue
class CashboxService {
  final CashboxRepository _repository = CashboxRepository();

  // ============================================================================
  // TRANSACTION OPERATIONS
  // ============================================================================

  /// Create a new cashbox transaction
  Future<CashboxTransaction> createTransaction(
      CashboxTransaction transaction) async {
    return await _repository.createTransaction(transaction);
  }

  /// Get all transactions with optional date range filter
  Future<List<CashboxTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get a single transaction by ID
  Future<CashboxTransaction?> getTransactionById(String id) async {
    return await _repository.getTransactionById(id);
  }

  /// Update an existing transaction
  Future<void> updateTransaction(
      String id, CashboxTransaction transaction) async {
    await _repository.updateTransaction(id, transaction);
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
  }

  // ============================================================================
  // ANALYTICS & AGGREGATIONS (computed from local data)
  // ============================================================================

  /// Get summary for a specific date range
  Future<CashboxSummary> getSummary(
      DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      return buildSummaryFromTransactions(transactions, startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  /// Build summary from already-fetched transactions (avoids duplicate queries)
  CashboxSummary buildSummaryFromTransactions(
    List<CashboxTransaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    double totalCashIn = 0.0;
    double totalCashOut = 0.0;

    for (var transaction in transactions) {
      if (transaction.isCashIn) {
        totalCashIn += transaction.amount;
      } else {
        totalCashOut += transaction.amount;
      }
    }

    return CashboxSummary.fromValues(
      cashIn: totalCashIn,
      cashOut: totalCashOut,
      count: transactions.length,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get current balance (up to a specific date, or all time)
  /// Balance = Total Cash In - Total Cash Out
  Future<double> getBalance({DateTime? upToDate}) async {
    try {
      final endDate = upToDate ?? DateTime.now();

      // Get all transactions from beginning to specified date
      final transactions = await _repository.getTransactions(
        endDate: endDate,
      );

      double totalCashIn = 0.0;
      double totalCashOut = 0.0;

      for (var transaction in transactions) {
        if (transaction.isCashIn) {
          totalCashIn += transaction.amount;
        } else {
          totalCashOut += transaction.amount;
        }
      }

      return totalCashIn - totalCashOut;
    } catch (e) {
      throw Exception('Failed to calculate balance: $e');
    }
  }

  /// Get total cash in for a date range
  Future<double> getTotalCashIn(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _repository.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.cashIn,
      );

      double total = 0.0;
      for (var transaction in transactions) {
        total += transaction.amount;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate total cash in: $e');
    }
  }

  /// Get total cash out for a date range
  Future<double> getTotalCashOut(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _repository.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: TransactionType.cashOut,
      );

      double total = 0.0;
      for (var transaction in transactions) {
        total += transaction.amount;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate total cash out: $e');
    }
  }

  /// Get today's summary
  Future<CashboxSummary> getTodaySummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getSummary(startOfDay, endOfDay);
  }

  /// Get current month's summary
  Future<CashboxSummary> getCurrentMonthSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return await getSummary(startOfMonth, endOfMonth);
  }

  /// Get current year's summary
  Future<CashboxSummary> getCurrentYearSummary() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return await getSummary(startOfYear, endOfYear);
  }

  /// Get all-time summary (from beginning)
  Future<CashboxSummary> getAllTimeSummary() async {
    // Use a very early date as start
    final startDate = DateTime(2000, 1, 1);
    final endDate = DateTime.now();

    return await getSummary(startDate, endDate);
  }

  /// Search transactions by description
  Future<List<CashboxTransaction>> searchTransactions(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getTransactions();
      }

      return await _repository.getTransactions(query: query);
    } catch (e) {
      throw Exception('Failed to search transactions: $e');
    }
  }

  /// Get transactions by type (cash_in or cash_out)
  Future<List<CashboxTransaction>> getTransactionsByType(
    TransactionType type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
    } catch (e) {
      throw Exception('Failed to load transactions by type: $e');
    }
  }

  /// Get transactions count for a date range
  Future<int> getTransactionCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      return transactions.length;
    } catch (e) {
      throw Exception('Failed to get transaction count: $e');
    }
  }
}
