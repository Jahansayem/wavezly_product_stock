import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../models/product.dart';
import '../../config/database_config.dart';
import 'base_dao.dart';

class ProductDao extends BaseDao<Product> {
  @override
  String get tableName => 'products';

  Database get _db => DatabaseConfig.database;

  // Broadcast stream controller for reactive product updates
  StreamController<List<Product>>? _productsController;
  String? _currentUserId;

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
    final map = toMap(product);
    map['id'] = product.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Notify stream listeners
    await notifyProductsChanged(userId);
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
}
