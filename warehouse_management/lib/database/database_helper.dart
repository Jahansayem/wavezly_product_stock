import 'package:sqflite/sqflite.dart';
import '../config/database_config.dart';

class DatabaseHelper {
  static Database get db => DatabaseConfig.database;

  // Query helpers
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Map<String, dynamic>?> querySingle(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final results = await query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Insert helpers
  static Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    return await db.insert(
      table,
      values,
      conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.abort,
    );
  }

  // Update helpers
  static Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Delete helpers
  static Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Raw query
  static Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return await db.rawQuery(sql, arguments);
  }

  // Transaction helpers
  static Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    return await db.transaction(action);
  }

  // Batch helpers
  static Batch batch() {
    return db.batch();
  }

  // User data cleanup
  static Future<void> clearUserData() async {
    await DatabaseConfig.clearUserData();
  }

  // Count helper
  static Future<int> count(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Check if record exists
  static Future<bool> exists(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final count = await DatabaseHelper.count(table, where: where, whereArgs: whereArgs);
    return count > 0;
  }
}
