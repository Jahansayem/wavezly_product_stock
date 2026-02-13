import 'package:wavezly/models/expense.dart';
import 'package:wavezly/models/expense_category.dart';
import 'package:wavezly/repositories/expense_repository.dart';

/// Service for managing expenses and expense categories
/// Now uses offline-first repository with local SQLite + sync queue
/// Provides CRUD operations and analytics for expense tracking
class ExpenseService {
  final ExpenseRepository _repository = ExpenseRepository();

  // ============================================================================
  // CATEGORY OPERATIONS
  // ============================================================================

  /// Get all expense categories (system + user's custom categories)
  Future<List<ExpenseCategory>> getCategories(
      {bool forceRefresh = false}) async {
    try {
      return await _repository.getCategories();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Get a single category by ID
  Future<ExpenseCategory?> getCategoryById(String id) async {
    try {
      return await _repository.getCategoryById(id);
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  /// Create a new custom expense category (user-created only)
  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    try {
      return await _repository.createCategory(category);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing custom category (system categories cannot be updated)
  Future<void> updateCategory(String id, ExpenseCategory category) async {
    try {
      await _repository.updateCategory(id, category);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a custom category (system categories cannot be deleted)
  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
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
      return await _repository.createExpense(expense);
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
      return await _repository.getExpenses(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  /// Get a single expense by ID
  Future<Expense?> getExpenseById(String id) async {
    try {
      return await _repository.getExpenseById(id);
    } catch (e) {
      throw Exception('Failed to load expense: $e');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(String id, Expense expense) async {
    try {
      await _repository.updateExpense(id, expense);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & AGGREGATIONS (computed from local data)
  // ============================================================================

  /// Get total expenses for a date range
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      return await _repository.getTotalExpenses(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to calculate total expenses: $e');
    }
  }

  /// Get current month's total expenses
  Future<double> getCurrentMonthTotal() async {
    try {
      return await _repository.getCurrentMonthTotal();
    } catch (e) {
      throw Exception('Failed to get current month total: $e');
    }
  }

  /// Get previous month's total expenses
  Future<double> getPreviousMonthTotal() async {
    try {
      return await _repository.getPreviousMonthTotal();
    } catch (e) {
      throw Exception('Failed to get previous month total: $e');
    }
  }

  /// Get both current and previous month totals in a single call (optimized)
  Future<Map<String, double>> getCurrentAndPreviousMonthTotals({
    bool forceRefresh = false,
  }) async {
    try {
      final currentTotal = await getCurrentMonthTotal();
      final previousTotal = await getPreviousMonthTotal();

      return {
        'current': currentTotal,
        'previous': previousTotal,
      };
    } catch (e) {
      throw Exception('Failed to get month totals: $e');
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
      return await _repository.getCategoryBreakdown(startDate, endDate);
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

      return await _repository.getExpenses(query: query);
    } catch (e) {
      throw Exception('Failed to search expenses: $e');
    }
  }

  /// Get expenses by category ID
  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    try {
      return await _repository.getExpenses(categoryId: categoryId);
    } catch (e) {
      throw Exception('Failed to load expenses by category: $e');
    }
  }

  /// Get transactions count for a date range
  Future<int> getExpenseCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final expenses = await getExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      return expenses.length;
    } catch (e) {
      throw Exception('Failed to get expense count: $e');
    }
  }
}
