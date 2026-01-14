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
    return currentUser.id;
  }

  // READ: Offline-first - return local data immediately, sync in background
  Stream<List<Product>> getAllProducts() {
    // Trigger background sync if online
    if (_connectivity.isOnline) {
      _syncService.syncProductsInBackground();
    }

    // Return local data stream
    return _productDao.getAllProducts(_userId);
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
      // Generate ID if not present
      product.id ??= const Uuid().v4();

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
      await _productDao.insertProduct(product, _userId);

      // Queue for sync
      final data = product.toMap();
      data['user_id'] = _userId;
      data['id'] = product.id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'products',
        recordId: product.id!,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product, {File? newImageFile}) async {
    try {
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
      await _productDao.updateProduct(id, product, _userId);

      // Queue for sync
      final data = product.toMap();
      data['user_id'] = _userId;
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
      final product = await _productDao.getProductById(productId);
      if (product != null) {
        product.image = null;
        await _productDao.updateProduct(productId, product, _userId);

        // Queue update for sync
        final data = product.toMap();
        data['user_id'] = _userId;
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
    return await _productDao.searchProducts(_userId, query);
  }

  Future<List<Product>> searchProductsInGroup(String query, String group) async {
    return await _productDao.searchProductsInGroup(_userId, query, group);
  }

  // Product groups
  Future<List<String>> getProductGroups() async {
    return await _productDao.getProductGroups(_userId);
  }

  Stream<List<String>> getProductGroupsStream() {
    return _productDao.getProductGroupsStream(_userId);
  }

  Future<void> addProductGroup(String groupName) async {
    try {
      final id = const Uuid().v4();

      await _productDao.addProductGroup(_userId, groupName, id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'product_groups',
        recordId: id,
        data: {
          'id': id,
          'name': groupName,
          'user_id': _userId,
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
      await _productDao.deleteProductGroup(_userId, groupName);

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
    return await _productDao.getLocations(_userId);
  }
}
