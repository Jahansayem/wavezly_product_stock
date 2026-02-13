import 'package:sqflite/sqflite.dart';
import '../../models/cashbox_transaction.dart';
import '../../config/database_config.dart';

class CashboxTransactionDao {
  Database get _db => DatabaseConfig.database;

  String get tableName => 'cashbox_transactions';

  /// Insert cashbox transaction
  Future<void> insertTransaction(CashboxTransaction transaction, String userId) async {
    final map = _toMap(transaction);
    map['id'] = transaction.id;
    map['user_id'] = userId;
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['created_at'] = transaction.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update cashbox transaction
  Future<void> updateTransaction(String id, CashboxTransaction transaction, String userId) async {
    final map = _toMap(transaction);
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

  /// Delete cashbox transaction
  Future<void> deleteTransaction(String id, String userId) async {
    await _db.delete(
      tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Get transaction by ID
  Future<CashboxTransaction?> getTransactionById(String id, String userId) async {
    final results = await _db.query(
      tableName,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  /// Get transactions with filters
  Future<List<CashboxTransaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? query,
  }) async {
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null) {
      whereClause += ' AND transaction_date >= ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      whereClause += ' AND transaction_date <= ?';
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    if (type != null) {
      whereClause += ' AND transaction_type = ?';
      whereArgs.add(type.value);
    }

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND description LIKE ?';
      whereArgs.add('%$query%');
    }

    final results = await _db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return results.map((map) => _fromMap(map)).toList();
  }

  /// Get unsynced transactions
  Future<List<CashboxTransaction>> getUnsyncedTransactions(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'user_id = ? AND is_synced = ?',
      whereArgs: [userId, 0],
    );

    return results.map((map) => _fromMap(map)).toList();
  }

  /// Mark as synced
  Future<void> markAsSynced(String id, Database db) async {
    await db.update(
      tableName,
      {
        'is_synced': 1,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Convert CashboxTransaction to map for database
  Map<String, dynamic> _toMap(CashboxTransaction transaction) {
    return {
      if (transaction.id != null) 'id': transaction.id,
      'transaction_type': transaction.transactionType.value,
      'amount': transaction.amount,
      'description': transaction.description,
      if (transaction.category != null && transaction.category!.isNotEmpty)
        'category': transaction.category,
      'transaction_date': transaction.transactionDate.toIso8601String().split('T')[0],
    };
  }

  /// Convert database map to CashboxTransaction
  CashboxTransaction _fromMap(Map<String, dynamic> map) {
    return CashboxTransaction(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      transactionType: TransactionType.fromString(map['transaction_type'] as String),
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      category: map['category'] as String?,
      transactionDate: map['transaction_date'] != null
          ? DateTime.parse(map['transaction_date'] as String)
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
