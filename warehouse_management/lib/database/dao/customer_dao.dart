import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/customer.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class CustomerDao extends BaseDao<Customer> {
  @override
  String get tableName => 'customers';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive customer updates
  StreamController<List<Customer>>? _customersController;
  String? _currentUserId;

  @override
  Customer fromMap(Map<String, dynamic> map) {
    return Customer.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Customer item) {
    final map = item.toMap();
    map['user_id'] = map['user_id']; // Ensure user_id is included
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }

  // Insert customer
  Future<void> insertCustomer(Customer customer, String userId) async {
    print('💾 [CustomerDao] insertCustomer START - userId: $userId, customerId: ${customer.id}, name: ${customer.name}');

    final map = toMap(customer);
    map['id'] = customer.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    print('💾 [CustomerDao] Inserting into SQLite table: $tableName');
    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [CustomerDao] Insert successful for customer ${customer.id}');

    // Notify stream listeners
    print('📢 [CustomerDao] Notifying stream listeners');
    await notifyCustomersChanged(userId);
    print('✅ [CustomerDao] insertCustomer COMPLETE');
  }

  // Update customer
  Future<void> updateCustomer(String id, Customer customer, String userId) async {
    final map = toMap(customer);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners
    await notifyCustomersChanged(userId);
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    // Get userId before deleting
    final results = await _db.query(
      tableName,
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners
    if (results.isNotEmpty) {
      final userId = results.first['user_id'] as String?;
      if (userId != null) {
        await notifyCustomersChanged(userId);
      }
    }
  }

  // Get all customers for user (Stream for reactive UI)
  Stream<List<Customer>> getAllCustomers(String userId) {
    print('🔍 CustomerDao.getAllCustomers called for userId: $userId');

    // Reset controller if userId changes (e.g., logout/login)
    if (_currentUserId != userId) {
      print('🔄 Resetting stream controller (userId changed)');
      _customersController?.close();
      _customersController = null;
      _currentUserId = userId;
    }

    // Create broadcast controller if needed
    if (_customersController == null) {
      print('✨ Creating new broadcast stream controller');
      _customersController = StreamController<List<Customer>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired');
          _refreshCustomers(userId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller');
    }

    return _customersController!.stream;
  }

  // Refresh customers stream with latest data from database
  Future<void> _refreshCustomers(String userId) async {
    print('🔄 _refreshCustomers called for userId: $userId');

    if (_customersController == null) {
      print('⚠️ Controller is null, cannot refresh');
      return;
    }

    if (_customersController!.isClosed) {
      print('⚠️ Controller is closed, cannot refresh');
      return;
    }

    try {
      print('📊 Querying customers from database...');
      final customers = await _queryCustomers(userId);
      print('✅ Query successful: ${customers.length} customers found');
      _customersController!.add(customers);
      print('✅ Customers added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshCustomers: $e');
      print('Stack trace: $stackTrace');
      _customersController!.addError(e, stackTrace);
    }
  }

  // Notify listeners that customers have changed (call after insert/update/delete)
  Future<void> notifyCustomersChanged(String userId) async {
    await _refreshCustomers(userId);
  }

  // Dispose stream controller (call when no longer needed)
  void dispose() {
    _customersController?.close();
    _customersController = null;
    _currentUserId = null;
  }

  Future<List<Customer>> _queryCustomers(String userId) async {
    print('🔍 _queryCustomers executing for userId: $userId');

    try {
      final db = DatabaseConfig.database;
      print('✅ Database connection obtained');

      final results = await db.query(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name ASC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      final customers = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${customers.length} Customer objects');

      return customers;
    } catch (e, stackTrace) {
      print('❌ ERROR in _queryCustomers: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String userId, String query) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND (name LIKE ? OR phone LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Get customers by filter
  Future<List<Customer>> getCustomersByFilter(String userId, String? filter) async {
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (filter == 'receive') {
      whereClause += ' AND total_due > 0';
    } else if (filter == 'give') {
      whereClause += ' AND total_due < 0';
    }

    final results = await _db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Mark as synced (override with correct signature)
  @override
  Future<void> markAsSynced(String id, Database db) async {
    await super.markAsSynced(id, db);
  }

  // Convenience method without database parameter
  Future<void> markCustomerAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced customers
  Future<List<Customer>> getUnsyncedCustomers(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) => fromMap(map)).toList();
  }

  /// Update customer total_due locally (called after transaction changes)
  /// Does NOT queue for sync - server trigger handles total_due updates
  Future<void> updateCustomerTotalDue(String customerId, double newTotalDue, String userId) async {
    try {
      await _db.update(
        tableName,
        {
          'total_due': newTotalDue,
          'is_paid': newTotalDue == 0 ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
          // Keep is_synced as-is - server trigger will update total_due via sync
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [customerId, userId],
      );

      // Notify stream listeners to refresh UI
      await notifyCustomersChanged(userId);
      print('✅ [CustomerDao] Updated total_due for customer $customerId to $newTotalDue');
    } catch (e) {
      print('❌ [CustomerDao] Error updating customer total_due: $e');
      rethrow;
    }
  }
}
