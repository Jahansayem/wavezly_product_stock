import 'package:sqflite/sqflite.dart';
import '../../models/expense_category.dart';
import '../../config/database_config.dart';

class ExpenseCategoryDao {
  Database get _db => DatabaseConfig.database;

  String get tableName => 'expense_categories';

  /// Insert expense category
  Future<void> insertCategory(ExpenseCategory category, String? userId) async {
    final map = _toMap(category);
    map['id'] = category.id;
    map['user_id'] = userId; // Can be null for system categories
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['created_at'] = category.createdAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update expense category
  Future<void> updateCategory(
      String id, ExpenseCategory category, String userId) async {
    final map = _toMap(category);
    map['is_synced'] = 0;
    map['last_synced_at'] = null;
    map['updated_at'] = DateTime.now().toIso8601String();

    await _db.update(
      tableName,
      map,
      where: 'id = ? AND user_id = ? AND is_system = 0',
      whereArgs: [id, userId],
    );
  }

  /// Delete expense category (only non-system categories)
  Future<void> deleteCategory(String id, String userId) async {
    await _db.delete(
      tableName,
      where: 'id = ? AND user_id = ? AND is_system = 0',
      whereArgs: [id, userId],
    );
  }

  /// Get category by ID
  Future<ExpenseCategory?> getCategoryById(String id) async {
    final results = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  /// Get all categories for user (both system and user-created)
  Future<List<ExpenseCategory>> getAllForUserAndSystem(String userId) async {
    final results = await _db.query(
      tableName,
      where: 'is_system = 1 OR user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_system DESC, name_bengali ASC',
    );

    return results.map((map) => _fromMap(map)).toList();
  }

  /// Upsert category from sync (mark as synced)
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

  /// Get unsynced categories for push
  Future<List<Map<String, dynamic>>> getUnsyncedCategories() async {
    final results = await _db.query(
      tableName,
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );

    return results;
  }

  /// Mark category as synced
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

  /// Convert ExpenseCategory to Map
  Map<String, dynamic> _toMap(ExpenseCategory category) {
    return {
      'name': category.name,
      'name_bengali': category.nameBengali,
      'description': category.description,
      'description_bengali': category.descriptionBengali,
      'icon_name': category.iconName,
      'icon_color': category.iconColor,
      'bg_color': category.bgColor,
      'is_system': category.isSystem ? 1 : 0,
    };
  }

  /// Convert Map to ExpenseCategory
  ExpenseCategory _fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String?,
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      nameBengali: map['name_bengali'] as String? ?? '',
      description: map['description'] as String?,
      descriptionBengali: map['description_bengali'] as String?,
      iconName: map['icon_name'] as String? ?? 'category',
      iconColor: map['icon_color'] as String? ?? 'blue600',
      bgColor: map['bg_color'] as String? ?? 'blue100',
      isSystem: (map['is_system'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
