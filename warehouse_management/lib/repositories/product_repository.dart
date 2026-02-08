import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../database/dao/product_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../services/image_storage_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class ProductRepository {
  final ProductDao _productDao = ProductDao();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();
  final ImageStorageService _imageService = ImageStorageService();

  String get _userId {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      print('❌ ERROR: No authenticated user in ProductRepository');
      throw Exception('No authenticated user. Please login first.');
    }
    print('🔑 [ProductRepository] _userId getter called: ${currentUser.id}');
    return currentUser.id;
  }

  // READ: Offline-first - return local data immediately, sync in background
  Stream<List<Product>> getAllProducts() {
    final userId = _userId;
    print('📖 [ProductRepository] getAllProducts() called with userId: $userId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      _syncService.syncProductsInBackground();
    }

    // Return local data stream
    return _productDao.getAllProducts(userId);
  }

  Stream<List<Product>> getProductsByGroup(String group) {
    if (_connectivity.isOnline) {
      _syncService.syncProductsInBackground();
    }

    return _productDao.getProductsByGroup(_userId, group);
  }

  // WRITE: Save locally + queue for sync
  Future<void> addProduct(Product product, {File? imageFile}) async {
    try {
      final userId = _userId;
      // Generate ID if not present
      product.id ??= const Uuid().v4();
      print('➕ [ProductRepository] addProduct() START - userId: $userId, productId: ${product.id}, name: ${product.name}');

      // Handle image upload
      if (imageFile != null) {
        if (await _connectivity.checkOnline()) {
          // Online: upload immediately
          try {
            product.image = await _imageService.uploadProductImage(imageFile);
          } catch (e) {
            print('Image upload failed, will retry later: $e');
            // Continue with product creation, image can be uploaded later
          }
        } else {
          // Offline: Store image path locally (could implement local image storage here)
          print('Offline: Image will be uploaded when online');
          // For now, skip image when offline
          product.image = null;
        }
      }

      // Insert to local database
      print('💾 [ProductRepository] Inserting to local SQLite with userId: $userId');
      await _productDao.insertProduct(product, userId);

      // Queue for sync
      final data = product.toMap();
      data['user_id'] = userId;
      data['id'] = product.id;
      data['product_group'] ??= '';  // Ensure not null for Supabase

      print('📤 [ProductRepository] Queuing sync operation for product ${product.id}');
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'products',
        recordId: product.id!,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        print('🌐 [ProductRepository] Online - attempting direct Supabase sync');
        try {
          await _directSupabaseInsert(product, userId);
          print('✅ [ProductRepository] Direct sync successful');
        } catch (e, stackTrace) {
          print('❌ [ProductRepository] Direct sync FAILED: $e');
          print('Stack trace: $stackTrace');
          print('📋 Sync queue will retry on next periodic sync');
        }
      } else {
        print('📴 [ProductRepository] Offline - sync queue will handle when online');
      }

      print('✅ [ProductRepository] addProduct() COMPLETE for product ${product.id}');
    } catch (e) {
      print('❌ [ProductRepository] addProduct() FAILED: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product, {File? newImageFile}) async {
    try {
      final userId = _userId;
      // Handle image replacement
      if (newImageFile != null && await _connectivity.checkOnline()) {
        try {
          final currentProduct = await _productDao.getProductById(id);
          final oldImageUrl = currentProduct?.image;

          final newImageUrl = await _imageService.replaceProductImage(
            newImageFile: newImageFile,
            oldImageUrl: oldImageUrl,
          );
          product.image = newImageUrl;
        } catch (e) {
          print('Image replacement failed: $e');
          // Continue with update
        }
      }

      // Update local database
      await _productDao.updateProduct(id, product, userId);

      // Queue for sync
      final data = product.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'products',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      // Get product image URL before deletion (for cleanup)
      final product = await _productDao.getProductById(id);
      final imageUrl = product?.image;

      // Delete from local database
      await _productDao.deleteProduct(id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'products',
        recordId: id,
      );

      // Delete image if exists (non-blocking)
      if (imageUrl != null && imageUrl.isNotEmpty && await _connectivity.checkOnline()) {
        _imageService.deleteProductImage(imageUrl).catchError((error) {
          print('Warning: Could not delete product image: $error');
        });
      }

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> deleteProductImage(String productId, String imageUrl) async {
    try {
      if (await _connectivity.checkOnline()) {
        await _imageService.deleteProductImage(imageUrl);
      }

      // Update product locally
      final userId = _userId;
      final product = await _productDao.getProductById(productId);
      if (product != null) {
        product.image = null;
        await _productDao.updateProduct(productId, product, userId);

        // Queue update for sync
        final data = product.toMap();
        data['user_id'] = userId;
        data['id'] = productId;
        data['image_url'] = null;

        await _syncService.queueOperation(
          operation: SyncConfig.operationUpdate,
          tableName: 'products',
          recordId: productId,
          data: data,
        );
      }

      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting product image: $e');
      rethrow;
    }
  }

  Future<Product?> getProductById(String id) async {
    return await _productDao.getProductById(id);
  }

  Future<List<Product>> searchProducts(String query) async {
    final userId = _userId;
    return await _productDao.searchProducts(userId, query);
  }

  Future<List<Product>> searchProductsInGroup(String query, String group) async {
    final userId = _userId;
    return await _productDao.searchProductsInGroup(userId, query, group);
  }

  // Product groups
  Future<List<String>> getProductGroups() async {
    final userId = _userId;
    return await _productDao.getProductGroups(userId);
  }

  Stream<List<String>> getProductGroupsStream() {
    final userId = _userId;
    return _productDao.getProductGroupsStream(userId);
  }

  Future<void> addProductGroup(String groupName) async {
    try {
      final userId = _userId;
      final id = const Uuid().v4();

      await _productDao.addProductGroup(userId, groupName, id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'product_groups',
        recordId: id,
        data: {
          'id': id,
          'name': groupName,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error adding product group: $e');
      rethrow;
    }
  }

  Future<void> deleteProductGroup(String groupName) async {
    try {
      final userId = _userId;
      await _productDao.deleteProductGroup(userId, groupName);

      // Note: We don't have the ID here, so we can't queue for sync properly
      // This is a limitation - ideally we'd fetch the ID first
      // For now, this will be synced on next full pull

      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting product group: $e');
      rethrow;
    }
  }

  // Locations
  Future<List<String>> getLocations() async {
    final userId = _userId;
    return await _productDao.getLocations(userId);
  }

  /// Validates and refreshes auth session before sync operations
  Future<bool> _ensureAuthSession() async {
    try {
      final session = SupabaseConfig.client.auth.currentSession;

      if (session == null) {
        print('❌ No auth session found');
        return false;
      }

      // Check if token is expired or expiring soon (within 5 minutes)
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final timeUntilExpiry = expiresAt - now;

        if (timeUntilExpiry <= 0) {
          print('❌ JWT token expired, refreshing...');
          await SupabaseConfig.client.auth.refreshSession();
          print('✅ Token refreshed successfully');
        } else if (timeUntilExpiry < 300) { // Less than 5 minutes
          print('⚠️ Token expiring soon, refreshing...');
          await SupabaseConfig.client.auth.refreshSession();
          print('✅ Token refreshed successfully');
        } else {
          print('✅ Auth session valid (expires in ${timeUntilExpiry}s)');
        }
      }

      return true;
    } catch (e) {
      print('❌ Error validating auth session: $e');
      return false;
    }
  }

  // BACKUP: Direct Supabase insert as fallback
  // This ensures products reach Supabase immediately even if sync queue fails
  Future<void> _directSupabaseInsert(Product product, String userId) async {
    // Validate auth session before attempting sync
    final hasValidSession = await _ensureAuthSession();
    if (!hasValidSession) {
      throw Exception('Cannot sync: No valid auth session');
    }
    final data = {
      'id': product.id,
      'name': product.name,
      'cost': product.cost,
      'product_group': product.group ?? '',
      'location': product.location,
      'company': product.company,
      'quantity': product.quantity,
      'image_url': product.image,
      'description': product.description,
      'barcode': product.barcode,
      'expiry_date': product.expiryDate?.toIso8601String().split('T')[0],
      'stock_alert_enabled': product.stockAlertEnabled,
      'min_stock_level': product.minStockLevel,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseConfig.client.from('products').insert(data);
  }
}
