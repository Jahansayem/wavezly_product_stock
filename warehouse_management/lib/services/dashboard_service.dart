import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/config/database_config.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/services/expense_service.dart';

class DashboardSummary {
  final double balance;
  final double todaySales;
  final double monthSales;
  final double todayExpenses;
  final double monthExpenses;
  final double duesGiven;
  final int stockCount;
  final String? lastBackupTime;
  final String? shopName;

  DashboardSummary({
    required this.balance,
    required this.todaySales,
    required this.monthSales,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.duesGiven,
    required this.stockCount,
    this.lastBackupTime,
    this.shopName,
  });
}

class DashboardService {
  final _supabase = SupabaseConfig.client;
  final _productService = ProductService();
  final _customerService = CustomerService();

  /// Offline-first: returns local summary immediately, then refreshes from remote
  Future<DashboardSummary> getSummaryOfflineFirst() async {
    try {
      // Try local first
      final localSummary = await getSummaryLocal();

      // Save to persistent cache for future instant loads
      await _saveCachedSummary(localSummary);

      // Attempt remote refresh in background (don't wait)
      _refreshRemoteInBackground();

      return localSummary;
    } catch (e) {
      print('Local summary failed, falling back to remote: $e');
      // Fallback to remote if local fails
      return await getSummaryRemote();
    }
  }

  Future<void> _refreshRemoteInBackground() async {
    try {
      final remoteSummary = await getSummaryRemote();
      // Update persistent cache with latest remote data
      await _saveCachedSummary(remoteSummary);
    } catch (e) {
      print('Background remote refresh failed: $e');
      // Silent fail - local data still valid
    }
  }

  /// Get summary from local SQLite database (instant)
  Future<DashboardSummary> getSummaryLocal() async {
    final db = DatabaseConfig.database;
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return _emptySummary();
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Query 1: Today's sales (single aggregate query)
      final todaySalesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total
        FROM sales
        WHERE user_id = ?
        AND created_at >= ?
      ''', [userId, startOfDay.toIso8601String()]);
      final todaySales = (todaySalesResult.first['total'] as num).toDouble();

      // Query 2: Month's sales
      final monthSalesResult = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as total
        FROM sales
        WHERE user_id = ?
        AND created_at >= ?
      ''', [userId, startOfMonth.toIso8601String()]);
      final monthSales = (monthSalesResult.first['total'] as num).toDouble();

      // Query 3: Customer balance summary (to_receive - to_give)
      final customerBalanceResult = await db.rawQuery('''
        SELECT
          COALESCE(SUM(CASE WHEN transaction_type = 'to_receive' THEN amount ELSE 0 END), 0) as to_receive,
          COALESCE(SUM(CASE WHEN transaction_type = 'to_give' THEN amount ELSE 0 END), 0) as to_give
        FROM customer_transactions
        WHERE user_id = ?
      ''', [userId]);

      final toReceive = (customerBalanceResult.first['to_receive'] as num).toDouble();
      final toGive = (customerBalanceResult.first['to_give'] as num).toDouble();
      final balance = toReceive - toGive;

      // Query 4: Stock count
      final stockCountResult = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM products
        WHERE user_id = ?
      ''', [userId]);
      final stockCount = (stockCountResult.first['count'] as num).toInt();

      // Query 5: Shop name from app_settings
      final shopNameResult = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['shop_name'],
        limit: 1,
      );
      final shopName = shopNameResult.isNotEmpty
          ? shopNameResult.first['value'] as String?
          : null;

      // Note: Expenses are stored in separate 'expenses' table (Supabase only)
      // For local offline mode, expenses will be 0 until expenses table is synced locally
      // This is acceptable as sales/balance data is more critical for offline operation
      final todayExpenses = 0.0;
      final monthExpenses = 0.0;

      return DashboardSummary(
        balance: balance,
        todaySales: todaySales,
        monthSales: monthSales,
        todayExpenses: todayExpenses,
        monthExpenses: monthExpenses,
        duesGiven: toGive,
        stockCount: stockCount,
        shopName: shopName,
        lastBackupTime: null,
      );
    } catch (e) {
      print('Error getting local summary: $e');
      rethrow;
    }
  }

  /// Get summary from Supabase (remote, requires network)
  Future<DashboardSummary> getSummaryRemote() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return _emptySummary();
    }

    // Get shop name from user_business_profiles
    String? shopName;
    try {
      final businessProfile = await _supabase
          .from('user_business_profiles')
          .select('shop_name')
          .eq('user_id', userId)
          .maybeSingle();

      shopName = businessProfile?['shop_name'];

      // Cache shop name locally for offline access
      if (shopName != null) {
        await _cacheShopName(shopName);
      }
    } catch (e) {
      print('Failed to fetch shop name: $e');
      // Continue with null shopName if fetch fails
    }

    // Get customer summary (balance calculation)
    final customerSummary = await _customerService.getSummary();
    final balance = customerSummary['netTotal'] ?? 0.0;
    final duesGiven = customerSummary['toGive'] ?? 0.0;

    // Get stock count
    final products = await _productService.getProducts();
    final stockCount = products.length;

    // Get today's sales
    final todaySales = await _getTodaySales();

    // Get monthly sales
    final monthSales = await _getMonthSales();

    // Today's expenses (placeholder - can be expanded)
    final todayExpenses = await _getTodayExpenses();

    // Monthly expenses (placeholder - can be expanded)
    final monthExpenses = await _getMonthExpenses();

    final summary = DashboardSummary(
      balance: balance,
      todaySales: todaySales,
      monthSales: monthSales,
      todayExpenses: todayExpenses,
      monthExpenses: monthExpenses,
      duesGiven: duesGiven,
      stockCount: stockCount,
      lastBackupTime: null,
      shopName: shopName,
    );

    // Save to persistent cache for instant future loads
    await _saveCachedSummary(summary);

    return summary;
  }

  Future<double> _getTodaySales() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('sales')
          .select('total_amount')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      double total = 0.0;
      for (var sale in response as List) {
        total += (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getMonthSales() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final response = await _supabase
          .from('sales')
          .select('total_amount')
          .gte('created_at', startOfMonth.toIso8601String())
          .lt('created_at', endOfMonth.toIso8601String());

      double total = 0.0;
      for (var sale in response as List) {
        total += (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getTodayExpenses() async {
    try {
      final expenseService = ExpenseService();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return await expenseService.getTotalExpenses(startOfDay, endOfDay);
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getMonthExpenses() async {
    try {
      final expenseService = ExpenseService();
      return await expenseService.getCurrentMonthTotal();
    } catch (e) {
      return 0.0;
    }
  }

  /// Cache shop name in local database for offline access
  Future<void> _cacheShopName(String shopName) async {
    try {
      final db = DatabaseConfig.database;
      await db.insert(
        'app_settings',
        {'key': 'shop_name', 'value': shopName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Failed to cache shop name: $e');
    }
  }

  /// Get cached dashboard summary from persistent store (instant load)
  /// Returns null if no cache exists or cache is invalid
  Future<DashboardSummary?> getCachedSummary() async {
    try {
      final db = DatabaseConfig.database;
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['dashboard_cache'],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final cacheJson = result.first['value'] as String?;
      if (cacheJson == null) return null;

      final cacheData = json.decode(cacheJson) as Map<String, dynamic>;

      // Check if cache is older than 24 hours
      final cachedAt = DateTime.tryParse(cacheData['cachedAt'] ?? '');
      if (cachedAt != null) {
        final age = DateTime.now().difference(cachedAt);
        if (age.inHours > 24) {
          // Cache too old, return null
          return null;
        }
      }

      return DashboardSummary(
        balance: (cacheData['balance'] as num?)?.toDouble() ?? 0.0,
        todaySales: (cacheData['todaySales'] as num?)?.toDouble() ?? 0.0,
        monthSales: (cacheData['monthSales'] as num?)?.toDouble() ?? 0.0,
        todayExpenses: (cacheData['todayExpenses'] as num?)?.toDouble() ?? 0.0,
        monthExpenses: (cacheData['monthExpenses'] as num?)?.toDouble() ?? 0.0,
        duesGiven: (cacheData['duesGiven'] as num?)?.toDouble() ?? 0.0,
        stockCount: (cacheData['stockCount'] as num?)?.toInt() ?? 0,
        shopName: cacheData['shopName'] as String?,
        lastBackupTime: cacheData['lastBackupTime'] as String?,
      );
    } catch (e) {
      print('Failed to get cached summary: $e');
      return null;
    }
  }

  /// Save dashboard summary to persistent cache for instant future loads
  Future<void> _saveCachedSummary(DashboardSummary summary) async {
    try {
      final db = DatabaseConfig.database;
      final cacheData = {
        'balance': summary.balance,
        'todaySales': summary.todaySales,
        'monthSales': summary.monthSales,
        'todayExpenses': summary.todayExpenses,
        'monthExpenses': summary.monthExpenses,
        'duesGiven': summary.duesGiven,
        'stockCount': summary.stockCount,
        'shopName': summary.shopName,
        'lastBackupTime': summary.lastBackupTime,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await db.insert(
        'app_settings',
        {'key': 'dashboard_cache', 'value': json.encode(cacheData)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Failed to save cached summary: $e');
    }
  }

  /// Get summary - Compatibility wrapper (uses offline-first by default)
  Future<DashboardSummary> getSummary() async {
    return await getSummaryOfflineFirst();
  }

  /// Fast local-only summary: tries cache first, then local DB, never remote.
  /// Never throws - returns empty summary on error.
  /// Use for bootstrap/instant render scenarios.
  Future<DashboardSummary> getSummaryLocalOrCached() async {
    try {
      // Priority 1: Try persistent cache (instant)
      final cached = await getCachedSummary();
      if (cached != null) {
        return cached;
      }

      // Priority 2: Try local DB (fast, no network)
      final local = await getSummaryLocal();
      return local;
    } catch (e) {
      print('getSummaryLocalOrCached error: $e');
      // Never throw - return empty summary
      return _emptySummary();
    }
  }

  /// Return empty summary for unauthenticated state
  DashboardSummary _emptySummary() {
    return DashboardSummary(
      balance: 0.0,
      todaySales: 0.0,
      monthSales: 0.0,
      todayExpenses: 0.0,
      monthExpenses: 0.0,
      duesGiven: 0.0,
      stockCount: 0,
      shopName: null,
      lastBackupTime: null,
    );
  }
}
