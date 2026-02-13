import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../database/dao/expense_dao.dart';
import '../database/dao/expense_category_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class ExpenseRepository {
  final ExpenseDao _expenseDao = ExpenseDao();
  final ExpenseCategoryDao _categoryDao = ExpenseCategoryDao();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Sync cooldown management
  DateTime? _lastSyncTrigger;
  static const _syncCooldownSeconds = 30;

  String get _userId {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user. Please login first.');
    }
    return currentUser.id;
  }

  // ============================================================================
  // CATEGORY OPERATIONS: Save locally + queue for sync
  // ============================================================================

  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    try {
      final userId = _userId;

      // Generate ID if not present
      final id = category.id ?? const Uuid().v4();
      final now = DateTime.now();

      final newCategory = category.copyWith(
        id: id,
        userId: userId,
        isSystem: false, // User categories are never system categories
        createdAt: category.createdAt ?? now,
        updatedAt: now,
      );

      // Insert to local database
      await _categoryDao.insertCategory(newCategory, userId);

      // Queue for sync
      final data = newCategory.toMap();
      data['user_id'] = userId;
      data['id'] = id;
      data['is_system'] = false;

      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'expense_categories',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }

      return newCategory;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<void> updateCategory(String id, ExpenseCategory category) async {
    try {
      final userId = _userId;

      // Update local database
      await _categoryDao.updateCategory(id, category, userId);

      // Queue for sync
      final data = category.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'expense_categories',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final userId = _userId;

      // Delete from local database
      await _categoryDao.deleteCategory(id, userId);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'expense_categories',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<ExpenseCategory?> getCategoryById(String id) async {
    try {
      return await _categoryDao.getCategoryById(id);
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  Future<List<ExpenseCategory>> getCategories() async {
    try {
      final userId = _userId;
      return await _categoryDao.getAllForUserAndSystem(userId);
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // ============================================================================
  // EXPENSE OPERATIONS: Save locally + queue for sync
  // ============================================================================

  Future<Expense> createExpense(Expense expense) async {
    try {
      final userId = _userId;

      // Generate ID if not present
      final id = expense.id ?? const Uuid().v4();
      final now = DateTime.now();

      final newExpense = expense.copyWith(
        id: id,
        userId: userId,
        createdAt: expense.createdAt ?? now,
        updatedAt: now,
      );

      // Insert to local database
      await _expenseDao.insertExpense(newExpense, userId);

      // Queue for sync
      final data = newExpense.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'expenses',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }

      return newExpense;
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<void> updateExpense(String id, Expense expense) async {
    try {
      final userId = _userId;

      // Update local database
      await _expenseDao.updateExpense(id, expense, userId);

      // Queue for sync
      final data = expense.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'expenses',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final userId = _userId;

      // Delete from local database
      await _expenseDao.deleteExpense(id, userId);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'expenses',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // ============================================================================
  // EXPENSE READ: Offline-first - return local data immediately
  // ============================================================================

  Future<Expense?> getExpenseById(String id) async {
    try {
      final userId = _userId;
      return await _expenseDao.getExpenseById(id, userId);
    } catch (e) {
      throw Exception('Failed to load expense: $e');
    }
  }

  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? query,
  }) async {
    try {
      final userId = _userId;
      return await _expenseDao.getExpenses(
        userId,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        query: query,
      );
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  // ============================================================================
  // ANALYTICS: Computed from local data
  // ============================================================================

  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      final userId = _userId;
      return await _expenseDao.getTotalForDateRange(userId, startDate, endDate);
    } catch (e) {
      throw Exception('Failed to calculate total expenses: $e');
    }
  }

  Future<double> getCurrentMonthTotal() async {
    try {
      final userId = _userId;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      return await _expenseDao.getTotalForDateRange(
          userId, startOfMonth, endOfMonth);
    } catch (e) {
      throw Exception('Failed to get current month total: $e');
    }
  }

  Future<double> getPreviousMonthTotal() async {
    try {
      final userId = _userId;
      return await _expenseDao.getPreviousMonthTotal(userId);
    } catch (e) {
      throw Exception('Failed to get previous month total: $e');
    }
  }

  Future<Map<String, double>> getCategoryBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _userId;
      return await _expenseDao.getCategoryBreakdown(userId, startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get category breakdown: $e');
    }
  }

  // ============================================================================
  // SYNC CONTROL: Manual trigger with cooldown
  // ============================================================================

  /// Trigger expense sync if needed (respects cooldown to avoid sync storm)
  Future<void> triggerExpenseSyncIfNeeded({bool force = false}) async {
    try {
      // Check cooldown unless forced
      if (!force && _lastSyncTrigger != null) {
        final secondsSinceLastSync =
            DateTime.now().difference(_lastSyncTrigger!).inSeconds;
        if (secondsSinceLastSync < _syncCooldownSeconds) {
          // Skip sync - still in cooldown period
          return;
        }
      }

      // Only sync if online
      if (!_connectivity.isOnline) {
        return;
      }

      // Update last sync trigger time
      _lastSyncTrigger = DateTime.now();

      // Trigger background sync
      _syncService.syncProductsInBackground();
    } catch (e) {
      // Log error but don't throw - sync failure shouldn't block UI
      print('Failed to trigger expense sync: $e');
    }
  }
}
