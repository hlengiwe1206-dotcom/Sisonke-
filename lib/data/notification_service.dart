import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to view notifications.',
      );
    }

    return user.id;
  }

  Stream<List<SisonkeNotification>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(
          primaryKey: ['id'],
        )
        .eq(
          'user_id',
          _userId,
        )
        .order(
          'created_at',
          ascending: false,
        )
        .map(
          (rows) => rows
              .map(
                SisonkeNotification.fromMap,
              )
              .toList(),
        );
  }

  Stream<int> watchUnreadCount() {
    return watchNotifications().map(
      (notifications) => notifications
          .where(
            (notification) =>
                !notification.isRead,
          )
          .length,
    );
  }

  Future<void> markAsRead(
    String notificationId,
  ) async {
    await _client
        .from('notifications')
        .update(
          {
            'read_at':
                DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          notificationId,
        )
        .eq(
          'user_id',
          _userId,
        );
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update(
          {
            'read_at':
                DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'user_id',
          _userId,
        )
        .isFilter(
          'read_at',
          null,
        );
  }
}
