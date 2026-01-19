import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/cashbox_transaction.dart';
import 'package:wavezly/models/cashbox_summary.dart';

/// Service for managing cashbox transactions and cash flow analytics
/// Provides CRUD operations and analytics for cash flow tracking
class CashboxService {
  final _supabase = SupabaseConfig.client;

  // ============================================================================
  // TRANSACTION OPERATIONS
  // ============================================================================

  /// Create a new cashbox transaction
  Future<CashboxTransaction> createTransaction(CashboxTransaction transaction) async {
    try {
      final data = transaction.toMap();
      data['user_id'] = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('cashbox_transactions')
          .insert(data)
          .select()
          .single();

      return CashboxTransaction.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Get all transactions with optional date range filter
  Future<List<CashboxTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('cashbox_transactions')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('transaction_date', ascending: false);

      return (response as List).map((item) => CashboxTransaction.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  /// Get a single transaction by ID
  Future<CashboxTransaction?> getTransactionById(String id) async {
    try {
      final response = await _supabase
          .from('cashbox_transactions')
          .select()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .maybeSingle();

      return response != null ? CashboxTransaction.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to load transaction: $e');
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(String id, CashboxTransaction transaction) async {
    try {
      final data = transaction.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('cashbox_transactions')
          .update(data)
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _supabase
          .from('cashbox_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & AGGREGATIONS
  // ============================================================================

  /// Get summary for a specific date range
  Future<CashboxSummary> getSummary(DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactions(
        startDate: startDate,
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

      return CashboxSummary.fromValues(
        cashIn: totalCashIn,
        cashOut: totalCashOut,
        count: transactions.length,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get summary: $e');
    }
  }

  /// Get current balance (up to a specific date, or all time)
  /// Balance = Total Cash In - Total Cash Out
  Future<double> getBalance({DateTime? upToDate}) async {
    try {
      final endDate = upToDate ?? DateTime.now();

      // Get all transactions from beginning to specified date
      final response = await _supabase
          .from('cashbox_transactions')
          .select('transaction_type, amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

      double totalCashIn = 0.0;
      double totalCashOut = 0.0;

      for (var item in response as List) {
        final type = item['transaction_type'] as String;
        final amount = item['amount'] is int
            ? (item['amount'] as int).toDouble()
            : (item['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'cash_in') {
          totalCashIn += amount;
        } else if (type == 'cash_out') {
          totalCashOut += amount;
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
      final response = await _supabase
          .from('cashbox_transactions')
          .select('amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('transaction_type', 'cash_in')
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

      double total = 0.0;
      for (var item in response as List) {
        final amount = item['amount'];
        if (amount != null) {
          total += amount is int ? amount.toDouble() : (amount as num).toDouble();
        }
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate total cash in: $e');
    }
  }

  /// Get total cash out for a date range
  Future<double> getTotalCashOut(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('cashbox_transactions')
          .select('amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('transaction_type', 'cash_out')
          .gte('transaction_date', startDate.toIso8601String().split('T')[0])
          .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

      double total = 0.0;
      for (var item in response as List) {
        final amount = item['amount'];
        if (amount != null) {
          total += amount is int ? amount.toDouble() : (amount as num).toDouble();
        }
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

      final response = await _supabase
          .from('cashbox_transactions')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .ilike('description', '%$query%')
          .order('transaction_date', ascending: false);

      return (response as List).map((item) => CashboxTransaction.fromMap(item)).toList();
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
      var query = _supabase
          .from('cashbox_transactions')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('transaction_type', type.value);

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('transaction_date', ascending: false);

      return (response as List).map((item) => CashboxTransaction.fromMap(item)).toList();
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
