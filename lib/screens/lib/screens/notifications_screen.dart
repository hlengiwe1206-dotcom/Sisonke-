import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
        return;
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications =
              List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load notifications: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(
    String notificationId,
  ) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere(
          (notification) =>
              notification['id'].toString() ==
              notificationId,
        );

        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update notification: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        for (final notification in _notifications) {
          notification['is_read'] = true;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update notifications: $error',
            ),
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(
    String? notificationType,
  ) {
    switch (notificationType) {
      case 'opportunity':
        return Icons.work_outline;

      case 'help_request':
        return Icons.volunteer_activism_outlined;

      case 'message':
        return Icons.message_outlined;

      case 'system':
        return Icons.notifications_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where(
      (notification) =>
          notification['is_read'] != true,
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 200,
                      ),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              'You are all caught up.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount:
                        _notifications.length,
                    separatorBuilder:
                        (
                          context,
                          index,
                        ) =>
                            const SizedBox(
                      height: 8,
                    ),
                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                      final notification =
                          _notifications[index];

                      final bool isRead =
                          notification['is_read'] ==
                              true;

                      final String title =
                          notification['title']
                                  ?.toString() ??
                              'Notification';

                      final String message =
                          notification['message']
                                  ?.toString() ??
                              '';

                      final String type =
                          notification['type']
                                  ?.toString() ??
                              'system';

                      return Card(
                        elevation: isRead ? 0 : 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              _getNotificationIcon(
                                type,
                              ),
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            message,
                          ),
                          trailing: isRead
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  size: 12,
                                ),
                          onTap: () async {
                            final id =
                                notification['id']
                                    ?.toString();

                            if (id != null &&
                                !isRead) {
                              await _markAsRead(
                                id,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
