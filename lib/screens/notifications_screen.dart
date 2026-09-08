import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
        return;
      }

      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

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

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    try {
      final notificationId = notification['id'];

      if (notificationId == null) return;

      await supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('id', notificationId);

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (item) => item['id'] == notificationId,
        );

        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notification: $error',
          ),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (!mounted) return;

      setState(() {
        for (final notification in _notifications) {
          notification['is_read'] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update notifications: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      final notificationId = notification['id'];

      if (notificationId == null) return;

      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
          (item) => item['id'] == notificationId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete notification: $error',
          ),
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _notificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'message':
      case 'chat':
        return Icons.chat_bubble_outline;

      case 'opportunity':
      case 'job':
        return Icons.business_center_outlined;

      case 'application':
        return Icons.description_outlined;

      case 'alert':
      case 'warning':
        return Icons.warning_amber_rounded;

      case 'success':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where(
      (notification) => notification['is_read'] != true,
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        centerTitle: false,
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
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 180,
                      ),
                      Icon(
                        Icons.notifications_none,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Center(
                        child: Text(
                          'You are all caught up.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    itemCount: _notifications.length,
                    separatorBuilder: (
                      context,
                      index,
                    ) {
                      return const Divider(
                        height: 1,
                      );
                    },
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final notification =
                          _notifications[index];

                      final bool isUnread =
                          notification['is_read'] != true;

                      final String title =
                          notification['title']?.toString() ??
                              'Notification';

                      final String body =
                          notification['body']?.toString() ?? '';

                      final String type =
                          notification['type']?.toString() ?? '';

                      final String date =
                          _formatDate(
                        notification['created_at'],
                      );

                      return Dismissible(
                        key: ValueKey(
                          notification['id'] ??
                              '$index-$title',
                        ),
                        direction:
                            DismissDirection.endToStart,
                        background: Container(
                          alignment:
                              Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(
                            right: 24,
                          ),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          _deleteNotification(
                            notification,
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              _notificationIcon(type),
                            ),
                          ),
                          title: Text(
                            title,
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
                              if (body.isNotEmpty) ...[
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                              if (date.isNotEmpty) ...[
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isUnread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () async {
                            if (isUnread) {
                              await _markAsRead(
                                notification,
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
