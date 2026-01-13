import 'package:sqflite/sqflite.dart';

abstract class BaseDao<T> {
  String get tableName;

  // Abstract methods that must be implemented
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);

  // Common CRUD operations
  Future<void> insert(T item, Database db) async {
    final map = toMap(item);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(String id, T item, Database db) async {
    final map = toMap(item);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;

    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id, Database db) async {
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<T?> getById(String id, Database db) async {
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  Future<List<T>> getAll(Database db, {String? where, List<Object?>? whereArgs}) async {
    final results = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );

    return results.map((map) => fromMap(map)).toList();
  }

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

  Future<List<T>> getUnsynced(Database db) async {
    final results = await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return results.map((map) => fromMap(map)).toList();
  }
}
