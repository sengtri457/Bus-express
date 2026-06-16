class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.referenceType,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String? ?? 'general',
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'type': type,
    if (referenceType != null) 'reference_type': referenceType,
    if (referenceId != null) 'reference_id': referenceId,
    'is_read': isRead,
  };
}
