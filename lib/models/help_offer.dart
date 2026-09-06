class HelpOffer {
  final String id;
  final String requestId;
  final String helperId;
  final String helperName;
  final String message;
  final String status;
  final DateTime createdAt;

  HelpOffer({
    required this.id,
    required this.requestId,
    required this.helperId,
    required this.helperName,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory HelpOffer.fromMap(Map<String, dynamic> map) {
    final helper = map['helper'] as Map<String, dynamic>?;
    return HelpOffer(
      id: map['id'].toString(),
      requestId: map['help_request_id'].toString(),
      helperId: map['helper_id'].toString(),
      helperName: helper?['first_name']?.toString() ?? 'Community member',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
