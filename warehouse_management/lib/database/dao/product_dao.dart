import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class ProductDao extends BaseDao<Product> {
  // Singleton pattern
  static final ProductDao _instance = ProductDao._internal();
  factory ProductDao() => _instance;
  ProductDao._internal();

  @override
  String get tableName => 'products';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive product updates (shared across all instances)
  StreamController<List<Product>>? _productsController;
  String? _currentUserId;
  bool _isRefreshing = false; // In-flight guard to prevent refresh storms

  @override
  Product fromMap(Map<String, dynamic> map) {
    return Product.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Product item) {
    final map = item.toMap();
    map['user_id'] = map['user_id']; // Ensure user_id is included
    map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();
    return map;
  }

  // Insert product
  Future<void> insertProduct(Product product, String userId) async {
    print('💾 [ProductDao] insertProduct START - userId: $userId, productId: ${product.id}, name: ${product.name}');

    final map = toMap(product);
    map['id'] = product.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    print('💾 [ProductDao] Inserting into SQLite table: $tableName');
    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ [ProductDao] Insert successful for product ${product.id}');

    // Notify stream listeners
    print('📢 [ProductDao] Notifying stream listeners');
    await notifyProductsChanged(userId);
    print('✅ [ProductDao] insertProduct COMPLETE');
  }

  // Update product
  Future<void> updateProduct(String id, Product product, String userId) async {
    final map = toMap(product);
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
    await notifyProductsChanged(userId);
  }

  // Update product quantity only (safer for partial stock edits)
  Future<void> updateProductQuantity(String id, int quantity, String userId) async {
    await _db.update(
      tableName,
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
        'last_synced_at': null,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    await notifyProductsChanged(userId);
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
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
        await notifyProductsChanged(userId);
      }
    }
  }

  // Get all products for user (Stream for reactive UI)
  Stream<List<Product>> getAllProducts(String userId) {
    print('🔍 ProductDao.getAllProducts called for userId: $userId');

    // Reset controller if userId changes (e.g., logout/login)
    if (_currentUserId != userId) {
      print('🔄 Resetting stream controller (userId changed)');
      _productsController?.close();
      _productsController = null;
      _currentUserId = userId;
      _isRefreshing = false;
    }

    // Create broadcast controller if needed
    if (_productsController == null) {
      print('✨ Creating new broadcast stream controller');
      _productsController = StreamController<List<Product>>.broadcast(
        onListen: () {
          print('👂 LISTENER ATTACHED - onListen fired');
          _refreshProducts(userId);
        },
        onCancel: () {
          print('❌ LISTENER CANCELLED');
        },
      );
    } else {
      print('♻️ Reusing existing stream controller');
      // CRITICAL FIX: Trigger refresh even when reusing controller
      // This ensures new listeners get current data immediately
      _refreshProducts(userId);
    }

    return _productsController!.stream;
  }

  // Refresh products stream with latest data from database
  Future<void> _refreshProducts(String userId) async {
    print('🔄 _refreshProducts called for userId: $userId');

    if (_productsController == null) {
      print('⚠️ Controller is null, cannot refresh');
      return;
    }

    if (_productsController!.isClosed) {
      print('⚠️ Controller is closed, cannot refresh');
      return;
    }

    // In-flight guard: prevent concurrent refreshes
    if (_isRefreshing) {
      print('⏭️ Refresh already in progress, skipping duplicate call');
      return;
    }

    _isRefreshing = true;

    try {
      print('📊 Querying products from database...');
      final products = await _queryProducts(userId);
      print('✅ Query successful: ${products.length} products found');
      _productsController!.add(products);
      print('✅ Products added to stream');
    } catch (e, stackTrace) {
      print('❌ ERROR in _refreshProducts: $e');
      print('Stack trace: $stackTrace');
      _productsController!.addError(e, stackTrace);
    } finally {
      _isRefreshing = false;
    }
  }

  // Notify listeners that products have changed (call after insert/update/delete)
  Future<void> notifyProductsChanged(String userId) async {
    await _refreshProducts(userId);
  }

  // Dispose stream controller (call when no longer needed)
  void dispose() {
    _productsController?.close();
    _productsController = null;
    _currentUserId = null;
    _isRefreshing = false;
  }

  Future<List<Product>> _queryProducts(String userId) async {
    print('🔍 _queryProducts executing for userId: $userId');

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
      final products = results.map((map) => fromMap(map)).toList();
      print('✅ Mapped to ${products.length} Product objects');

      return products;
    } catch (e, stackTrace) {
      print('❌ ERROR in _queryProducts: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get products by group
  Stream<List<Product>> getProductsByGroup(String userId, String group) {
    final controller = StreamController<List<Product>>();

    _queryProductsByGroup(userId, group).then((products) {
      if (!controller.isClosed) {
        controller.add(products);
      }
    });

    return controller.stream;
  }

  Future<List<Product>> _queryProductsByGroup(String userId, String group) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND product_group = ?',
      whereArgs: [userId, group],
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  // Search products
  Future<List<Product>> searchProducts(String userId, String query) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND name LIKE ?',
      whereArgs: [userId, '%$query%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Search products in group
  Future<List<Product>> searchProductsInGroup(
    String userId,
    String query,
    String group,
  ) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND product_group = ? AND name LIKE ?',
      whereArgs: [userId, group, '%$query%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String userId, String barcode) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND barcode = ?',
      whereArgs: [userId, barcode],
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
  Future<void> markProductAsSynced(String id) async {
    await markAsSynced(id, _db);
  }

  // Get unsynced products
  Future<List<Product>> getUnsyncedProducts(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) => fromMap(map)).toList();
  }

  // Get product groups
  Future<List<String>> getProductGroups(String userId) async {
    final results = await _db.query(
      'product_groups',
      columns: ['name'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return results.map((map) => map['name'] as String).toList();
  }

  // Get product groups stream
  Stream<List<String>> getProductGroupsStream(String userId) {
    final controller = StreamController<List<String>>();

    getProductGroups(userId).then((groups) {
      if (!controller.isClosed) {
        controller.add(groups);
      }
    });

    return controller.stream;
  }

  // Add product group
  Future<void> addProductGroup(String userId, String groupName, String id) async {
    await _db.insert(
      'product_groups',
      {
        'id': id,
        'name': groupName,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Delete product group
  Future<void> deleteProductGroup(String userId, String groupName) async {
    await _db.delete(
      'product_groups',
      where: 'user_id = ? AND name = ?',
      whereArgs: [userId, groupName],
    );
  }

  // Get locations
  Future<List<String>> getLocations(String userId) async {
    final results = await _db.query(
      'locations',
      columns: ['name'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return results.map((map) => map['name'] as String).toList();
  }

  /// Apply local stock deductions after sale completion
  /// Does NOT queue for sync - server already has correct stock
  /// Updates local cache to match server state immediately
  /// OVERSELL SUPPORT: Allows negative stock values
  Future<void> applyLocalStockDeductions(
    String userId,
    Map<String, int> deductions,
  ) async {
    if (deductions.isEmpty) return;

    try {
      await _db.transaction((txn) async {
        for (final entry in deductions.entries) {
          final productId = entry.key;
          final soldQty = entry.value;

          // Update quantity: COALESCE(quantity, 0) - soldQty
          // NO MAX CLAMP - allow negative stock for overselling
          // Keep is_synced = 1 (do not queue sync)
          await txn.rawUpdate(
            '''
            UPDATE $tableName
            SET quantity = COALESCE(quantity, 0) - ?,
                updated_at = ?
            WHERE id = ? AND user_id = ?
            ''',
            [
              soldQty,
              DateTime.now().toIso8601String(),
              productId,
              userId,
            ],
          );
        }
      });

      // Notify stream listeners to refresh UI
      await notifyProductsChanged(userId);
      print('✅ [ProductDao] Local stock deductions applied for ${deductions.length} products (oversell enabled)');
    } catch (e) {
      print('❌ [ProductDao] Error applying local stock deductions: $e');
      rethrow;
    }
  }

  /// Apply local stock increments after purchase completion
  /// Does NOT queue for sync - server already has correct stock
  /// Updates local cache to match server state immediately
  Future<void> applyLocalStockIncrements(
    String userId,
    Map<String, int> increments,
  ) async {
    if (increments.isEmpty) return;

    try {
      await _db.transaction((txn) async {
        for (final entry in increments.entries) {
          final productId = entry.key;
          final purchasedQty = entry.value;

          // Update quantity: COALESCE(quantity, 0) + purchasedQty
          // Keep is_synced unchanged (do not queue sync)
          await txn.rawUpdate(
            '''
            UPDATE $tableName
            SET quantity = COALESCE(quantity, 0) + ?,
                updated_at = ?
            WHERE id = ? AND user_id = ?
            ''',
            [
              purchasedQty,
              DateTime.now().toIso8601String(),
              productId,
              userId,
            ],
          );
        }
      });

      // Notify stream listeners to refresh UI
      await notifyProductsChanged(userId);
      print('✅ [ProductDao] Local stock increments applied for ${increments.length} products');
    } catch (e) {
      print('❌ [ProductDao] Error applying local stock increments: $e');
      rethrow;
    }
  }

  /// Get recent usage map for products (product_id -> last sale timestamp)
  /// Used for sorting products by recently sold in Sales Screen
  /// Returns map of product_id -> DateTime of most recent sale
  Future<Map<String, DateTime>> getProductRecentUsageMap(String userId) async {
    try {
      final results = await _db.rawQuery(
        '''
        SELECT
          si.product_id,
          MAX(s.created_at) as last_used_at
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        WHERE s.user_id = ?
          AND si.product_id IS NOT NULL
        GROUP BY si.product_id
        ''',
        [userId],
      );

      final Map<String, DateTime> usageMap = {};
      for (final row in results) {
        final productId = row['product_id'] as String?;
        final lastUsedAtStr = row['last_used_at'] as String?;

        if (productId != null && lastUsedAtStr != null) {
          try {
            usageMap[productId] = DateTime.parse(lastUsedAtStr);
          } catch (e) {
            print('⚠️ Failed to parse date for product $productId: $lastUsedAtStr');
          }
        }
      }

      print('✅ [ProductDao] Recent usage map built: ${usageMap.length} products with sales history');
      return usageMap;
    } catch (e) {
      print('❌ [ProductDao] Error building recent usage map: $e');
      return {};
    }
  }
}
