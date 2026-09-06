class SisonkeMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  SisonkeMessage({required this.id, required this.conversationId, required this.senderId, required this.content, required this.createdAt});
  factory SisonkeMessage.fromMap(Map<String, dynamic> map) => SisonkeMessage(
    id: map['id'].toString(), conversationId: map['conversation_id'].toString(), senderId: map['sender_id'].toString(),
    content: map['content']?.toString() ?? '', createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now());
}
