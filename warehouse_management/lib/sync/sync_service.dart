import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/database_config.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';
import '../database/dao/sync_queue_dao.dart';
import '../database/dao/product_dao.dart';
import '../database/dao/customer_dao.dart';
import 'connectivity_service.dart';

class SyncResult {
  final bool success;
  final String? error;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    this.error,
    this.syncedCount = 0,
    this.failedCount = 0,
  });

  factory SyncResult.success({int syncedCount = 0}) => SyncResult(
        success: true,
        syncedCount: syncedCount,
      );

  factory SyncResult.offline() => SyncResult(
        success: false,
        error: 'Device is offline',
      );

  factory SyncResult.error(String error) => SyncResult(
        success: false,
        error: error,
      );
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SyncQueueDao _queueDao = SyncQueueDao();
  final ConnectivityService _connectivity = ConnectivityService();
  final ProductDao _productDao = ProductDao();
  final CustomerDao _customerDao = CustomerDao();
  SupabaseClient get _supabase => SupabaseConfig.client;

  Timer? _periodicTimer;
  bool _isSyncing = false;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Start periodic sync (every 5 minutes)
  void startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(milliseconds: SyncConfig.syncIntervalMilliseconds),
      (_) => syncAll(),
    );
    print(
        'Periodic sync started (every ${SyncConfig.syncIntervalMinutes} minutes)');
  }

  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    print('Periodic sync stopped');
  }

  // Main sync orchestration
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      print('Sync already in progress, skipping');
      return SyncResult.error('Sync already in progress');
    }

    if (!await _connectivity.checkOnline()) {
      print('Device offline, skipping sync');
      return SyncResult.offline();
    }

    final userId = _currentUserId;
    if (userId == null) {
      print('No authenticated user, skipping sync');
      return SyncResult.error('No authenticated user. Please login again.');
    }

    _isSyncing = true;
    int totalSynced = 0;
    int totalFailed = 0;

    try {
      print('Starting full sync...');

      // Step 1: PUSH - Upload queued local changes
      final pushResult = await _pushToServer(userId);
      totalSynced += pushResult.syncedCount;
      totalFailed += pushResult.failedCount;

      // Step 2: PULL - Fetch latest from server
      final pullResult = await _pullFromServer(userId);
      totalSynced += pullResult.syncedCount;

      print('Sync completed: $totalSynced synced, $totalFailed failed');
      return SyncResult(
        success: totalFailed == 0,
        syncedCount: totalSynced,
        failedCount: totalFailed,
      );
    } catch (e) {
      print('Sync failed: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // PUSH: Upload queued local changes
  Future<SyncResult> _pushToServer(String userId) async {
    try {
      int synced = 0;
      int failed = 0;

      while (true) {
        final queue = await _queueDao.getPendingOperations(userId: userId);
        if (queue.isEmpty) {
          if (synced == 0 && failed == 0) {
            print('No pending operations to push');
          }
          break;
        }

        print('Pushing ${queue.length} operations to server...');

        for (var operation in queue) {
          try {
            await _queueDao.markAsProcessing(operation['id']);
            await _processOperation(operation);
            await _queueDao.markAsCompleted(operation['id']);
            synced++;
          } catch (e) {
            print('Failed to sync operation ${operation['id']}: $e');
            await _queueDao.markAsFailed(operation['id'], e.toString());
            failed++;
          }
        }

        // Clear completed operations after each batch so the next batch can load.
        await _queueDao.clearCompleted(userId);
      }

      return SyncResult(
        success: failed == 0,
        syncedCount: synced,
        failedCount: failed,
      );
    } catch (e) {
      return SyncResult.error(e.toString());
    }
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final tableName = operation['table_name'] as String;
    final op = operation['operation'] as String;
    final recordId = operation['record_id'] as String;
    final data = operation['data'] != null
        ? Map<String, dynamic>.from(
            jsonDecode(operation['data'] as String) as Map,
          )
        : null;

    // Remove sync metadata fields before sending to Supabase
    if (data != null) {
      data.remove('is_synced');
      data.remove('last_synced_at');
      if (tableName == 'customer_transactions') {
        final normalizedData =
            await _normalizeCustomerTransactionData(data, recordId);
        data
          ..clear()
          ..addAll(normalizedData);
      }
    }

    final payload = data == null ? null : Map<String, dynamic>.from(data);

    switch (op) {
      case SyncConfig.operationInsert:
        try {
          print(
              '📤 SyncService: Inserting to $tableName - record_id: $recordId');
          if (payload == null) {
            throw Exception(
              'Missing sync payload for $tableName insert $recordId',
            );
          }
          await _supabase.from(tableName).insert(payload);
          print('✅ SyncService: Insert successful');
          await _markRecordAsSynced(tableName, recordId);
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('duplicate') ||
              errorStr.contains('unique') ||
              errorStr.contains('23505')) {
            print(
                'ℹ️ SyncService: $tableName/$recordId already exists - marking as synced');
            await _markRecordAsSynced(tableName, recordId);
          } else {
            print('❌ SyncService: Insert failed for $tableName/$recordId');
            print('Error details: $e');
            rethrow;
          }
        }
        break;

      case SyncConfig.operationUpdate:
        if (payload == null) {
          throw Exception(
            'Missing sync payload for $tableName update $recordId',
          );
        }
        await _supabase.from(tableName).update(payload).eq('id', recordId);
        await _markRecordAsSynced(tableName, recordId);
        break;

      case SyncConfig.operationDelete:
        await _supabase.from(tableName).delete().eq('id', recordId);
        break;
    }
  }

  Future<Map<String, dynamic>> _normalizeCustomerTransactionData(
    Map<String, dynamic> data,
    String recordId,
  ) async {
    final normalized = Map<String, dynamic>.from(data);
    final db = DatabaseConfig.database;
    final localRows = await db.query(
      'customer_transactions',
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    final localData = localRows.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(localRows.first);
    final now = DateTime.now().toIso8601String();

    final createdAt = _firstNonEmptyString([
          normalized['created_at'],
          localData['created_at'],
          normalized['transaction_date'],
          localData['transaction_date'],
        ]) ??
        now;
    final transactionDate = _firstNonEmptyString([
          normalized['transaction_date'],
          localData['transaction_date'],
          normalized['created_at'],
          localData['created_at'],
        ]) ??
        createdAt;
    final updatedAt = _firstNonEmptyString([
          normalized['updated_at'],
          localData['updated_at'],
        ]) ??
        now;
    final note = _firstNonEmptyString([
      normalized['note'],
      normalized['description'],
      localData['note'],
      localData['description'],
    ]);
    final referenceId = _firstNonEmptyString([
      normalized['reference_id'],
      normalized['sale_id'],
      localData['reference_id'],
      localData['sale_id'],
    ]);

    normalized['id'] = recordId;
    normalized['customer_id'] ??= localData['customer_id'];
    normalized['user_id'] ??= localData['user_id'];
    normalized['transaction_type'] ??= localData['transaction_type'];
    normalized['amount'] ??= localData['amount'];
    normalized['balance'] = _toDouble(normalized['balance']) ??
        _toDouble(localData['balance']) ??
        0.0;
    normalized['transaction_date'] = transactionDate;
    normalized['created_at'] = createdAt;
    normalized['updated_at'] = updatedAt;

    if (note == null) {
      normalized.remove('note');
    } else {
      normalized['note'] = note;
    }

    if (referenceId == null) {
      normalized.remove('reference_id');
    } else {
      normalized['reference_id'] = referenceId;
    }

    normalized.remove('description');
    normalized.remove('sale_id');

    return normalized;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  Future<void> _markRecordAsSynced(String tableName, String recordId) async {
    final db = DatabaseConfig.database;
    await db.update(
      tableName,
      {
        'is_synced': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // PULL: Fetch latest data from Supabase
  Future<SyncResult> _pullFromServer(String userId) async {
    try {
      print('Pulling latest data from server for user $userId...');
      int totalPulled = 0;

      // Pull each table
      for (var tableName in SyncConfig.syncTables) {
        final count = await _pullTable(tableName, userId);
        totalPulled += count;
      }

      // Notify DAOs to refresh streams after sync
      if (totalPulled > 0) {
        await _productDao.notifyProductsChanged(userId);
        await _customerDao.notifyCustomersChanged(userId);
        // Note: CustomerTransactionDao uses per-customer streams,
        // so we'd need to notify each customer separately.
        // For now, UI will refresh on next navigation to customer details.
        // Notify dashboard to refresh after data changes
        _notifyDashboardRefresh();
      }

      print('Pulled $totalPulled records from server');
      return SyncResult.success(syncedCount: totalPulled);
    } catch (e) {
      print('Pull failed: $e');
      return SyncResult.error(e.toString());
    }
  }

  Future<int> _pullTable(String tableName, String userId) async {
    try {
      // Get last sync timestamp for this table
      final lastSync = await _getLastSync(tableName);

      // Fetch records updated since last sync
      var query = _supabase.from(tableName).select();

      // Add user filter for user-specific tables
      // Special handling for child tables (sale_items, purchase_items) - scope by parent IDs
      if (tableName == 'sale_items') {
        // Fetch user's sales IDs from local database first
        final db = DatabaseConfig.database;
        final salesResults = await db.query(
          'sales',
          columns: ['id'],
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        final saleIds = salesResults.map((row) => row['id'] as String).toList();

        if (saleIds.isEmpty) {
          // No sales for user, skip sync
          return 0;
        }

        // Scope sale_items to user's sales IDs
        query = query.inFilter('sale_id', saleIds);
      } else if (tableName == 'purchase_items') {
        // Fetch user's purchases IDs from local database first
        final db = DatabaseConfig.database;
        final purchasesResults = await db.query(
          'purchases',
          columns: ['id'],
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        final purchaseIds =
            purchasesResults.map((row) => row['id'] as String).toList();

        if (purchaseIds.isEmpty) {
          // No purchases for user, skip sync
          return 0;
        }

        // Scope purchase_items to user's purchases IDs
        query = query.inFilter('purchase_id', purchaseIds);
      } else if (tableName == 'expense_categories') {
        // expense_categories: fetch system categories (user_id is null) and user's categories
        query = query.or('is_system.eq.true,user_id.eq.$userId');
      } else {
        // Default: filter by user_id
        query = query.eq('user_id', userId);
      }

      // Filter by updated_at if table has it (some tables don't have updated_at)
      final tablesWithoutUpdatedAt = [
        'product_groups',
        'locations',
        'sale_items',
        'purchase_items',
        'sales',
        'purchases',
        'customer_transactions'
      ];
      if (!tablesWithoutUpdatedAt.contains(tableName)) {
        if (lastSync != null) {
          query = query.gt('updated_at', lastSync);
        }
      }

      final data = await query;

      if (data.isEmpty) {
        return 0;
      }

      // Upsert into local database (server wins)
      final db = DatabaseConfig.database;
      final batch = db.batch();

      for (var record in data) {
        // Remove any pending sync operations for this record (server wins)
        await _queueDao.removeOperationsForRecord(tableName, record['id']);

        // Mark as synced
        record['is_synced'] = 1;
        record['last_synced_at'] = DateTime.now().toIso8601String();

        // Convert boolean values to integers for SQLite compatibility
        final sanitizedRecord = _sanitizeForSqlite(record);

        batch.insert(
          tableName,
          sanitizedRecord,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      // Update last sync timestamp
      await _updateLastSync(tableName, DateTime.now());

      return data.length;
    } catch (e) {
      print('Error pulling table $tableName: $e');
      return 0;
    }
  }

  Future<String?> _getLastSync(String tableName) async {
    final db = DatabaseConfig.database;
    final result = await db.query(
      'sync_metadata',
      columns: ['last_pull_at'],
      where: 'table_name = ?',
      whereArgs: [tableName],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['last_pull_at'] as String?;
  }

  // Convert boolean values to integers for SQLite compatibility
  Map<String, dynamic> _sanitizeForSqlite(Map<String, dynamic> record) {
    final sanitized = <String, dynamic>{};
    for (final entry in record.entries) {
      final value = entry.value;
      if (value is bool) {
        sanitized[entry.key] = value ? 1 : 0;
      } else {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  Future<void> _updateLastSync(String tableName, DateTime timestamp) async {
    final db = DatabaseConfig.database;
    await db.insert(
      'sync_metadata',
      {
        'table_name': tableName,
        'last_pull_at': timestamp.toIso8601String(),
        'last_sync_status': 'success',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Queue operation for sync
  Future<void> queueOperation({
    required String operation,
    required String tableName,
    required String recordId,
    Map<String, dynamic>? data,
  }) async {
    final userId = data?['user_id'] as String? ?? _currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user for sync queue.');
    }

    await _queueDao.addToQueue(
      userId: userId,
      operation: operation,
      tableName: tableName,
      recordId: recordId,
      data: data,
    );
  }

  // Trigger immediate sync
  Future<SyncResult> syncNow() async {
    return await syncAll();
  }

  // Trigger a full manual backup, including retrying previously failed items.
  Future<SyncResult> backupAllData() async {
    if (_isSyncing) {
      return SyncResult.error('Sync already in progress');
    }

    if (!await _connectivity.checkOnline()) {
      return SyncResult.offline();
    }

    final userId = _currentUserId;
    if (userId == null) {
      return SyncResult.error('No authenticated user. Please login again.');
    }

    final retriedCount = await _queueDao.resetAllFailedToPending(userId);
    if (retriedCount > 0) {
      print('Reset $retriedCount failed sync operations to pending');
    }

    return await syncAll();
  }

  // Sync specific table in background
  Future<void> syncProductsInBackground() async {
    // Lightweight trigger - actual sync happens in background
    if (_connectivity.isOnline && !_isSyncing) {
      Timer(Duration(seconds: 1), () => syncAll());
    }
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final userId = _currentUserId;
    final pendingCount =
        userId == null ? 0 : await _queueDao.getPendingCount(userId);
    final failedCount =
        userId == null ? 0 : await _queueDao.getFailedCount(userId);
    final legacyCount = await _queueDao.getLegacyQueueCount();

    return {
      'pending': pendingCount,
      'failed': failedCount,
      'legacy_pending': legacyCount,
      'is_online': _connectivity.isOnline,
      'is_syncing': _isSyncing,
    };
  }

  // Dashboard refresh notification
  final _dashboardRefreshController = StreamController<void>.broadcast();
  Stream<void> get onDashboardRefresh => _dashboardRefreshController.stream;

  void _notifyDashboardRefresh() {
    if (!_dashboardRefreshController.isClosed) {
      _dashboardRefreshController.add(null);
    }
  }

  /// Public wrapper for RealtimeService to trigger dashboard refresh.
  void notifyDashboardRefreshFromRealtime() {
    _notifyDashboardRefresh();
  }

  void dispose() {
    stopPeriodicSync();
    _dashboardRefreshController.close();
  }
}
