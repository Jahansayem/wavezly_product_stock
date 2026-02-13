import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/cart_item.dart';
import '../database/dao/sale_dao.dart';
import '../database/dao/sale_item_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class SalesRepository {
  final SaleDao _saleDao = SaleDao();
  final SaleItemDao _saleItemDao = SaleItemDao();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Sync cooldown management
  DateTime? _lastSyncTrigger;
  static const _syncCooldownSeconds = 30;

  String get _userId {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      print('❌ ERROR: No authenticated user in SalesRepository');
      throw Exception('No authenticated user. Please login first.');
    }
    return currentUser.id;
  }

  // ============================================================================
  // SALE OPERATIONS: Offline-first
  // ============================================================================

  // READ: Offline-first - return local data immediately, sync in background
  Stream<List<Sale>> getAllSales() {
    final userId = _userId;
    print('📖 [SalesRepository] getAllSales() called with userId: $userId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerSaleSyncIfNeeded();
    }

    // Return local data stream
    return _saleDao.getAllSales(userId);
  }

  // Get sales by customer
  Future<List<Sale>> getSalesByCustomer(String customerId) async {
    final userId = _userId;

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerSaleSyncIfNeeded();
    }

    return await _saleDao.getSalesByCustomer(userId, customerId);
  }

  // Get sale by ID
  Future<Sale?> getSaleById(String saleId) async {
    return await _saleDao.getSaleById(saleId);
  }

  // WRITE: Process sale - save locally + queue sync
  Future<String> processSale(Sale sale, List<CartItem> cartItems) async {
    try {
      final userId = _userId;

      // Generate IDs if not present
      sale.id ??= const Uuid().v4();
      sale.userId = userId;
      sale.createdAt ??= DateTime.now();

      print('➕ [SalesRepository] processSale() START - saleId: ${sale.id}, items: ${cartItems.length}');

      // Generate sale number locally (format: S-YYYYMMDD-XXXXX)
      if (sale.saleNumber == null || sale.saleNumber!.isEmpty) {
        final timestamp = DateTime.now();
        final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
        final random = timestamp.millisecondsSinceEpoch % 100000;
        sale.saleNumber = 'S-$dateStr-${random.toString().padLeft(5, '0')}';
      }

      // Insert sale to local database
      print('💾 [SalesRepository] Inserting sale to local SQLite');
      await _saleDao.insertSale(sale, userId);

      // Convert cart items to sale items
      final saleItems = cartItems.map((item) {
        final itemJson = item.toSaleItemJson();
        return SaleItem(
          id: const Uuid().v4(),
          saleId: sale.id,
          productName: itemJson['product_name'] as String?,
          quantity: itemJson['quantity'] as int?,
          unitPrice: (itemJson['unit_price'] as num?)?.toDouble(),
          subtotal: (itemJson['subtotal'] as num?)?.toDouble(),
        );
      }).toList();

      // Insert sale items to local database
      print('💾 [SalesRepository] Inserting ${saleItems.length} sale items');
      await _saleItemDao.insertSaleItems(saleItems);

      // Queue sale for sync
      final saleData = sale.toJson();
      saleData['user_id'] = userId;
      saleData['id'] = sale.id;

      print('📤 [SalesRepository] Queuing sale sync operation');
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'sales',
        recordId: sale.id!,
        data: saleData,
      );

      // Queue sale items for sync
      for (var item in saleItems) {
        final itemData = {
          'id': item.id,
          'sale_id': item.saleId,
          'product_id': cartItems.firstWhere((ci) => ci.product.name == item.productName).product.id,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _syncService.queueOperation(
          operation: SyncConfig.operationInsert,
          tableName: 'sale_items',
          recordId: item.id!,
          data: itemData,
        );
      }

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        print('🌐 [SalesRepository] Online - triggering immediate sync');
        _syncService.syncNow();
      } else {
        print('📴 [SalesRepository] Offline - sync queue will handle when online');
      }

      print('✅ [SalesRepository] processSale() COMPLETE for sale ${sale.id}');
      return sale.id!;
    } catch (e) {
      print('❌ [SalesRepository] processSale() FAILED: $e');
      rethrow;
    }
  }

  // Process quick cash sale
  Future<String> processQuickCashSale({
    required double cashReceived,
    String? customerMobile,
    double? profitMargin,
    String? productDetails,
    bool receiptSmsEnabled = true,
    DateTime? saleDate,
    String? photoUrl,
  }) async {
    try {
      final userId = _userId;

      // Create sale object
      final sale = Sale(
        id: const Uuid().v4(),
        userId: userId,
        isQuickSale: true,
        cashReceived: cashReceived,
        totalAmount: cashReceived,
        subtotal: cashReceived,
        taxAmount: 0,
        customerPhone: customerMobile,
        profitMargin: profitMargin,
        productDetails: productDetails,
        receiptSmsSent: receiptSmsEnabled,
        saleDate: saleDate ?? DateTime.now(),
        photoUrl: photoUrl,
        paymentMethod: 'cash',
        paymentStatus: 'paid',
        customerName: 'Walk-in Customer',
        createdAt: DateTime.now(),
      );

      // Generate sale number
      final timestamp = DateTime.now();
      final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
      final random = timestamp.millisecondsSinceEpoch % 100000;
      sale.saleNumber = 'S-$dateStr-${random.toString().padLeft(5, '0')}';

      // Insert sale to local database
      await _saleDao.insertSale(sale, userId);

      // Queue for sync
      final saleData = sale.toJson();
      saleData['user_id'] = userId;

      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'sales',
        recordId: sale.id!,
        data: saleData,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }

      return sale.id!;
    } catch (e) {
      print('❌ [SalesRepository] processQuickCashSale() FAILED: $e');
      rethrow;
    }
  }

  // Update sale
  Future<void> updateSale(String id, Sale sale) async {
    try {
      final userId = _userId;

      // Update local database
      await _saleDao.updateSale(id, sale, userId);

      // Queue for sync
      final data = sale.toJson();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'sales',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error updating sale: $e');
      rethrow;
    }
  }

  // Delete sale
  Future<void> deleteSale(String id) async {
    try {
      // Delete from local database (cascade will handle items)
      await _saleDao.deleteSale(id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'sales',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting sale: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SALE ITEM OPERATIONS: Offline-first
  // ============================================================================

  // Get sale items stream (offline-first)
  Stream<List<SaleItem>> getSaleItems(String saleId) {
    print('📖 [SalesRepository] getSaleItems() called for saleId: $saleId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerSaleSyncIfNeeded();
    }

    // Return local data stream
    return _saleItemDao.getSaleItems(saleId);
  }

  // ============================================================================
  // SYNC CONTROL: Manual trigger with cooldown
  // ============================================================================

  /// Trigger sale sync if needed (respects cooldown to avoid sync storm)
  Future<void> triggerSaleSyncIfNeeded({bool force = false}) async {
    try {
      // Check cooldown unless forced
      if (!force && _lastSyncTrigger != null) {
        final secondsSinceLastSync =
            DateTime.now().difference(_lastSyncTrigger!).inSeconds;
        if (secondsSinceLastSync < _syncCooldownSeconds) {
          // Skip sync - still in cooldown period
          print('⏳ [SalesRepository] Sync cooldown active, skipping sync');
          return;
        }
      }

      // Only sync if online
      if (!_connectivity.isOnline) {
        print('📴 [SalesRepository] Offline, skipping sync');
        return;
      }

      // Update last sync trigger time
      _lastSyncTrigger = DateTime.now();

      // Trigger background sync
      print('🔄 [SalesRepository] Triggering background sync');
      _syncService.syncProductsInBackground();
    } catch (e) {
      // Log error but don't throw - sync failure shouldn't block UI
      print('❌ [SalesRepository] Failed to trigger sync: $e');
    }
  }
}
