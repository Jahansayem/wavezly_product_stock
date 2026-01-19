import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/expense.dart';
import 'package:wavezly/models/expense_category.dart';

/// Service for managing expenses and expense categories
/// Provides CRUD operations and analytics for expense tracking
class ExpenseService {
  final _supabase = SupabaseConfig.client;

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  /// Get all expense categories (system + user's custom categories)
  Future<List<ExpenseCategory>> getCategories() async {
    try {
      final response = await _supabase
          .from('expense_categories')
          .select()
          .order('is_system', ascending: false)
          .order('name_bengali', ascending: true);

      return (response as List)
          .map((item) => ExpenseCategory.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get a single category by ID
  Future<ExpenseCategory?> getCategoryById(String id) async {
    try {
      final response = await _supabase
          .from('expense_categories')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? ExpenseCategory.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  /// Create a new custom expense category (user-created only)
  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    try {
      final data = category.toMap();
      data['user_id'] = _supabase.auth.currentUser!.id;
      data['is_system'] = false; // User categories are never system categories

      final response = await _supabase
          .from('expense_categories')
          .insert(data)
          .select()
          .single();

      return ExpenseCategory.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing custom category (system categories cannot be updated)
  Future<void> updateCategory(String id, ExpenseCategory category) async {
    try {
      final data = category.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('expense_categories')
          .update(data)
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_system', false); // Ensure only non-system categories are updated
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a custom category (system categories cannot be deleted)
  Future<void> deleteCategory(String id) async {
    try {
      await _supabase
          .from('expense_categories')
          .delete()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_system', false); // Ensure only non-system categories are deleted
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ============================================================================
  // EXPENSE OPERATIONS
  // ============================================================================

  /// Create a new expense
  Future<Expense> createExpense(Expense expense) async {
    try {
      final data = expense.toMap();
      data['user_id'] = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('expenses')
          .insert(data)
          .select()
          .single();

      return Expense.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Get all expenses with optional date range filter
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('expenses')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);

      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('expense_date', ascending: false);

      return (response as List).map((item) => Expense.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  /// Get a single expense by ID
  Future<Expense?> getExpenseById(String id) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id)
          .maybeSingle();

      return response != null ? Expense.fromMap(response) : null;
    } catch (e) {
      throw Exception('Failed to load expense: $e');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(String id, Expense expense) async {
    try {
      final data = expense.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('expenses')
          .update(data)
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', id)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & AGGREGATIONS
  // ============================================================================

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select('amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0]);

      if (response == null || (response as List).isEmpty) {
        return 0.0;
      }

      double total = 0.0;
      for (var item in response as List) {
        final amount = item['amount'];
        if (amount != null) {
          total += amount is int ? amount.toDouble() : (amount as num).toDouble();
        }
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate total expenses: $e');
    }
  }

  /// Get current month's total expenses
  Future<double> getCurrentMonthTotal() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      return await getTotalExpenses(startOfMonth, endOfMonth);
    } catch (e) {
      throw Exception('Failed to get current month total: $e');
    }
  }

  /// Get previous month's total expenses
  Future<double> getPreviousMonthTotal() async {
    try {
      final now = DateTime.now();
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

      return await getTotalExpenses(startOfLastMonth, endOfLastMonth);
    } catch (e) {
      throw Exception('Failed to get previous month total: $e');
    }
  }

  /// Get today's total expenses
  Future<double> getTodayTotal() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return await getTotalExpenses(startOfDay, endOfDay);
    } catch (e) {
      throw Exception('Failed to get today total: $e');
    }
  }

  /// Get expense breakdown by category for a date range
  /// Returns map of category_id -> total_amount
  Future<Map<String, double>> getCategoryBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select('category_id, amount')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0]);

      final breakdown = <String, double>{};

      for (var item in response as List) {
        final categoryId = item['category_id'] as String?;
        if (categoryId != null) {
          final amount = item['amount'];
          final amountDouble = amount is int ? amount.toDouble() : (amount as num).toDouble();
          breakdown[categoryId] = (breakdown[categoryId] ?? 0.0) + amountDouble;
        }
      }

      return breakdown;
    } catch (e) {
      throw Exception('Failed to get category breakdown: $e');
    }
  }

  /// Search expenses by description
  Future<List<Expense>> searchExpenses(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getExpenses();
      }

      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .ilike('description', '%$query%')
          .order('expense_date', ascending: false);

      return (response as List).map((item) => Expense.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }

  /// Get expenses by category ID
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('category_id', categoryId)
          .order('expense_date', ascending: false);

      return (response as List).map((item) => Expense.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load expenses by category: $e');
    }
  }
}
