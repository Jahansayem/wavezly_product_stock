import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:wavezly/services/local_notification_cache_service.dart';
import 'package:wavezly/models/local_notification.dart';

class NotificationService {
  static const String appId = '38885689-4f43-4d42-8c17-cbcd852fba07';
  static final LocalNotificationCacheService _cacheService =
      LocalNotificationCacheService();

  /// Initialize OneSignal (call in main.dart)
  /// Sets up listeners to capture and save notifications to local cache
  static Future<void> initialize() async {
    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);

    // Setup notification handlers to save to local cache
    _setupNotificationHandlers();
  }

  /// Setup listeners to capture notifications and save to local cache
  static void _setupNotificationHandlers() {
    // Handle notification received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _saveNotificationToCache(event.notification);
      // Allow the notification to display
      event.preventDefault();
    });

    // Handle notification opened/clicked
    OneSignal.Notifications.addClickListener((event) {
      _saveNotificationToCache(event.notification);
    });
  }

  /// Save OneSignal notification to local cache
  static Future<void> _saveNotificationToCache(OSNotification notification) async {
    try {
      final localNotification = LocalNotification(
        notificationId: notification.notificationId,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        additionalData: notification.additionalData,
        receivedAt: DateTime.now(),
        isRead: false,
      );

      await _cacheService.saveNotification(localNotification);
      print('Notification saved to local cache: ${notification.notificationId}');
    } catch (e) {
      print('Error saving notification to cache: $e');
    }
  }

  /// Set user's external ID for targeting (call after login)
  static Future<void> loginUser(String userId) async {
    await OneSignal.login(userId);
  }

  /// Remove user's external ID (call on logout)
  static Future<void> logoutUser() async {
    await OneSignal.logout();
  }

  /// Get current OneSignal player ID
  static Future<String?> getPlayerId() async {
    return OneSignal.User.pushSubscription.id;
  }
}
