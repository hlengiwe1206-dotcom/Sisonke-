import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? opportunityId;
  final String title;
  final String message;
  final String notificationType;
  final int? matchScore;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.opportunityId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.matchScore,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      opportunityId: map['opportunity_id']?.toString(),
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      notificationType:
          map['notification_type']?.toString() ?? 'opportunity',
      matchScore: _toInt(map['match_score']),
      isRead: map['is_read'] == true,
      createdAt: _toDate(map['created_at']) ?? DateTime.now(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // =========================================================
  // LIVE NOTIFICATION STREAM
  // =========================================================

  Stream<List<AppNotification>> watchNotifications() {
    final userId = currentUserId;

    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) => AppNotification.fromMap(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(),
        );
  }

  // =========================================================
  // GET NOTIFICATIONS
  // =========================================================

  Future<List<AppNotification>> getNotifications({
    int limit = 100,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      return [];
    }

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (row) => AppNotification.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  // =========================================================
  // UNREAD COUNT
  // =========================================================

  Future<int> getUnreadCount() async {
    final userId = currentUserId;

    if (userId == null) {
      return 0;
    }

    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // =========================================================
  // MARK ONE AS READ
  // =========================================================

  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;

    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
        })
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  // =========================================================
  // MARK ALL AS READ
  // =========================================================

  Future<void> markAllAsRead() async {
    final userId = currentUserId;

    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // =========================================================
  // DELETE NOTIFICATION
  // =========================================================

  Future<void> deleteNotification(String notificationId) async {
    final userId = currentUserId;

    if (userId == null) return;

    await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  // =========================================================
  // DELETE ALL READ NOTIFICATIONS
  // =========================================================

  Future<void> deleteReadNotifications() async {
    final userId = currentUserId;

    if (userId == null) return;

    await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .eq('is_read', true);
  }

  // =========================================================
  // GET THE RELATED OPPORTUNITY
  // =========================================================

  Future<Map<String, dynamic>?> getOpportunity(
    String opportunityId,
  ) async {
    try {
      final response = await _supabase
          .from('opportunities')
          .select()
          .eq('id', opportunityId)
          .maybeSingle();

      if (response == null) return null;

      return Map<String, dynamic>.from(response);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // MAIN ALERT SYNCHRONISATION ENGINE
  //
  // IMPORTANT:
  //
  // This does NOT recalculate your existing match scores.
  //
  // It receives the already-calculated scores from your
  // working Opportunities screen and uses them to decide
  // whether a notification should be generated.
  // =========================================================

  Future<void> syncOpportunityAlerts({
    required List<Map<String, dynamic>> opportunities,
    required Map<String, int> matchScores,
    int personalisedMatchThreshold = 60,
    int closingAlertDays = 7,
  }) async {
    final userId = currentUserId;

    if (userId == null) return;

    if (opportunities.isEmpty) return;

    final opportunityIds = opportunities
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (opportunityIds.isEmpty) return;

    // ---------------------------------------------------------
    // Load existing alerts first.
    //
    // This prevents unnecessary duplicate insert attempts.
    // ---------------------------------------------------------

    final existingResponse = await _supabase
        .from('notifications')
        .select(
          'opportunity_id, notification_type',
        )
        .eq('user_id', userId)
        .inFilter(
          'opportunity_id',
          opportunityIds,
        );

    final existingAlerts = <String>{};

    for (final row in existingResponse as List) {
      final map = Map<String, dynamic>.from(row);

      final opportunityId = map['opportunity_id']?.toString();
      final notificationType =
          map['notification_type']?.toString();

      if (opportunityId != null &&
          notificationType != null) {
        existingAlerts.add(
          '$opportunityId::$notificationType',
        );
      }
    }

    // ---------------------------------------------------------
    // PROCESS EACH OPPORTUNITY
    // ---------------------------------------------------------

    for (final opportunity in opportunities) {
      final opportunityId =
          opportunity['id']?.toString();

      if (opportunityId == null ||
          opportunityId.isEmpty) {
        continue;
      }

      final title =
          opportunity['title']?.toString() ??
              'New Opportunity';

      final closingDate = _parseDate(
        opportunity['closing_date'],
      );

      final matchScore =
          matchScores[opportunityId] ?? 0;

      // =======================================================
      // PERSONALISED MATCH ALERT
      // =======================================================

      if (matchScore >=
          personalisedMatchThreshold) {
        const notificationType =
            'personalised_match';

        final key =
            '$opportunityId::$notificationType';

        if (!existingAlerts.contains(key)) {
          await _createNotificationSafely(
            userId: userId,
            opportunityId: opportunityId,
            title:
                '✨ New $matchScore% Opportunity Match',
            message:
                '"$title" strongly matches your '
                'personalised opportunity preferences.',
            notificationType: notificationType,
            matchScore: matchScore,
          );

          existingAlerts.add(key);
        }
      }

      // =======================================================
      // CLOSING DATE ALERTS
      // =======================================================

      if (closingDate == null) {
        continue;
      }

      final daysRemaining =
          _daysUntil(closingDate);

      if (daysRemaining < 0) {
        continue;
      }

      if (daysRemaining >
          closingAlertDays) {
        continue;
      }

      final alertData =
          _closingAlertData(daysRemaining);

      if (alertData == null) {
        continue;
      }

      final notificationType =
          alertData['type']!;

      final key =
          '$opportunityId::$notificationType';

      if (!existingAlerts.contains(key)) {
        await _createNotificationSafely(
          userId: userId,
          opportunityId: opportunityId,
          title: alertData['title']!,
          message:
              '"$title" ${alertData['message']!}',
          notificationType: notificationType,
          matchScore: matchScore > 0
              ? matchScore
              : null,
        );

        existingAlerts.add(key);
      }
    }
  }

  // =========================================================
  // SAFE NOTIFICATION INSERT
  // =========================================================

  Future<void> _createNotificationSafely({
    required String userId,
    required String opportunityId,
    required String title,
    required String message,
    required String notificationType,
    int? matchScore,
  }) async {
    try {
      await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'opportunity_id': opportunityId,
            'title': title,
            'message': message,
            'notification_type':
                notificationType,
            'match_score': matchScore,
            'is_read': false,
          });
    } on PostgrestException catch (error) {
      // PostgreSQL duplicate key error.
      //
      // The unique index protects against race conditions
      // when multiple app refreshes happen simultaneously.
      if (error.code == '23505') {
        return;
      }

      rethrow;
    }
  }

  // =========================================================
  // CLOSING ALERT CONTENT
  // =========================================================

  Map<String, String>? _closingAlertData(
    int daysRemaining,
  ) {
    switch (daysRemaining) {
      case 0:
        return {
          'type': 'closing_today',
          'title': '🚨 Closing Today',
          'message':
              'closes today. Take action before the deadline.',
        };

      case 1:
        return {
          'type': 'closing_tomorrow',
          'title': '⚠️ Closing Tomorrow',
          'message':
              'closes tomorrow.',
        };

      case 2:
      case 3:
        return {
          'type': 'closing_soon',
          'title':
              '⏰ Closing in $daysRemaining Days',
          'message':
              'closes in $daysRemaining days.',
        };

      case 7:
        return {
          'type': 'closing_this_week',
          'title': '📅 Closing in 7 Days',
          'message':
              'closes in one week.',
        };

      default:
        return null;
    }
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value.toLocal();
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final closingDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return closingDay
        .difference(today)
        .inDays;
  }
}
