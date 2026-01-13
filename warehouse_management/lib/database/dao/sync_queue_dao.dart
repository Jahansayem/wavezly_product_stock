import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../config/database_config.dart';
import '../../config/sync_config.dart';

class SyncQueueDao {
  Database get _db => DatabaseConfig.database;

  // Add operation to queue
  Future<int> addToQueue({
    required String operation,
    required String tableName,
    required String recordId,
    Map<String, dynamic>? data,
  }) async {
    return await _db.insert('sync_queue', {
      'operation': operation,
      'table_name': tableName,
      'record_id': recordId,
      'data': data != null ? jsonEncode(data) : null,
      'created_at': DateTime.now().toIso8601String(),
      'status': SyncConfig.statusPending,
      'retry_count': 0,
    });
  }

  // Get pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations({int? limit}) async {
    return await _db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: [SyncConfig.statusPending],
      orderBy: 'created_at ASC',
      limit: limit ?? SyncConfig.batchSize,
    );
  }

  // Mark as processing
  Future<void> markAsProcessing(int id) async {
    await _db.update(
      'sync_queue',
      {'status': SyncConfig.statusProcessing},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark as completed
  Future<void> markAsCompleted(int id) async {
    await _db.update(
      'sync_queue',
      {'status': SyncConfig.statusCompleted},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark as failed
  Future<void> markAsFailed(int id, String error) async {
    await _db.rawUpdate(
      '''
      UPDATE sync_queue
      SET status = ?,
          last_error = ?,
          retry_count = retry_count + 1
      WHERE id = ?
      ''',
      [SyncConfig.statusFailed, error, id],
    );
  }

  // Reset failed to pending (for retry)
  Future<void> resetFailedToPending(int id) async {
    await _db.update(
      'sync_queue',
      {'status': SyncConfig.statusPending},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get failed operations
  Future<List<Map<String, dynamic>>> getFailedOperations() async {
    return await _db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: [SyncConfig.statusFailed],
      orderBy: 'created_at DESC',
    );
  }

  // Clear completed operations
  Future<void> clearCompleted() async {
    await _db.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: [SyncConfig.statusCompleted],
    );
  }

  // Get pending count
  Future<int> getPendingCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      [SyncConfig.statusPending],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get failed count
  Future<int> getFailedCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE status = ?',
      [SyncConfig.statusFailed],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Check if operation exists for record
  Future<bool> hasOperationForRecord(String tableName, String recordId) async {
    final result = await _db.query(
      'sync_queue',
      where: 'table_name = ? AND record_id = ? AND status = ?',
      whereArgs: [tableName, recordId, SyncConfig.statusPending],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Remove operation for record (used when server wins in conflict)
  Future<void> removeOperationsForRecord(String tableName, String recordId) async {
    await _db.delete(
      'sync_queue',
      where: 'table_name = ? AND record_id = ?',
      whereArgs: [tableName, recordId],
    );
  }

  // Get all operations (for debugging)
  Future<List<Map<String, dynamic>>> getAllOperations() async {
    return await _db.query(
      'sync_queue',
      orderBy: 'created_at DESC',
    );
  }

  // Clear all operations (for testing/debugging)
  Future<void> clearAll() async {
    await _db.delete('sync_queue');
  }
}
