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
                        'Error loading notifications:\n${snapshot.error}',
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final notification = notifications[index];

                    final isUnread =
                        notification['read_at'] == null;

                    return Card(
                      elevation: isUnread ? 3 : 0,
                      color: isUnread
                          ? Colors.blue.shade50
                          : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            notificationIcon(
                              notification['type']?.toString(),
                            ),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              notification['body']?.toString() ?? '',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatNotificationDate(
                                notification['created_at'],
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: isUnread
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () async {
                          if (isUnread) {
                            await _markAsRead(
                              notification['id'].toString(),
                            );
                          }

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                notification['title']
                                        ?.toString() ??
                                    'Notification',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

IconData notificationIcon(String? type) {
  switch (type) {
    case 'closing_date':
    case 'deadline':
      return Icons.schedule;

    case 'opportunity_match':
    case 'personalised_match':
      return Icons.auto_awesome;

    case 'saved_opportunity':
      return Icons.bookmark;

    case 'help_request':
      return Icons.volunteer_activism;

    case 'offer':
      return Icons.handshake;

    case 'connection':
      return Icons.people;

    case 'message':
      return Icons.message;

    default:
      return Icons.notifications;
  }
}

String formatNotificationDate(dynamic date) {
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
