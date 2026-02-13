import 'package:uuid/uuid.dart';
import '../models/cashbox_transaction.dart';
import '../database/dao/cashbox_transaction_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class CashboxRepository {
  final CashboxTransactionDao _dao = CashboxTransactionDao();
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
  // WRITE: Save locally + queue for sync
  // ============================================================================

  Future<CashboxTransaction> createTransaction(
      CashboxTransaction transaction) async {
    try {
      final userId = _userId;

      // Generate ID if not present
      final id = transaction.id ?? const Uuid().v4();
      final now = DateTime.now();

      final newTransaction = transaction.copyWith(
        id: id,
        userId: userId,
        createdAt: transaction.createdAt ?? now,
        updatedAt: now,
      );

      // Insert to local database
      await _dao.insertTransaction(newTransaction, userId);

      // Queue for sync
      final data = newTransaction.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'cashbox_transactions',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }

      return newTransaction;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<void> updateTransaction(
      String id, CashboxTransaction transaction) async {
    try {
      final userId = _userId;

      // Update local database
      await _dao.updateTransaction(id, transaction, userId);

      // Queue for sync
      final data = transaction.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'cashbox_transactions',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final userId = _userId;

      // Delete from local database
      await _dao.deleteTransaction(id, userId);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'cashbox_transactions',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // ============================================================================
  // READ: Offline-first - return local data immediately
  // ============================================================================

  Future<CashboxTransaction?> getTransactionById(String id) async {
    try {
      final userId = _userId;
      return await _dao.getTransactionById(id, userId);
    } catch (e) {
      throw Exception('Failed to load transaction: $e');
    }
  }

  Future<List<CashboxTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? query,
  }) async {
    try {
      final userId = _userId;
      return await _dao.getTransactions(
        userId,
        startDate: startDate,
        endDate: endDate,
        type: type,
        query: query,
      );
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  // ============================================================================
  // SYNC CONTROL: Manual trigger with cooldown
  // ============================================================================

  /// Trigger cashbox sync if needed (respects cooldown to avoid sync storm)
  Future<void> triggerCashboxSyncIfNeeded({bool force = false}) async {
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
      print('Failed to trigger cashbox sync: $e');
    }
  }
}
