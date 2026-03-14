import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/customer_transaction.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class CustomerTransactionDao extends BaseDao<CustomerTransaction> {
  @override
  String get tableName => 'customer_transactions';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive transaction updates (per customer)
  final Map<String, StreamController<List<CustomerTransaction>>>
      _transactionControllers = {};

  @override
  CustomerTransaction fromMap(Map<String, dynamic> map) {
    return CustomerTransaction.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(CustomerTransaction item) {
    final map = item.toMap();
    map['user_id'] = map['user_id']; // Ensure user_id is included
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    return map;
  }

  // Insert transaction
  Future<void> insertTransaction(
      CustomerTransaction transaction, String userId) async {
    print(
        '💾 [CustomerTransactionDao] insertTransaction START - customerId: ${transaction.customerId}, amount: ${transaction.amount}');

    final map = toMap(transaction);
    map['id'] = transaction.id;
    map['user_id'] = userId;
    map['customer_id'] = transaction.customerId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    // Keep both legacy and current column names populated locally.
    map['description'] = transaction.description;
    map['note'] = transaction.description;
    map['sale_id'] = transaction.saleId;
    map['reference_id'] = transaction.saleId;
    map['balance'] = transaction.balance ?? 0.0;
    map['transaction_date'] = transaction.createdAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    print(
        '💾 [CustomerTransactionDao] Inserting into SQLite table: $tableName');
    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(
        '✅ [CustomerTransactionDao] Insert successful for transaction ${transaction.id}');

    // Notify stream listeners for this customer
    if (transaction.customerId != null) {
      print('📢 [CustomerTransactionDao] Notifying stream listeners');
      await notifyTransactionsChanged(transaction.customerId!);
      print('✅ [CustomerTransactionDao] insertTransaction COMPLETE');
    }
  }

  // Update transaction
  Future<void> updateTransaction(
      String id, CustomerTransaction transaction, String userId) async {
    final map = toMap(transaction);
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['updated_at'] = DateTime.now().toIso8601String();

    // Keep both legacy and current column names populated locally.
    map['description'] = transaction.description;
    map['note'] = transaction.description;
    map['sale_id'] = transaction.saleId;
    map['reference_id'] = transaction.saleId;
    map['balance'] = transaction.balance ?? 0.0;
    map['transaction_date'] = transaction.createdAt?.toIso8601String() ??
        DateTime.now().toIso8601String();

    await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners for this customer
    if (transaction.customerId != null) {
      await notifyTransactionsChanged(transaction.customerId!);
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    // Get customerId before deleting
    final results = await _db.query(
      tableName,
      columns: ['customer_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners for this customer
    if (results.isNotEmpty) {
      final customerId = results.first['customer_id'] as String?;
      if (customerId != null) {
        await notifyTransactionsChanged(customerId);
      }
    }
  }

  // Get customer transactions (Stream for reactive UI)
  Stream<List<CustomerTransaction>> getCustomerTransactions(String customerId) {
    print(
        '🔍 CustomerTransactionDao.getCustomerTransactions called for customerId: $customerId');

    // Create broadcast controller if needed for this customer
    if (!_transactionControllers.containsKey(customerId)) {
      print(
          '✨ Creating new broadcast stream controller for customer $customerId');
      _transactionControllers[customerId] =
          StreamController<List<CustomerTransaction>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED for customer $customerId');
          _refreshTransactions(customerId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED for customer $customerId');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller for customer $customerId');
    }

    return _transactionControllers[customerId]!.stream;
  }

  // Refresh transactions stream with latest data from database
  Future<void> _refreshTransactions(String customerId) async {
    print('🔄 _refreshTransactions called for customerId: $customerId');

    final controller = _transactionControllers[customerId];
    if (controller == null) {
      print('⚠️ Controller is null for customer $customerId, cannot refresh');
      return;
    }

    if (controller.isClosed) {
      print('⚠️ Controller is closed for customer $customerId, cannot refresh');
      return;
    }

    try {
      print('📊 Querying transactions from database...');
      final transactions = await _queryTransactions(customerId);
      print('✅ Query successful: ${transactions.length} transactions found');
      controller.add(transactions);
      print('✅ Transactions added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshTransactions: $e');
      print('Stack trace: $stackTrace');
      controller.addError(e, stackTrace);
    }
  }

  // Notify listeners that transactions have changed for a customer
  Future<void> notifyTransactionsChanged(String customerId) async {
    await _refreshTransactions(customerId);
  }

  // Dispose stream controller for a specific customer
  void disposeCustomer(String customerId) {
    _transactionControllers[customerId]?.close();
    _transactionControllers.remove(customerId);
  }

  // Dispose all stream controllers
  void dispose() {
    for (var controller in _transactionControllers.values) {
      controller.close();
    }
    _transactionControllers.clear();
  }

  Future<List<CustomerTransaction>> _queryTransactions(
      String customerId) async {
    print('🔍 _queryTransactions executing for customerId: $customerId');

    try {
      final db = DatabaseConfig.database;
      print('✅ Database connection obtained');

      final results = await db.query(
        tableName,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      final transactions = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${transactions.length} CustomerTransaction objects');

      return transactions;
    } catch (e, stackTrace) {
      print('❌ ERROR in _queryTransactions: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get transaction by ID
  Future<CustomerTransaction?> getTransactionById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Mark as synced (override with correct signature)
  @override
  Future<void> markAsSynced(String id, Database db) async {
    await super.markAsSynced(id, db);
  }

  // Convenience method without database parameter
  Future<void> markTransactionAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  Future<void> updateTransactionBalance(String id, double balance) async {
    final results = await _db.query(
      tableName,
      columns: ['customer_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    await _db.update(
      tableName,
      {
        'balance': balance,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
        'last_synced_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final customerId = results.first['customer_id'] as String?;
      if (customerId != null) {
        await notifyTransactionsChanged(customerId);
      }
    }
  }

  // Get unsynced transactions
  Future<List<CustomerTransaction>> getUnsyncedTransactions(
      String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) => fromMap(map)).toList();
  }

  /// Calculate total due for a customer from local transactions
  /// Used to update customer.total_due after transaction changes
  Future<double> calculateTotalDue(String customerId) async {
    try {
      final results = await _db.rawQuery(
        '''
        SELECT
          SUM(CASE WHEN transaction_type = 'GIVEN' THEN amount ELSE 0 END) as total_given,
          SUM(CASE WHEN transaction_type = 'RECEIVED' THEN amount ELSE 0 END) as total_received
        FROM $tableName
        WHERE customer_id = ?
        ''',
        [customerId],
      );

      if (results.isEmpty) return 0.0;

      final row = results.first;
      final totalGiven = (row['total_given'] as num?)?.toDouble() ?? 0.0;
      final totalReceived = (row['total_received'] as num?)?.toDouble() ?? 0.0;

      // GIVEN increases balance (customer owes us)
      // RECEIVED decreases balance (we pay customer)
      final totalDue = totalGiven - totalReceived;

      print(
          '✅ [CustomerTransactionDao] Calculated total_due for $customerId: $totalDue (given: $totalGiven, received: $totalReceived)');
      return totalDue;
    } catch (e) {
      print('❌ [CustomerTransactionDao] Error calculating total_due: $e');
      rethrow;
    }
  }

  /// Get recent transactions with customer details (for history view)
  /// Returns transaction details joined with customer info, ordered by date DESC
  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 50}) async {
    try {
      final results = await _db.rawQuery(
        '''
        SELECT
          ct.id,
          ct.customer_id,
          c.name as customer_name,
          c.phone as customer_phone,
          ct.transaction_type,
          ct.amount,
          ct.transaction_date as created_at,
          ct.note
        FROM $tableName ct
        INNER JOIN customers c ON ct.customer_id = c.id
        ORDER BY ct.transaction_date DESC
        LIMIT ?
        ''',
        [limit],
      );

      print(
          '✅ [CustomerTransactionDao] Retrieved ${results.length} recent transactions');
      return results;
    } catch (e) {
      print('❌ [CustomerTransactionDao] Error getting recent transactions: $e');
      rethrow;
    }
  }
}
