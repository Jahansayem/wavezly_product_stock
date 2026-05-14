import 'package:sqflite/sqflite.dart';
import 'package:wavezly/config/database_config.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/services/customer_service.dart';

class ReportDateRange {
  const ReportDateRange({
    this.start,
    this.endExclusive,
  });

  final DateTime? start;
  final DateTime? endExclusive;
}

class BusinessReportSummary {
  const BusinessReportSummary({
    required this.cashSales,
    required this.customerDueReceived,
    required this.otherIncome,
    required this.cashPurchases,
    required this.supplierDuePaid,
    required this.otherExpense,
    required this.netBalance,
    required this.cashProfit,
    required this.dueProfit,
    required this.totalProfit,
    required this.supplierDue,
    required this.customerReceivable,
  });

  final double cashSales;
  final double customerDueReceived;
  final double otherIncome;
  final double cashPurchases;
  final double supplierDuePaid;
  final double otherExpense;
  final double netBalance;
  final double cashProfit;
  final double dueProfit;
  final double totalProfit;
  final double supplierDue;
  final double customerReceivable;

  static const empty = BusinessReportSummary(
    cashSales: 0,
    customerDueReceived: 0,
    otherIncome: 0,
    cashPurchases: 0,
    supplierDuePaid: 0,
    otherExpense: 0,
    netBalance: 0,
    cashProfit: 0,
    dueProfit: 0,
    totalProfit: 0,
    supplierDue: 0,
    customerReceivable: 0,
  );
}

class ReportsService {
  ReportsService({CustomerService? customerService})
      : _customerService = customerService ?? CustomerService();

  final CustomerService _customerService;

  Future<BusinessReportSummary> getBusinessSummary(
    ReportDateRange range,
  ) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return BusinessReportSummary.empty;
    }

    final db = DatabaseConfig.database;

    final sales = await _salesSummary(db, userId, range);
    final customerDueReceived =
        await _sumByDate(db, userId, range, _customerDueReceivedQuery);
    final otherIncome = await _sumByDate(db, userId, range, _cashInQuery);
    final otherExpense = await _sumByDate(db, userId, range, _expensesQuery);
    final purchases = await _purchaseSummary(db, userId, range);
    final customerSummary = await _safeCustomerSummary();

    final cashSales = sales['cashSales'] ?? 0;
    final cashPurchases = purchases['cashPurchases'] ?? 0;
    final supplierDue = purchases['supplierDue'] ?? 0;
    const supplierDuePaid = 0.0;
    final netBalance = cashSales +
        customerDueReceived +
        otherIncome -
        cashPurchases -
        supplierDuePaid -
        otherExpense;
    final cashProfit = sales['cashProfit'] ?? 0;
    final dueProfit = sales['dueProfit'] ?? 0;

    return BusinessReportSummary(
      cashSales: cashSales,
      customerDueReceived: customerDueReceived,
      otherIncome: otherIncome,
      cashPurchases: cashPurchases,
      supplierDuePaid: supplierDuePaid,
      otherExpense: otherExpense,
      netBalance: netBalance,
      cashProfit: cashProfit,
      dueProfit: dueProfit,
      totalProfit: cashProfit + dueProfit,
      supplierDue: supplierDue,
      customerReceivable: customerSummary['toReceive'] ?? 0,
    );
  }

  Future<Map<String, double>> _salesSummary(
    Database db,
    String userId,
    ReportDateRange range,
  ) async {
    final filter = _DateFilter(
      dateExpression: 'COALESCE(sale_date, created_at)',
      range: range,
    );
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE
            WHEN LOWER(COALESCE(payment_status, 'paid')) = 'paid'
              THEN COALESCE(cash_received, total_amount, 0)
            ELSE 0
          END
        ), 0) AS cash_sales,
        COALESCE(SUM(
          CASE
            WHEN LOWER(COALESCE(payment_status, 'paid')) = 'paid'
              THEN COALESCE(profit_margin, 0)
            ELSE 0
          END
        ), 0) AS cash_profit,
        COALESCE(SUM(
          CASE
            WHEN LOWER(COALESCE(payment_status, 'paid')) <> 'paid'
              THEN COALESCE(profit_margin, 0)
            ELSE 0
          END
        ), 0) AS due_profit
      FROM sales
      WHERE user_id = ? ${filter.sql}
    ''', [
      userId,
      ...filter.args,
    ]);
    final row = rows.first;
    return {
      'cashSales': _asDouble(row['cash_sales']),
      'cashProfit': _asDouble(row['cash_profit']),
      'dueProfit': _asDouble(row['due_profit']),
    };
  }

  Future<Map<String, double>> _purchaseSummary(
    Database db,
    String userId,
    ReportDateRange range,
  ) async {
    final filter = _DateFilter(
      dateExpression: 'purchase_date',
      range: range,
    );
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(
          CASE
            WHEN paid_amount IS NOT NULL AND paid_amount > 0 THEN paid_amount
            WHEN LOWER(COALESCE(payment_status, 'paid')) = 'paid'
              THEN COALESCE(total_amount, 0)
            ELSE 0
          END
        ), 0) AS cash_purchases,
        COALESCE(SUM(COALESCE(due_amount, 0)), 0) AS supplier_due
      FROM purchases
      WHERE user_id = ? ${filter.sql}
    ''', [
      userId,
      ...filter.args,
    ]);
    final row = rows.first;
    return {
      'cashPurchases': _asDouble(row['cash_purchases']),
      'supplierDue': _asDouble(row['supplier_due']),
    };
  }

  Future<double> _sumByDate(
    Database db,
    String userId,
    ReportDateRange range,
    _DateSumQuery query,
  ) async {
    final filter = _DateFilter(
      dateExpression: query.dateExpression,
      range: range,
    );
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(${query.amountExpression}), 0) AS total
      FROM ${query.tableName}
      WHERE user_id = ? ${query.extraWhere} ${filter.sql}
    ''', [
      userId,
      ...filter.args,
    ]);
    return _asDouble(rows.first['total']);
  }

  Future<Map<String, double>> _safeCustomerSummary() async {
    try {
      return await _customerService.getSummary();
    } catch (_) {
      return const {'toReceive': 0.0, 'toGive': 0.0, 'netTotal': 0.0};
    }
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _DateFilter {
  _DateFilter({
    required this.dateExpression,
    required this.range,
  });

  final String dateExpression;
  final ReportDateRange range;

  String get sql {
    final clauses = <String>[];
    if (range.start != null) {
      clauses.add('date($dateExpression) >= date(?)');
    }
    if (range.endExclusive != null) {
      clauses.add('date($dateExpression) < date(?)');
    }
    if (clauses.isEmpty) return '';
    return 'AND ${clauses.join(' AND ')}';
  }

  List<String> get args {
    final values = <String>[];
    if (range.start != null) {
      values.add(range.start!.toIso8601String());
    }
    if (range.endExclusive != null) {
      values.add(range.endExclusive!.toIso8601String());
    }
    return values;
  }
}

class _DateSumQuery {
  const _DateSumQuery({
    required this.tableName,
    required this.dateExpression,
    required this.amountExpression,
    this.extraWhere = '',
  });

  final String tableName;
  final String dateExpression;
  final String amountExpression;
  final String extraWhere;
}

const _customerDueReceivedQuery = _DateSumQuery(
  tableName: 'customer_transactions',
  dateExpression: 'COALESCE(transaction_date, created_at)',
  amountExpression: 'amount',
  extraWhere:
      "AND UPPER(COALESCE(transaction_type, '')) IN ('RECEIVED', 'TO_GIVE')",
);

const _cashInQuery = _DateSumQuery(
  tableName: 'cashbox_transactions',
  dateExpression: 'transaction_date',
  amountExpression: 'amount',
  extraWhere: "AND transaction_type = 'cash_in'",
);

const _expensesQuery = _DateSumQuery(
  tableName: 'expenses',
  dateExpression: 'expense_date',
  amountExpression: 'amount',
);
