import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/customer_transaction.dart';
import '../database/dao/customer_dao.dart';
import '../database/dao/customer_transaction_dao.dart';
import '../sync/sync_service.dart';
import '../sync/connectivity_service.dart';
import '../config/supabase_config.dart';
import '../config/sync_config.dart';

class CustomerRepository {
  final CustomerDao _customerDao = CustomerDao();
  final CustomerTransactionDao _transactionDao = CustomerTransactionDao();
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Sync cooldown management
  DateTime? _lastSyncTrigger;
  static const _syncCooldownSeconds = 30;

  String get _userId {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser == null) {
      print('❌ ERROR: No authenticated user in CustomerRepository');
      throw Exception('No authenticated user. Please login first.');
    }
    print('🔑 [CustomerRepository] _userId getter called: ${currentUser.id}');
    return currentUser.id;
  }

  // ============================================================================
  // CUSTOMER OPERATIONS: Offline-first
  // ============================================================================

  // READ: Offline-first - return local data immediately, sync in background
  Stream<List<Customer>> getAllCustomers() {
    final userId = _userId;
    print('📖 [CustomerRepository] getAllCustomers() called with userId: $userId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerCustomerSyncIfNeeded();
    }

    // Return local data stream
    return _customerDao.getAllCustomers(userId);
  }

  // Get customers with filtering
  Future<List<Customer>> getCustomersByFilter(String? filter) async {
    final userId = _userId;

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerCustomerSyncIfNeeded();
    }

    return await _customerDao.getCustomersByFilter(userId, filter);
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    final userId = _userId;

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerCustomerSyncIfNeeded();
    }

    return await _customerDao.searchCustomers(userId, query);
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    return await _customerDao.getCustomerById(customerId);
  }

  // WRITE: Save locally + queue for sync
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final userId = _userId;

      // Generate ID if not present
      customer.id ??= const Uuid().v4();
      print('➕ [CustomerRepository] createCustomer() START - userId: $userId, customerId: ${customer.id}, name: ${customer.name}');

      // Generate avatar color if not present
      if (customer.avatarColor == null && customer.name != null) {
        customer.avatarColor = _generateAvatarColor(customer.name!);
      }

      // Insert to local database
      print('💾 [CustomerRepository] Inserting to local SQLite with userId: $userId');
      await _customerDao.insertCustomer(customer, userId);

      // Queue for sync
      final data = customer.toMap();
      data['user_id'] = userId;
      data['id'] = customer.id;

      print('📤 [CustomerRepository] Queuing sync operation for customer ${customer.id}');
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'customers',
        recordId: customer.id!,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        print('🌐 [CustomerRepository] Online - triggering immediate sync');
        _syncService.syncNow();
      } else {
        print('📴 [CustomerRepository] Offline - sync queue will handle when online');
      }

      print('✅ [CustomerRepository] createCustomer() COMPLETE for customer ${customer.id}');
      return customer;
    } catch (e) {
      print('❌ [CustomerRepository] createCustomer() FAILED: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(String id, Customer customer) async {
    try {
      final userId = _userId;

      // Update local database
      await _customerDao.updateCustomer(id, customer, userId);

      // Queue for sync
      final data = customer.toMap();
      data['user_id'] = userId;
      data['id'] = id;

      await _syncService.queueOperation(
        operation: SyncConfig.operationUpdate,
        tableName: 'customers',
        recordId: id,
        data: data,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      // Delete from local database
      await _customerDao.deleteCustomer(id);

      // Queue for sync
      await _syncService.queueOperation(
        operation: SyncConfig.operationDelete,
        tableName: 'customers',
        recordId: id,
      );

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        _syncService.syncNow();
      }
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Get summary from local data (no remote call)
  Future<Map<String, double>> getSummary() async {
    try {
      final userId = _userId;
      final customers = await _customerDao.getCustomersByFilter(userId, null);

      double toReceive = 0.0;
      double toGive = 0.0;

      for (var customer in customers) {
        if (customer.totalDue > 0) {
          toReceive += customer.totalDue;
        } else {
          toGive += customer.totalDue.abs();
        }
      }

      return {
        'toReceive': toReceive,
        'toGive': toGive,
        'netTotal': toGive - toReceive, // Net amount to give
      };
    } catch (e) {
      print('Error getting customer summary: $e');
      rethrow;
    }
  }

  // ============================================================================
  // TRANSACTION OPERATIONS: Offline-first
  // ============================================================================

  /// Adds customer transaction using local-first approach
  /// Amount must ALWAYS be positive - transaction_type determines balance direction
  /// GIVEN = we gave to customer (increases their balance/our receivable)
  /// RECEIVED = customer paid us (decreases their balance/our receivable)
  Future<void> addTransaction(CustomerTransaction transaction) async {
    try {
      // Validate required fields
      if (transaction.customerId == null || transaction.customerId!.isEmpty) {
        throw Exception('Customer ID is required');
      }
      if (transaction.transactionType == null || transaction.transactionType!.isEmpty) {
        throw Exception('Transaction type is required');
      }
      if (transaction.amount == null || transaction.amount! <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      if (!['GIVEN', 'RECEIVED'].contains(transaction.transactionType)) {
        throw Exception('Invalid transaction type. Must be GIVEN or RECEIVED');
      }

      final userId = _userId;

      // Generate ID if not present
      transaction.id ??= const Uuid().v4();
      print('➕ [CustomerRepository] addTransaction() START - transactionId: ${transaction.id}, customerId: ${transaction.customerId}, type: ${transaction.transactionType}, amount: ${transaction.amount}');

      // Ensure amount is always positive
      final positiveAmount = transaction.amount!.abs();
      transaction.amount = positiveAmount;

      // Insert transaction to local database
      print('💾 [CustomerRepository] Inserting transaction to local SQLite');
      await _transactionDao.insertTransaction(transaction, userId);

      // Calculate new total_due from local transactions
      final newTotalDue = await _transactionDao.calculateTotalDue(transaction.customerId!);
      print('📊 [CustomerRepository] Calculated new total_due: $newTotalDue');

      // Update customer total_due locally
      await _customerDao.updateCustomerTotalDue(transaction.customerId!, newTotalDue, userId);

      // Queue transaction for sync
      final transactionData = transaction.toMap();
      transactionData['user_id'] = userId;
      transactionData['id'] = transaction.id;
      transactionData['note'] = transaction.description ?? '';
      transactionData['transaction_date'] = transaction.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String();

      print('📤 [CustomerRepository] Queuing transaction sync operation');
      await _syncService.queueOperation(
        operation: SyncConfig.operationInsert,
        tableName: 'customer_transactions',
        recordId: transaction.id!,
        data: transactionData,
      );

      // Queue customer update for sync (to sync total_due)
      // Note: Server trigger will recalculate total_due, this ensures local changes sync
      final customer = await _customerDao.getCustomerById(transaction.customerId!);
      if (customer != null) {
        final customerData = customer.toMap();
        customerData['user_id'] = userId;
        customerData['id'] = customer.id;

        print('📤 [CustomerRepository] Queuing customer update sync operation');
        await _syncService.queueOperation(
          operation: SyncConfig.operationUpdate,
          tableName: 'customers',
          recordId: customer.id!,
          data: customerData,
        );
      }

      // Trigger immediate sync if online
      if (await _connectivity.checkOnline()) {
        print('🌐 [CustomerRepository] Online - triggering immediate sync');
        _syncService.syncNow();
      } else {
        print('📴 [CustomerRepository] Offline - sync queue will handle when online');
      }

      print('✅ [CustomerRepository] addTransaction() COMPLETE');
    } catch (e) {
      print('❌ [CustomerRepository] addTransaction() FAILED: $e');
      rethrow;
    }
  }

  // Get customer transactions stream (offline-first)
  Stream<List<CustomerTransaction>> getCustomerTransactions(String customerId) {
    print('📖 [CustomerRepository] getCustomerTransactions() called for customerId: $customerId');

    // Trigger background sync if online
    if (_connectivity.isOnline) {
      triggerCustomerSyncIfNeeded();
    }

    // Return local data stream
    return _transactionDao.getCustomerTransactions(customerId);
  }

  // Get recent transactions with customer details (for history view)
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 50}) async {
    try {
      return await _transactionDao.getRecentTransactions(limit: limit);
    } catch (e) {
      print('❌ [CustomerRepository] Error getting recent transactions: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SYNC CONTROL: Manual trigger with cooldown
  // ============================================================================

  /// Trigger customer sync if needed (respects cooldown to avoid sync storm)
  Future<void> triggerCustomerSyncIfNeeded({bool force = false}) async {
    try {
      // Check cooldown unless forced
      if (!force && _lastSyncTrigger != null) {
        final secondsSinceLastSync =
            DateTime.now().difference(_lastSyncTrigger!).inSeconds;
        if (secondsSinceLastSync < _syncCooldownSeconds) {
          // Skip sync - still in cooldown period
          print('⏳ [CustomerRepository] Sync cooldown active, skipping sync');
          return;
        }
      }

      // Only sync if online
      if (!_connectivity.isOnline) {
        print('📴 [CustomerRepository] Offline, skipping sync');
        return;
      }

      // Update last sync trigger time
      _lastSyncTrigger = DateTime.now();

      // Trigger background sync
      print('🔄 [CustomerRepository] Triggering background sync');
      _syncService.syncProductsInBackground();
    } catch (e) {
      // Log error but don't throw - sync failure shouldn't block UI
      print('❌ [CustomerRepository] Failed to trigger sync: $e');
    }
  }

  // Generate avatar color from name
  String _generateAvatarColor(String name) {
    final colors = [
      '#3B82F6', // blue
      '#10B981', // green
      '#8B5CF6', // purple
      '#F59E0B', // amber
      '#EF4444', // red
      '#06B6D4', // cyan
      '#EC4899', // pink
      '#6366F1', // indigo
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}
