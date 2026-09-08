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
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'You must be logged in to view notifications.';
        _notifications = [];
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(
          response.map(
            (notification) =>
                Map<String, dynamic>.from(notification as Map),
          ),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final notificationId = notification['id'];

    if (notificationId == null) return;

    final isUnread = notification['read_at'] == null;

    if (!isUnread) return;

    try {
      await _supabase
          .from('notifications')
          .update({
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        notification['read_at'] =
            DateTime.now().toUtc().toIso8601String();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark notification as read: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final notificationId = notification['id'];

    if (notificationId == null) return;

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);

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

  Future<void> _showDeleteConfirmation(
    Map<String, dynamic> notification,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete notification?'),
          content: const Text(
            'This notification will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteNotification(notification);
    }
  }

  IconData _getNotificationIcon(String? type) {
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

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'closing_date':
      case 'deadline':
        return Colors.red;

      case 'opportunity_match':
      case 'personalised_match':
        return Colors.deepPurple;

      case 'saved_opportunity':
        return Colors.orange;

      case 'help_request':
        return Colors.green;

      case 'offer':
        return Colors.teal;

      case 'connection':
        return Colors.blue;

      case 'message':
        return Colors.indigo;

      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '';

    final localDate = date.toLocal();

    final now = DateTime.now();
    final difference = now.difference(localDate);

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

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day/$month/$year';
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
  ) {
    final type = notification['type']?.toString();
    final title =
        notification['title']?.toString() ?? 'Notification';
    final body = notification['body']?.toString() ?? '';
    final createdAt = notification['created_at'];
    final isUnread = notification['read_at'] == null;

    final icon = _getNotificationIcon(type);
    final iconColor = _getNotificationColor(type);

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _showDeleteConfirmation(notification);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Card(
        elevation: isUnread ? 3 : 0,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnread
                ? Colors.blue.shade100
                : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _markAsRead(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: iconColor.withOpacity(0.12),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
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
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete notification',
                  onPressed: () {
                    _showDeleteConfirmation(notification);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are all caught up.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(
            _notifications[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where(
          (notification) => notification['read_at'] == null,
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadNotifications,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
