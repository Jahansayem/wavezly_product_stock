import 'package:wavezly/config/supabase_config.dart';
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

  DashboardSummary({
    required this.balance,
    required this.todaySales,
    required this.monthSales,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.duesGiven,
    required this.stockCount,
    this.lastBackupTime,
  });
}

class DashboardService {
  final _supabase = SupabaseConfig.client;
  final _productService = ProductService();
  final _customerService = CustomerService();

  Future<DashboardSummary> getSummary() async {
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

    return DashboardSummary(
      balance: balance,
      todaySales: todaySales,
      monthSales: monthSales,
      todayExpenses: todayExpenses,
      monthExpenses: monthExpenses,
      duesGiven: duesGiven,
      stockCount: stockCount,
      lastBackupTime: null,
    );
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
}
