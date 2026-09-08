import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isUpdating = false;

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
        _notifications =
            List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading notifications: $error');

      if (!mounted) return;

      setState(() {
        _notifications = [];
        _isLoading = false;
      });

      _showMessage(
        'Unable to load notifications.',
        isError: true,
      );
    }
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id'];

    if (notificationId == null) return;

    try {
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
          _notifications[index] = {
            ..._notifications[index],
            'is_read': true,
          };
        }
      });
    } catch (error) {
      debugPrint('Error marking notification as read: $error');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty) return;

    final unreadNotifications = _notifications
        .where(
          (notification) =>
              notification['is_read'] != true,
        )
        .toList();

    if (unreadNotifications.isEmpty) return;

    try {
      setState(() {
        _isUpdating = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('user_id', user.id)
          .neq('is_read', true);

      if (!mounted) return;

      setState(() {
        _notifications = _notifications
            .map(
              (notification) => {
                ...notification,
                'is_read': true,
              },
            )
            .toList();
      });

      _showMessage('All notifications marked as read.');
    } catch (error) {
      debugPrint('Error marking all notifications as read: $error');

      _showMessage(
        'Unable to update notifications.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id'];

    if (notificationId == null) return;

    try {
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

      _showMessage('Notification deleted.');
    } catch (error) {
      debugPrint('Error deleting notification: $error');

      _showMessage(
        'Unable to delete notification.',
        isError: true,
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_notifications.isEmpty) return;

    final confirmed = await _showDeleteConfirmation();

    if (confirmed != true) return;

    try {
      setState(() {
        _isUpdating = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase
          .from('notifications')
          .delete()
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        _notifications = [];
      });

      _showMessage('All notifications deleted.');
    } catch (error) {
      debugPrint('Error deleting notifications: $error');

      _showMessage(
        'Unable to delete notifications.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete notifications?'),
          content: const Text(
            'This will permanently delete all your notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : Colors.green,
        ),
      );
  }

  String _getTitle(
    Map<String, dynamic> notification,
  ) {
    final value =
        notification['title'] ??
        notification['subject'] ??
        notification['notification_title'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Notification';
    }

    return value.toString();
  }

  String _getBody(
    Map<String, dynamic> notification,
  ) {
    final value =
        notification['body'] ??
        notification['message'] ??
        notification['description'] ??
        notification['content'];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  IconData _getNotificationIcon(
    Map<String, dynamic> notification,
  ) {
    final type =
        notification['type']
            ?.toString()
            .toLowerCase() ??
        '';

    if (type.contains('application')) {
      return Icons.assignment_outlined;
    }

    if (type.contains('job')) {
      return Icons.work_outline;
    }

    if (type.contains('message')) {
      return Icons.message_outlined;
    }

    if (type.contains('alert')) {
      return Icons.warning_amber_outlined;
    }

    if (type.contains('success')) {
      return Icons.check_circle_outline;
    }

    return Icons.notifications_outlined;
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    DateTime? date;

    try {
      date = DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return value.toString();
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final unreadCount = _notifications
        .where(
          (notification) =>
              notification['is_read'] != true,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read_all') {
                  _markAllAsRead();
                }

                if (value == 'delete_all') {
                  _deleteAllNotifications();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'read_all',
                  enabled: !_isUpdating,
                  child: const Row(
                    children: [
                      Icon(Icons.done_all),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete_all',
                  enabled: !_isUpdating,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete all',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'When you receive notifications,\nthey will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      physics:
          const AlwaysScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) {
        return const Divider(
          height: 1,
          indent: 76,
        );
      },
      itemBuilder: (context, index) {
        final notification =
            _notifications[index];

        return _NotificationTile(
          notification: notification,
          title: _getTitle(notification),
          body: _getBody(notification),
          date: _formatDate(
            notification['created_at'],
          ),
          icon: _getNotificationIcon(
            notification,
          ),
          onTap: () {
            if (notification['is_read'] != true) {
              _markAsRead(notification);
            }
          },
          onDelete: () {
            _deleteNotification(notification);
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String title;
  final String body;
  final String date;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.title,
    required this.body,
    required this.date,
    required this.icon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread =
        notification['is_read'] != true;

    final theme = Theme.of(context);

    return Dismissible(
      key: Key(
        notification['id']?.toString() ??
            UniqueKey().toString(),
      ),
      direction:
          DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        return true;
      },
      onDismissed: (_) {
        onDelete();
      },
      child: Material(
        color: isUnread
            ? theme.colorScheme.primary
                .withOpacity(0.05)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primary
                          .withOpacity(0.12),
                  child: Icon(
                    icon,
                    color:
                        theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 9,
                              height: 9,
                              margin:
                                  const EdgeInsets.only(
                                left: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme
                                    .colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          body,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
