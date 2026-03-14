import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/database_config.dart';
import '../config/supabase_config.dart';
import '../database/dao/cashbox_transaction_dao.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/customer_transaction_dao.dart';
import '../database/dao/expense_category_dao.dart';
import '../database/dao/expense_dao.dart';
import '../database/dao/product_dao.dart';
import '../database/dao/purchase_dao.dart';
import '../database/dao/purchase_item_dao.dart';
import '../database/dao/sale_dao.dart';
import '../database/dao/sale_item_dao.dart';
import '../database/dao/sync_queue_dao.dart';
import 'sync_service.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final ProductDao _productDao = ProductDao();
  final CustomerDao _customerDao = CustomerDao();
  final CustomerTransactionDao _transactionDao = CustomerTransactionDao();
  final SaleDao _saleDao = SaleDao();
  final SaleItemDao _saleItemDao = SaleItemDao();
  final PurchaseDao _purchaseDao = PurchaseDao();
  final PurchaseItemDao _purchaseItemDao = PurchaseItemDao();
  final ExpenseDao _expenseDao = ExpenseDao();
  final ExpenseCategoryDao _expenseCategoryDao = ExpenseCategoryDao();
  final CashboxTransactionDao _cashboxTransactionDao =
      CashboxTransactionDao();
  final SyncQueueDao _queueDao = SyncQueueDao();

  RealtimeChannel? _channel;
  String? _currentUserId;
  bool _isSubscribed = false;

  final Map<String, Set<String>> _tableColumns = {};

  bool get isSubscribed => _isSubscribed;

  void subscribe(String userId) {
    if (_isSubscribed && _currentUserId == userId) {
      print('[RealtimeService] Already subscribed for user $userId');
      return;
    }

    unsubscribe();

    _currentUserId = userId;
    final supabase = SupabaseConfig.client;

    _channel = supabase
        .channel('db-changes-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('products', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'customers',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('customers', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'customer_transactions',
          filter: _userFilter(userId),
          callback: (payload) =>
              unawaited(_handleChange('customer_transactions', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sales',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('sales', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sale_items',
          callback: (payload) => unawaited(_handleChange('sale_items', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'purchases',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('purchases', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'purchase_items',
          callback: (payload) =>
              unawaited(_handleChange('purchase_items', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('expenses', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_categories',
          callback: (payload) =>
              unawaited(_handleChange('expense_categories', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'cashbox_transactions',
          filter: _userFilter(userId),
          callback: (payload) =>
              unawaited(_handleChange('cashbox_transactions', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'product_groups',
          filter: _userFilter(userId),
          callback: (payload) =>
              unawaited(_handleChange('product_groups', payload)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'locations',
          filter: _userFilter(userId),
          callback: (payload) => unawaited(_handleChange('locations', payload)),
        );

    _channel!.subscribe((status, [error]) {
      print('[RealtimeService] Channel status: $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        _isSubscribed = true;
      } else if (status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.channelError) {
        _isSubscribed = false;
        if (error != null) {
          print('[RealtimeService] Channel error: $error');
        }
      }
    });
  }

  PostgresChangeFilter _userFilter(String userId) {
    return PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    );
  }

  Future<void> _handleChange(
    String tableName,
    PostgresChangePayload payload,
  ) async {
    try {
      if (!await _shouldProcessPayload(tableName, payload)) {
        return;
      }

      print('[RealtimeService] Received ${payload.eventType} on $tableName');

      if (payload.eventType == PostgresChangeEvent.delete) {
        await _handleDelete(tableName, payload.oldRecord);
      } else {
        await _handleUpsert(
          tableName,
          payload.newRecord,
          previousRecord: payload.oldRecord,
        );
      }
    } catch (e) {
      print('[RealtimeService] Error handling change on $tableName: $e');
    }
  }

  Future<bool> _shouldProcessPayload(
    String tableName,
    PostgresChangePayload payload,
  ) async {
    final record = payload.eventType == PostgresChangeEvent.delete
        ? payload.oldRecord
        : payload.newRecord;
    return _shouldProcessRecord(tableName, record);
  }

  Future<bool> _shouldProcessRecord(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final userId = _currentUserId;
    if (userId == null || record.isEmpty) {
      return false;
    }

    switch (tableName) {
      case 'expense_categories':
        return _parseBool(record['is_system']) || record['user_id'] == userId;
      case 'sale_items':
        final saleId = record['sale_id']?.toString();
        return saleId != null && await _parentBelongsToUser('sales', saleId);
      case 'purchase_items':
        final purchaseId = record['purchase_id']?.toString();
        return purchaseId != null &&
            await _parentBelongsToUser('purchases', purchaseId);
      default:
        return record['user_id'] == userId;
    }
  }

  Future<bool> _parentBelongsToUser(String tableName, String parentId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return false;
    }

    final db = DatabaseConfig.database;
    final rows = await db.query(
      tableName,
      columns: ['id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [parentId, userId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Future<void> _handleUpsert(
    String tableName,
    Map<String, dynamic> record, {
    Map<String, dynamic>? previousRecord,
  }) async {
    if (record.isEmpty) {
      return;
    }

    final recordId = record['id']?.toString();
    if (recordId == null) {
      return;
    }

    final db = DatabaseConfig.database;

    await _queueDao.removeOperationsForRecord(tableName, recordId);

    record['is_synced'] = 1;
    record['last_synced_at'] = DateTime.now().toIso8601String();

    final filtered = await _filterKnownColumns(tableName, record);
    final sanitized = _sanitizeForSqlite(filtered);

    await db.insert(
      tableName,
      sanitized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _notifyDao(
      tableName,
      record,
      previousRecord: previousRecord,
    );
  }

  Future<void> _handleDelete(
    String tableName,
    Map<String, dynamic> oldRecord,
  ) async {
    if (oldRecord.isEmpty) {
      return;
    }

    final recordId = oldRecord['id']?.toString();
    if (recordId == null) {
      return;
    }

    final db = DatabaseConfig.database;

    await _queueDao.removeOperationsForRecord(tableName, recordId);
    await db.delete(tableName, where: 'id = ?', whereArgs: [recordId]);

    await _notifyDao(tableName, oldRecord);
  }

  Future<void> _notifyDao(
    String tableName,
    Map<String, dynamic> record, {
    Map<String, dynamic>? previousRecord,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      return;
    }

    switch (tableName) {
      case 'products':
        await _productDao.notifyProductsChanged(userId);
        break;
      case 'customers':
        await _customerDao.notifyCustomersChanged(userId);
        break;
      case 'customer_transactions':
        final customerIds = <String>{
          if (record['customer_id'] != null) record['customer_id'].toString(),
          if (previousRecord?['customer_id'] != null)
            previousRecord!['customer_id'].toString(),
        };
        for (final customerId in customerIds) {
          await _transactionDao.notifyTransactionsChanged(customerId);
        }
        await _customerDao.notifyCustomersChanged(userId);
        break;
      case 'sales':
        await _saleDao.notifySalesChanged(userId);
        break;
      case 'sale_items':
        await _notifySaleItemChanges(record, previousRecord);
        break;
      case 'purchases':
        await _purchaseDao.notifyPurchasesChanged(userId);
        break;
      case 'purchase_items':
        await _notifyPurchaseItemChanges(record, previousRecord);
        break;
      case 'expenses':
        await _expenseDao.notifyChanged();
        break;
      case 'expense_categories':
        await _expenseCategoryDao.notifyChanged();
        break;
      case 'cashbox_transactions':
        await _cashboxTransactionDao.notifyChanged();
        break;
      case 'product_groups':
        await _productDao.notifyGroupsChanged(userId);
        break;
      case 'locations':
        break;
    }

    SyncService().notifyDashboardRefreshFromRealtime();
  }

  Future<void> _notifySaleItemChanges(
    Map<String, dynamic> record,
    Map<String, dynamic>? previousRecord,
  ) async {
    final saleIds = <String>{
      if (record['sale_id'] != null) record['sale_id'].toString(),
      if (previousRecord?['sale_id'] != null)
        previousRecord!['sale_id'].toString(),
    };

    for (final saleId in saleIds) {
      await _saleItemDao.notifyItemsChanged(saleId);
    }
  }

  Future<void> _notifyPurchaseItemChanges(
    Map<String, dynamic> record,
    Map<String, dynamic>? previousRecord,
  ) async {
    final purchaseIds = <String>{
      if (record['purchase_id'] != null) record['purchase_id'].toString(),
      if (previousRecord?['purchase_id'] != null)
        previousRecord!['purchase_id'].toString(),
    };

    for (final purchaseId in purchaseIds) {
      await _purchaseItemDao.notifyItemsChanged(purchaseId);
    }
  }

  Future<Map<String, dynamic>> _filterKnownColumns(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    if (!_tableColumns.containsKey(tableName)) {
      final db = DatabaseConfig.database;
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      _tableColumns[tableName] =
          columns.map((column) => column['name'] as String).toSet();
    }

    final knownColumns = _tableColumns[tableName]!;
    return Map.fromEntries(
      record.entries.where((entry) => knownColumns.contains(entry.key)),
    );
  }

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

  void unsubscribe() {
    if (_channel != null) {
      try {
        SupabaseConfig.client.removeChannel(_channel!);
      } catch (e) {
        print('[RealtimeService] Error removing channel: $e');
      }
      _channel = null;
    }

    _isSubscribed = false;
    _currentUserId = null;
  }
}
