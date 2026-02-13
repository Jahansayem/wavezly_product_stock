import 'package:sqflite/sqflite.dart';
import '../../models/expense.dart';
import '../../config/database_config.dart';

class ExpenseDao {
  Database get _db => DatabaseConfig.database;

  String get tableName => 'expenses';

  /// Insert expense
  Future<void> insertExpense(Expense expense, String userId) async {
    final map = _toMap(expense);
    map['id'] = expense.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['created_at'] = expense.createdAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update expense
  Future<void> updateExpense(String id, Expense expense, String userId) async {
    final map = _toMap(expense);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.update(
      tableName,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Delete expense
  Future<void> deleteExpense(String id, String userId) async {
    await _db.delete(
      tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Get expense by ID
  Future<Expense?> getExpenseById(String id, String userId) async {
    final results = await _db.query(
      tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  /// Get expenses with filters
  Future<List<Expense>> getExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? query,
  }) async {
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      whereClause += ' AND expense_date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      whereClause += ' AND expense_date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND description LIKE ?';
      whereArgs.add('%$query%');
    }

    final results = await _db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'expense_date DESC, created_at DESC',
    );

    return results.map((map) => _fromMap(map)).toList();
  }

  /// Get total expenses for date range
  Future<double> getTotalForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await _db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM $tableName
      WHERE user_id = ?
        AND expense_date >= ?
        AND expense_date <= ?
      ''',
      [
        userId,
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );

    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }

    final total = result.first['total'];
    return total is int ? total.toDouble() : (total as num).toDouble();
  }

  /// Get previous month total
  Future<double> getPreviousMonthTotal(String userId) async {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    return await getTotalForDateRange(userId, startOfLastMonth, endOfLastMonth);
  }

  /// Get category breakdown for date range
  Future<Map<String, double>> getCategoryBreakdown(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final results = await _db.rawQuery(
      '''
      SELECT category_id, SUM(amount) as total
      FROM $tableName
      WHERE user_id = ?
        AND expense_date >= ?
        AND expense_date <= ?
        AND category_id IS NOT NULL
      GROUP BY category_id
      ''',
      [
        userId,
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
    );

    final breakdown = <String, double>{};
    for (var row in results) {
      final categoryId = row['category_id'] as String;
      final total = row['total'];
      final totalDouble =
          total is int ? total.toDouble() : (total as num).toDouble();
      breakdown[categoryId] = totalDouble;
    }

    return breakdown;
  }

  /// Upsert expense from sync (mark as synced)
  Future<void> upsertFromSync(Map<String, dynamic> data) async {
    final map = Map<String, dynamic>.from(data);
    map['is_synced'] = 1;
    map['last_synced_at'] = DateTime.now().toIso8601String();

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get unsynced expenses for push
  Future<List<Map<String, dynamic>>> getUnsyncedExpenses() async {
    final results = await _db.query(
      tableName,
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );

    return results;
  }

  /// Mark expense as synced
  Future<void> markAsSynced(String id) async {
    await _db.update(
      tableName,
      {
        'is_synced': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Convert Expense to Map
  Map<String, dynamic> _toMap(Expense expense) {
    return {
      'category_id': expense.categoryId,
      'amount': expense.amount,
      'description': expense.description,
      'expense_date': expense.expenseDate.toIso8601String().split('T')[0],
    };
  }

  /// Convert Map to Expense
  Expense _fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      categoryId: map['category_id'] as String?,
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'] as String)
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
