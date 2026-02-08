class Announcement {
  final String id;
  final String title;
  final String body;
  final String? targetRole;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? notificationId;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.targetRole,
    required this.createdBy,
    required this.createdAt,
    this.sentAt,
    this.notificationId,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    targetRole: json['target_role'] as String?,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
    notificationId: json['notification_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'target_role': targetRole,
    'created_by': createdBy,
  };
}
