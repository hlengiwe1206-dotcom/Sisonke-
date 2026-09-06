class HelpRequest {
  final String id;
  final String requesterId;
  final String title;
  final String content;
  final String? category;
  final String status;
  final DateTime createdAt;
  final int offerCount;

  HelpRequest({
    required this.id,
    required this.requesterId,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.offerCount,
  });

  factory HelpRequest.fromMap(Map<String, dynamic> map) {
    return HelpRequest(
      id: map['id'].toString(),
      requesterId: map['requester_id'].toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category_name']?.toString(),
      status: map['status']?.toString() ?? 'open',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      offerCount: (map['offer_count'] as num?)?.toInt() ?? 0,
    );
  }
}
