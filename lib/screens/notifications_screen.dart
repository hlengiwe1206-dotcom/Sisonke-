import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: userId == null
          ? const Center(
              child: Text(
                'Please sign in to view notifications.',
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error loading notifications:\n\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notifications =
                    List<Map<String, dynamic>>.from(snapshot.data!);

                notifications.sort((a, b) {
                  final aDate = DateTime.tryParse(
                        a['created_at']?.toString() ?? '',
                      ) ??
                      DateTime(2000);

                  final bDate = DateTime.tryParse(
                        b['created_at']?.toString() ?? '',
                      ) ??
                      DateTime(2000);

                  return bDate.compareTo(aDate);
                });

                if (notifications.isEmpty) {
                  return const _EmptyNotifications();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    return _NotificationCard(
                      notification: notification,
                      onTap: () async {
                        final isUnread =
                            notification['read_at'] == null;

                        if (isUnread) {
                          await _markAsRead(
                            notification['id'].toString(),
                          );
                        }

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              notification['title']?.toString() ??
                                  'Notification',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Future<void> Function() onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['read_at'] == null;

    final notificationType =
        notification['type']?.toString() ?? '';

    return Card(
      elevation: isUnread ? 3 : 0,
      color: isUnread
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          child: Icon(
            _getNotificationIcon(notificationType),
          ),
        ),
        title: Text(
          notification['title']?.toString() ??
              'Notification',
          style: TextStyle(
            fontWeight: isUnread
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification['body']?.toString() ?? '',
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(notification['created_at']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          await onTap();
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'closing_soon':
        return Icons.timer_outlined;

      case 'closing_today':
        return Icons.warning_amber_rounded;

      case 'opportunity_match':
        return Icons.auto_awesome;

      case 'new_opportunity':
        return Icons.campaign_outlined;

      case 'saved_opportunity':
        return Icons.bookmark;

      case 'high_match':
        return Icons.star;

      default:
        return Icons.notifications;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      return '';
    }

    final parsedDate = DateTime.tryParse(
      date.toString(),
    );

    if (parsedDate == null) {
      return '';
    }

    final localDate = parsedDate.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Opportunity alerts and closing-date reminders '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
