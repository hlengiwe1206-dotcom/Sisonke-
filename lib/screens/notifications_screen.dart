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
      setState(() {
        _isLoading = true;
      });

      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
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

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    try {
      final notificationId = notification['id'];

      if (notificationId == null) return;

      await supabase
          .from('notifications')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (item) => item['id'] == notificationId,
        );

        if (index != -1) {
          _notifications[index]['read_at'] =
              DateTime.now().toIso8601String();
        }
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

  Future<void> _markAllAsRead() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase
          .from('notifications')
          .update({
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .isFilter('read_at', null);

      await _loadNotifications();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark all notifications as read: $error',
          ),
        ),
      );
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

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour =
        localDate.hour.toString().padLeft(2, '0');

    final minute =
        localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((notification) {
      return notification['read_at'] == null;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(
                Icons.done_all,
              ),
              onPressed: _markAllAsRead,
            ),

          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: _loadNotifications,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadNotifications,

        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )

            : _notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),

                      Icon(
                        Icons.notifications_none,
                        size: 70,
                        color: Colors.grey,
                      ),

                      SizedBox(height: 16),

                      Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
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
                        (_, __) =>
                            const SizedBox(height: 8),

                    itemBuilder:
                        (context, index) {
                      final notification =
                          _notifications[index];

                      final bool isUnread =
                          notification['read_at'] ==
                              null;

                      final String title =
                          notification['title']
                                  ?.toString() ??
                              'Notification';

                      final String body =
                          notification['body']
                                  ?.toString() ??
                              '';

                      final String type =
                          notification['type']
                                  ?.toString() ??
                              '';

                      final String date =
                          _formatDate(
                        notification[
                            'created_at'],
                      );

                      return Card(
                        elevation:
                            isUnread ? 3 : 0,

                        color: isUnread
                            ? Colors.blue.shade50
                            : Colors.white,

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
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              if (body.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    top: 4,
                                  ),

                                  child: Text(
                                    body,
                                  ),
                                ),

                              if (date.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    top: 6,
                                  ),

                                  child: Text(
                                    date,
                                    style:
                                        const TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          trailing: isUnread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration:
                                      const BoxDecoration(
                                    color: Colors.red,
                                    shape:
                                        BoxShape.circle,
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
