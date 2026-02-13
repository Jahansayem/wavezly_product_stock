import 'package:uuid/uuid.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';
import '../models/buying_cart_item.dart';
import '../database/dao/purchase_dao.dart';
import '../database/dao/purchase_item_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class PurchaseRepository {
  final PurchaseDao _purchaseDao = PurchaseDao();
  final PurchaseItemDao _purchaseItemDao = PurchaseItemDao();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Sync cooldown management
  DateTime? _lastSyncTrigger;
  static const _syncCooldownSeconds = 30;

  String get _userId {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      print('❌ ERROR: No authenticated user in PurchaseRepository');
      throw Exception('No authenticated user. Please login first.');
    }
    return currentUser.id;
  }

  // ============================================================================
  // PURCHASE OPERATIONS: Offline-first
  // ============================================================================

  // READ: Offline-first - return local data immediately, sync in background
  Stream<List<Purchase>> getAllPurchases() {
    final userId = _userId;
    print('📖 [PurchaseRepository] getAllPurchases() called with userId: $userId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerPurchaseSyncIfNeeded();
    }

    // Return local data stream
    return _purchaseDao.getAllPurchases(userId);
  }

  // Get purchases by supplier
  Future<List<Purchase>> getPurchasesBySupplier(String supplierId) async {
    final userId = _userId;

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerPurchaseSyncIfNeeded();
    }

    return await _purchaseDao.getPurchasesBySupplier(userId, supplierId);
  }

  // Get purchase by ID
  Future<Purchase?> getPurchaseById(String purchaseId) async {
    return await _purchaseDao.getPurchaseById(purchaseId);
  }

  // WRITE: Process purchase - save locally + queue sync
  Future<String> processPurchase({
    required Purchase purchase,
    required List<BuyingCartItem> cartItems,
  }) async {
    try {
      final userId = _userId;

      // Generate IDs if not present
      purchase.id ??= const Uuid().v4();
      purchase.userId = userId;
      purchase.createdAt ??= DateTime.now();
      purchase.updatedAt = DateTime.now();

      print('➕ [PurchaseRepository] processPurchase() START - purchaseId: ${purchase.id}, items: ${cartItems.length}');

      // Generate purchase number locally (format: P-YYYYMMDD-XXXXX)
      if (purchase.purchaseNumber == null || purchase.purchaseNumber!.isEmpty) {
        final timestamp = DateTime.now();
        final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
        final random = timestamp.millisecondsSinceEpoch % 100000;
        purchase.purchaseNumber = 'P-$dateStr-${random.toString().padLeft(5, '0')}';
      }

      // Insert purchase to local database
      print('💾 [PurchaseRepository] Inserting purchase to local SQLite');
      await _purchaseDao.insertPurchase(purchase, userId);

      // Convert cart items to purchase items
      final purchaseItems = cartItems.map((item) {
        return PurchaseItem.fromBuyingCartItem(item)
          ..id = const Uuid().v4()
          ..purchaseId = purchase.id
          ..createdAt = DateTime.now();
      }).toList();

      // Insert purchase items to local database
      print('💾 [PurchaseRepository] Inserting ${purchaseItems.length} purchase items');
      await _purchaseItemDao.insertPurchaseItems(purchaseItems);

      // Queue purchase for sync
      final purchaseData = purchase.toMap();
      purchaseData['user_id'] = userId;
      purchaseData['id'] = purchase.id;

      print('📤 [PurchaseRepository] Queuing purchase sync operation');
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'purchases',
        recordId: purchase.id!,
        data: purchaseData,
      );

      // Queue purchase items for sync
      for (var item in purchaseItems) {
        final itemData = item.toMap();
        itemData['id'] = item.id;
        itemData['purchase_id'] = item.purchaseId;

        await _syncService.queueOperation(
          operation: SyncConfig.operationInsert,
          tableName: 'purchase_items',
          recordId: item.id!,
          data: itemData,
        );
      }

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        print('🌐 [PurchaseRepository] Online - triggering immediate sync');
        _syncService.syncNow();
      } else {
        print('📴 [PurchaseRepository] Offline - sync queue will handle when online');
      }

      print('✅ [PurchaseRepository] processPurchase() COMPLETE for purchase ${purchase.id}');
      return purchase.id!;
    } catch (e) {
      print('❌ [PurchaseRepository] processPurchase() FAILED: $e');
      rethrow;
    }
  }

  // Update purchase
  Future<void> updatePurchase(String id, Purchase purchase) async {
    try {
      final userId = _userId;

      // Update local database
      await _purchaseDao.updatePurchase(id, purchase, userId);

      // Queue for sync
      final data = purchase.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'purchases',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error updating purchase: $e');
      rethrow;
    }
  }

  // Delete purchase
  Future<void> deletePurchase(String id) async {
    try {
      // Delete from local database (cascade will handle items)
      await _purchaseDao.deletePurchase(id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'purchases',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting purchase: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PURCHASE ITEM OPERATIONS: Offline-first
  // ============================================================================

  // Get purchase items stream (offline-first)
  Stream<List<PurchaseItem>> getPurchaseItems(String purchaseId) {
    print('📖 [PurchaseRepository] getPurchaseItems() called for purchaseId: $purchaseId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerPurchaseSyncIfNeeded();
    }

    // Return local data stream
    return _purchaseItemDao.getPurchaseItems(purchaseId);
  }

  // ============================================================================
  // SYNC CONTROL: Manual trigger with cooldown
  // ============================================================================

  /// Trigger purchase sync if needed (respects cooldown to avoid sync storm)
  Future<void> triggerPurchaseSyncIfNeeded({bool force = false}) async {
    try {
      // Check cooldown unless forced
      if (!force && _lastSyncTrigger != null) {
        final secondsSinceLastSync =
            DateTime.now().difference(_lastSyncTrigger!).inSeconds;
        if (secondsSinceLastSync < _syncCooldownSeconds) {
          // Skip sync - still in cooldown period
          print('⏳ [PurchaseRepository] Sync cooldown active, skipping sync');
          return;
        }
      }

      // Only sync if online
      if (!_connectivity.isOnline) {
        print('📴 [PurchaseRepository] Offline, skipping sync');
        return;
      }

      // Update last sync trigger time
      _lastSyncTrigger = DateTime.now();

      // Trigger background sync
      print('🔄 [PurchaseRepository] Triggering background sync');
      _syncService.syncProductsInBackground();
    } catch (e) {
      // Log error but don't throw - sync failure shouldn't block UI
      print('❌ [PurchaseRepository] Failed to trigger sync: $e');
    }
  }
}
