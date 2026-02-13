import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/purchase.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class PurchaseDao extends BaseDao<Purchase> {
  @override
  String get tableName => 'purchases';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive purchase updates
  StreamController<List<Purchase>>? _purchasesController;
  String? _currentUserId;

  @override
  Purchase fromMap(Map<String, dynamic> map) {
    return Purchase.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Purchase item) {
    final map = item.toMap();
    map['user_id'] = map['user_id'];
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    // Map comment to notes for database
    if (map.containsKey('comment')) {
      map['notes'] = map['comment'];
      map.remove('comment');
    }
    return map;
  }

  // Insert purchase
  Future<void> insertPurchase(Purchase purchase, String userId) async {
    print('💾 [PurchaseDao] insertPurchase START - userId: $userId, purchaseId: ${purchase.id}');

    final map = toMap(purchase);
    map['id'] = purchase.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    print('💾 [PurchaseDao] Inserting into SQLite table: $tableName');
    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [PurchaseDao] Insert successful for purchase ${purchase.id}');

    // Notify stream listeners
    await notifyPurchasesChanged(userId);
  }

  // Update purchase
  Future<void> updatePurchase(String id, Purchase purchase, String userId) async {
    final map = toMap(purchase);
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
    await notifyPurchasesChanged(userId);
  }

  // Delete purchase
  Future<void> deletePurchase(String id) async {
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
        await notifyPurchasesChanged(userId);
      }
    }
  }

  // Get all purchases for user (Stream for reactive UI)
  Stream<List<Purchase>> getAllPurchases(String userId) {
    print('🔍 PurchaseDao.getAllPurchases called for userId: $userId');

    // Reset controller if userId changes
    if (_currentUserId != userId) {
      print('🔄 Resetting stream controller (userId changed)');
      _purchasesController?.close();
      _purchasesController = null;
      _currentUserId = userId;
    }

    // Create broadcast controller if needed
    if (_purchasesController == null) {
      print('✨ Creating new broadcast stream controller');
      _purchasesController = StreamController<List<Purchase>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired');
          _refreshPurchases(userId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller');
    }

    return _purchasesController!.stream;
  }

  // Refresh purchases stream with latest data from database
  Future<void> _refreshPurchases(String userId) async {
    print('🔄 _refreshPurchases called for userId: $userId');

    if (_purchasesController == null || _purchasesController!.isClosed) {
      print('⚠️ Controller is null or closed, cannot refresh');
      return;
    }

    try {
      print('📊 Querying purchases from database...');
      final purchases = await _queryPurchases(userId);
      print('✅ Query successful: ${purchases.length} purchases found');
      _purchasesController!.add(purchases);
      print('✅ Purchases added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshPurchases: $e');
      print('Stack trace: $stackTrace');
      _purchasesController!.addError(e, stackTrace);
    }
  }

  // Notify listeners that purchases have changed
  Future<void> notifyPurchasesChanged(String userId) async {
    await _refreshPurchases(userId);
  }

  // Dispose stream controller
  void dispose() {
    _purchasesController?.close();
    _purchasesController = null;
    _currentUserId = null;
  }

  Future<List<Purchase>> _queryPurchases(String userId) async {
    print('🔍 _queryPurchases executing for userId: $userId');

    try {
      final db = DatabaseConfig.database;
      final results = await db.query(
        tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'purchase_date DESC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      // Map notes to comment for model
      final purchases = results.map((map) {
        final modifiedMap = Map<String, dynamic>.from(map);
        if (modifiedMap.containsKey('notes')) {
          modifiedMap['comment'] = modifiedMap['notes'];
        }
        return fromMap(modifiedMap);
      }).toList();
      print('✅ Mapped to ${purchases.length} Purchase objects');

      return purchases;
    } catch (e, stackTrace) {
      print('❌ ERROR in _queryPurchases: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get purchase by ID
  Future<Purchase?> getPurchaseById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final map = Map<String, dynamic>.from(results.first);
    if (map.containsKey('notes')) {
      map['comment'] = map['notes'];
    }
    return fromMap(map);
  }

  // Get purchases by supplier
  Future<List<Purchase>> getPurchasesBySupplier(String userId, String supplierId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND supplier_id = ?',
      whereArgs: [userId, supplierId],
      orderBy: 'purchase_date DESC',
    );

    return results.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap.containsKey('notes')) {
        modifiedMap['comment'] = modifiedMap['notes'];
      }
      return fromMap(modifiedMap);
    }).toList();
  }

  // Mark as synced
  @override
  Future<void> markAsSynced(String id, Database db) async {
    await super.markAsSynced(id, db);
  }

  // Convenience method without database parameter
  Future<void> markPurchaseAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced purchases
  Future<List<Purchase>> getUnsyncedPurchases(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) {
      final modifiedMap = Map<String, dynamic>.from(map);
      if (modifiedMap.containsKey('notes')) {
        modifiedMap['comment'] = modifiedMap['notes'];
      }
      return fromMap(modifiedMap);
    }).toList();
  }
}
