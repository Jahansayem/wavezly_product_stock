/// Local notification model for OneSignal push notifications.
/// Stored in SQLite for persistence across app restarts.
class LocalNotification {
  final String notificationId; // OneSignal notification ID (dedupe key)
  final String title;
  final String body;
  final Map<String, dynamic>? additionalData; // Custom data from OneSignal
  final DateTime receivedAt;
  final bool isRead;

  LocalNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    this.additionalData,
    required this.receivedAt,
    this.isRead = false,
  });

  /// Create from database row
  factory LocalNotification.fromMap(Map<String, dynamic> map) {
    return LocalNotification(
      notificationId: map['notification_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      additionalData: map['additional_data'] != null
          ? Map<String, dynamic>.from(map['additional_data'] as Map)
          : null,
      receivedAt: DateTime.parse(map['received_at'] as String),
      isRead: (map['is_read'] as int) == 1,
    );
  }

  /// Convert to database row
  Map<String, dynamic> toMap() {
    return {
      'notification_id': notificationId,
      'title': title,
      'body': body,
      'additional_data': additionalData,
      'received_at': receivedAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  /// Copy with updated fields
  LocalNotification copyWith({
    String? notificationId,
    String? title,
    String? body,
    Map<String, dynamic>? additionalData,
    DateTime? receivedAt,
    bool? isRead,
  }) {
    return LocalNotification(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      additionalData: additionalData ?? this.additionalData,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
