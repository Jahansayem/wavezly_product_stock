import 'package:sqflite/sqflite.dart';
import 'package:wavezly/config/database_config.dart';
import 'package:wavezly/models/local_notification.dart';

/// Local-only notification cache service.
/// Stores OneSignal push notifications in SQLite (no Supabase dependency).
/// Retention: keeps only latest 200 notifications.
class LocalNotificationCacheService {
  static const int _maxNotifications = 200;

  /// Get all notifications ordered by received time (newest first)
  Future<List<LocalNotification>> getNotifications() async {
    try {
      final db = DatabaseConfig.database;
      final results = await db.query(
        'local_notifications',
        orderBy: 'received_at DESC',
        limit: _maxNotifications,
      );

      return results.map((row) => LocalNotification.fromMap(row)).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final db = DatabaseConfig.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM local_notifications WHERE is_read = 0',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Save a new notification (dedupe by notificationId)
  Future<void> saveNotification(LocalNotification notification) async {
    try {
      final db = DatabaseConfig.database;

      // Insert or replace (dedupe by notification_id)
      await db.insert(
        'local_notifications',
        notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cleanup: keep only latest 200 notifications
      await _cleanupOldNotifications(db);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final db = DatabaseConfig.database;
      await db.update(
        'local_notifications',
        {'is_read': 1},
        where: 'notification_id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final db = DatabaseConfig.database;
      await db.update(
        'local_notifications',
        {'is_read': 1},
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final db = DatabaseConfig.database;
      await db.delete(
        'local_notifications',
        where: 'notification_id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications (useful for testing/logout)
  Future<void> clearAll() async {
    try {
      final db = DatabaseConfig.database;
      await db.delete('local_notifications');
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  /// Cleanup old notifications, keeping only latest 200
  Future<void> _cleanupOldNotifications(Database db) async {
    try {
      // Get count of notifications
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM local_notifications',
      );
      final count = (countResult.first['count'] as int?) ?? 0;

      if (count > _maxNotifications) {
        // Delete oldest notifications beyond the limit
        await db.rawDelete('''
          DELETE FROM local_notifications
          WHERE notification_id IN (
            SELECT notification_id
            FROM local_notifications
            ORDER BY received_at DESC
            LIMIT -1 OFFSET ?
          )
        ''', [_maxNotifications]);
      }
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }
}
