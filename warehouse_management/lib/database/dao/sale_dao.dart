import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/sale.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class SaleDao extends BaseDao<Sale> {
  @override
  String get tableName => 'sales';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive sale updates
  StreamController<List<Sale>>? _salesController;
  String? _currentUserId;

  @override
  Sale fromMap(Map<String, dynamic> map) {
    return Sale.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Sale item) {
    final map = item.toJson();
    map['user_id'] = map['user_id'];
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    return map;
  }

  // Insert sale
  Future<void> insertSale(Sale sale, String userId) async {
    print('💾 [SaleDao] insertSale START - userId: $userId, saleId: ${sale.id}');

    final map = toMap(sale);
    map['id'] = sale.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    print('💾 [SaleDao] Inserting into SQLite table: $tableName');
    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [SaleDao] Insert successful for sale ${sale.id}');

    // Notify stream listeners
    await notifySalesChanged(userId);
  }

  // Update sale
  Future<void> updateSale(String id, Sale sale, String userId) async {
    final map = toMap(sale);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners
    await notifySalesChanged(userId);
  }

  // Delete sale
  Future<void> deleteSale(String id) async {
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
        await notifySalesChanged(userId);
      }
    }
  }

  // Get all sales for user (Stream for reactive UI)
  Stream<List<Sale>> getAllSales(String userId) {
    print('🔍 SaleDao.getAllSales called for userId: $userId');

    // Reset controller if userId changes
    if (_currentUserId != userId) {
      print('🔄 Resetting stream controller (userId changed)');
      _salesController?.close();
      _salesController = null;
      _currentUserId = userId;
    }

    // Create broadcast controller if needed
    if (_salesController == null) {
      print('✨ Creating new broadcast stream controller');
      _salesController = StreamController<List<Sale>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired');
          _refreshSales(userId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller');
    }

    return _salesController!.stream;
  }

  // Refresh sales stream with latest data from database
  Future<void> _refreshSales(String userId) async {
    print('🔄 _refreshSales called for userId: $userId');

    if (_salesController == null || _salesController!.isClosed) {
      print('⚠️ Controller is null or closed, cannot refresh');
      return;
    }

    try {
      print('📊 Querying sales from database...');
      final sales = await _querySales(userId);
      print('✅ Query successful: ${sales.length} sales found');
      _salesController!.add(sales);
      print('✅ Sales added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshSales: $e');
      print('Stack trace: $stackTrace');
      _salesController!.addError(e, stackTrace);
    }
  }

  // Notify listeners that sales have changed
  Future<void> notifySalesChanged(String userId) async {
    await _refreshSales(userId);
  }

  // Dispose stream controller
  void dispose() {
    _salesController?.close();
    _salesController = null;
    _currentUserId = null;
  }

  Future<List<Sale>> _querySales(String userId) async {
    print('🔍 _querySales executing for userId: $userId');

    try {
      final db = DatabaseConfig.database;
      final results = await db.query(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      final sales = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${sales.length} Sale objects');

      return sales;
    } catch (e, stackTrace) {
      print('❌ ERROR in _querySales: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get sale by ID
  Future<Sale?> getSaleById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Get sales by customer
  Future<List<Sale>> getSalesByCustomer(String userId, String customerId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND customer_id = ?',
      whereArgs: [userId, customerId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Mark as synced
  @override
  Future<void> markAsSynced(String id, Database db) async {
    await super.markAsSynced(id, db);
  }

  // Convenience method without database parameter
  Future<void> markSaleAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced sales
  Future<List<Sale>> getUnsyncedSales(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) => fromMap(map)).toList();
  }
}
