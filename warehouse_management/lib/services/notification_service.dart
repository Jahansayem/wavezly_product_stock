import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String appId = '38885689-4f43-4d42-8c17-cbcd852fba07';

  /// Initialize OneSignal (call in main.dart)
  static Future<void> initialize() async {
    OneSignal.initialize(appId);
    await OneSignal.Notifications.requestPermission(true);
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
