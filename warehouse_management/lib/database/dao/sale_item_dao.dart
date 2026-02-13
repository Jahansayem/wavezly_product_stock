import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/sale_item.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class SaleItemDao extends BaseDao<SaleItem> {
  @override
  String get tableName => 'sale_items';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controllers for reactive sale item updates (per sale)
  final Map<String, StreamController<List<SaleItem>>> _itemControllers = {};

  @override
  SaleItem fromMap(Map<String, dynamic> map) {
    return SaleItem.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(SaleItem item) {
    return {
      'id': item.id,
      'sale_id': item.saleId,
      'product_id': null, // Will be set by caller if needed
      'product_name': item.productName,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
      'subtotal': item.subtotal,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  // Insert sale item
  Future<void> insertSaleItem(SaleItem item) async {
    print('💾 [SaleItemDao] insertSaleItem START - itemId: ${item.id}, saleId: ${item.saleId}');

    final map = toMap(item);
    map['id'] = item.id;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [SaleItemDao] Insert successful for item ${item.id}');

    // Notify stream listeners for this sale
    if (item.saleId != null) {
      await notifyItemsChanged(item.saleId!);
    }
  }

  // Insert multiple sale items in batch
  Future<void> insertSaleItems(List<SaleItem> items) async {
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

    // Notify stream listeners for all affected sales
    final saleIds = items.map((item) => item.saleId).where((id) => id != null).toSet();
    for (var saleId in saleIds) {
      await notifyItemsChanged(saleId!);
    }
  }

  // Update sale item
  Future<void> updateSaleItem(String id, SaleItem item) async {
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
    if (item.saleId != null) {
      await notifyItemsChanged(item.saleId!);
    }
  }

  // Delete sale item
  Future<void> deleteSaleItem(String id) async {
    // Get saleId before deleting
    final results = await _db.query(
      tableName,
      columns: ['sale_id'],
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
      final saleId = results.first['sale_id'] as String?;
      if (saleId != null) {
        await notifyItemsChanged(saleId);
      }
    }
  }

  // Get sale items for a specific sale (Stream for reactive UI)
  Stream<List<SaleItem>> getSaleItems(String saleId) {
    print('🔍 SaleItemDao.getSaleItems called for saleId: $saleId');

    // Create controller if it doesn't exist
    if (!_itemControllers.containsKey(saleId)) {
      print('✨ Creating new broadcast stream controller for sale $saleId');
      _itemControllers[saleId] = StreamController<List<SaleItem>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired for sale $saleId');
          _refreshItems(saleId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED for sale $saleId');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller for sale $saleId');
    }

    return _itemControllers[saleId]!.stream;
  }

  // Refresh items stream with latest data from database
  Future<void> _refreshItems(String saleId) async {
    print('🔄 _refreshItems called for saleId: $saleId');

    final controller = _itemControllers[saleId];
    if (controller == null || controller.isClosed) {
      print('⚠️ Controller is null or closed, cannot refresh');
      return;
    }

    try {
      print('📊 Querying sale items from database...');
      final items = await _querySaleItems(saleId);
      print('✅ Query successful: ${items.length} items found');
      controller.add(items);
      print('✅ Items added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshItems: $e');
      print('Stack trace: $stackTrace');
      controller.addError(e, stackTrace);
    }
  }

  // Notify listeners that items have changed for a sale
  Future<void> notifyItemsChanged(String saleId) async {
    await _refreshItems(saleId);
  }

  // Dispose specific stream controller
  void disposeController(String saleId) {
    _itemControllers[saleId]?.close();
    _itemControllers.remove(saleId);
  }

  // Dispose all stream controllers
  void dispose() {
    for (var controller in _itemControllers.values) {
      controller.close();
    }
    _itemControllers.clear();
  }

  Future<List<SaleItem>> _querySaleItems(String saleId) async {
    print('🔍 _querySaleItems executing for saleId: $saleId');

    try {
      final db = DatabaseConfig.database;
      final results = await db.query(
        tableName,
        where: 'sale_id = ?',
        whereArgs: [saleId],
        orderBy: 'created_at ASC',
      );

      print('✅ Query executed: ${results.length} rows returned');
      final items = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${items.length} SaleItem objects');

      return items;
    } catch (e, stackTrace) {
      print('❌ ERROR in _querySaleItems: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get sale item by ID
  Future<SaleItem?> getSaleItemById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Get all items for multiple sales (for batch operations)
  Future<List<SaleItem>> getItemsBySaleIds(List<String> saleIds) async {
    if (saleIds.isEmpty) return [];

    final placeholders = List.filled(saleIds.length, '?').join(',');
    final results = await _db.query(
      tableName,
      where: 'sale_id IN ($placeholders)',
      whereArgs: saleIds,
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
  Future<void> markSaleItemAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced sale items
  Future<List<SaleItem>> getUnsyncedSaleItems() async {
    final results = await _db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return results.map((map) => fromMap(map)).toList();
  }
}
