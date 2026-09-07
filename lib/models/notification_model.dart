class SisonkeNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? relatedType;
  final String? relatedId;
  final DateTime? readAt;
  final DateTime createdAt;

  const SisonkeNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedType,
    this.relatedId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory SisonkeNotification.fromMap(
    Map<String, dynamic> map,
  ) {
    return SisonkeNotification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      title: map['title']?.toString() ?? 'Notification',
      body: map['body']?.toString() ?? '',
      relatedType: map['related_type']?.toString(),
      relatedId: map['related_id']?.toString(),
      readAt: map['read_at'] == null
          ? null
          : DateTime.tryParse(
              map['read_at'].toString(),
            ),
      createdAt:
          DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
