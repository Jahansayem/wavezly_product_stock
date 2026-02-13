import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/purchase_item.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class PurchaseItemDao extends BaseDao<PurchaseItem> {
  @override
  String get tableName => 'purchase_items';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controllers for reactive purchase item updates (per purchase)
  final Map<String, StreamController<List<PurchaseItem>>> _itemControllers = {};

  @override
  PurchaseItem fromMap(Map<String, dynamic> map) {
    return PurchaseItem.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(PurchaseItem item) {
    final map = item.toMap();
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    return map;
  }

  // Insert purchase item
  Future<void> insertPurchaseItem(PurchaseItem item) async {
    print('💾 [PurchaseItemDao] insertPurchaseItem START - itemId: ${item.id}, purchaseId: ${item.purchaseId}');

    final map = toMap(item);
    map['id'] = item.id;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [PurchaseItemDao] Insert successful for item ${item.id}');

    // Notify stream listeners for this purchase
    if (item.purchaseId != null) {
      await notifyItemsChanged(item.purchaseId!);
    }
  }

  // Insert multiple purchase items in batch
  Future<void> insertPurchaseItems(List<PurchaseItem> items) async {
    if (items.isEmpty) return;

    final batch = _db.batch();
    for (var item in items) {
      final map = toMap(item);
      map['id'] = item.id;
      map['is_synced'] = 0;
      map['last_synced_at'] = null;

      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // Notify stream listeners for all affected purchases
    final purchaseIds = items.map((item) => item.purchaseId).where((id) => id != null).toSet();
    for (var purchaseId in purchaseIds) {
      await notifyItemsChanged(purchaseId!);
    }
  }

  // Update purchase item
  Future<void> updatePurchaseItem(String id, PurchaseItem item) async {
    final map = toMap(item);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify stream listeners
    if (item.purchaseId != null) {
      await notifyItemsChanged(item.purchaseId!);
    }
  }

  // Delete purchase item
  Future<void> deletePurchaseItem(String id) async {
    // Get purchaseId before deleting
    final results = await _db.query(
      tableName,
      columns: ['purchase_id'],
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
      final purchaseId = results.first['purchase_id'] as String?;
      if (purchaseId != null) {
        await notifyItemsChanged(purchaseId);
      }
    }
  }

  // Get purchase items for a specific purchase (Stream for reactive UI)
  Stream<List<PurchaseItem>> getPurchaseItems(String purchaseId) {
    print('🔍 PurchaseItemDao.getPurchaseItems called for purchaseId: $purchaseId');

    // Create controller if it doesn't exist
    if (!_itemControllers.containsKey(purchaseId)) {
      print('✨ Creating new broadcast stream controller for purchase $purchaseId');
      _itemControllers[purchaseId] = StreamController<List<PurchaseItem>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired for purchase $purchaseId');
          _refreshItems(purchaseId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED for purchase $purchaseId');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller for purchase $purchaseId');
    }

    return _itemControllers[purchaseId]!.stream;
  }

  // Refresh items stream with latest data from database
  Future<void> _refreshItems(String purchaseId) async {
    print('🔄 _refreshItems called for purchaseId: $purchaseId');

    final controller = _itemControllers[purchaseId];
    if (controller == null || controller.isClosed) {
      print('⚠️ Controller is null or closed, cannot refresh');
      return;
    }

    try {
      print('📊 Querying purchase items from database...');
      final items = await _queryPurchaseItems(purchaseId);
      print('✅ Query successful: ${items.length} items found');
      controller.add(items);
      print('✅ Items added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshItems: $e');
      print('Stack trace: $stackTrace');
      controller.addError(e, stackTrace);
    }
  }

  // Notify listeners that items have changed for a purchase
  Future<void> notifyItemsChanged(String purchaseId) async {
    await _refreshItems(purchaseId);
  }

  // Dispose specific stream controller
  void disposeController(String purchaseId) {
    _itemControllers[purchaseId]?.close();
    _itemControllers.remove(purchaseId);
  }

  // Dispose all stream controllers
  void dispose() {
    for (var controller in _itemControllers.values) {
      controller.close();
    }
    _itemControllers.clear();
  }

  Future<List<PurchaseItem>> _queryPurchaseItems(String purchaseId) async {
    print('🔍 _queryPurchaseItems executing for purchaseId: $purchaseId');

    try {
      final db = DatabaseConfig.database;
      final results = await db.query(
        tableName,
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
        orderBy: 'created_at ASC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      final items = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${items.length} PurchaseItem objects');

      return items;
    } catch (e, stackTrace) {
      print('❌ ERROR in _queryPurchaseItems: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get purchase item by ID
  Future<PurchaseItem?> getPurchaseItemById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Get all items for multiple purchases (for batch operations)
  Future<List<PurchaseItem>> getItemsByPurchaseIds(List<String> purchaseIds) async {
    if (purchaseIds.isEmpty) return [];

    final placeholders = List.filled(purchaseIds.length, '?').join(',');
    final results = await _db.query(
      tableName,
      where: 'purchase_id IN ($placeholders)',
      whereArgs: purchaseIds,
      orderBy: 'created_at ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Mark as synced
  @override
  Future<void> markAsSynced(String id, Database db) async {
    await super.markAsSynced(id, db);
  }

  // Convenience method without database parameter
  Future<void> markPurchaseItemAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced purchase items
  Future<List<PurchaseItem>> getUnsyncedPurchaseItems() async {
    final results = await _db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return results.map((map) => fromMap(map)).toList();
  }
}
