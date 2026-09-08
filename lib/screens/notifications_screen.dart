import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();

    loadNotifications();
    listenForNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading notifications: $error');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void listenForNotifications() {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    notificationChannel = supabase
        .channel('notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (!mounted) return;

            final newNotification =
                Map<String, dynamic>.from(payload.newRecord);

            setState(() {
              notifications.insert(0, newNotification);
            });
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
          (notification) =>
              notification['id'].toString() == notificationId,
        );

        if (index != -1) {
          notifications[index]['is_read'] = true;
          notifications[index]['read_at'] =
              DateTime.now().toIso8601String();
        }
      });
    } catch (error) {
      debugPrint('Error marking notification as read: $error');
    }
  }

  @override
  void dispose() {
    if (notificationChannel != null) {
      supabase.removeChannel(notificationChannel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where(
      (notification) =>
          notification['is_read'] == false,
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          unreadCount > 0
              ? 'Notifications ($unreadCount)'
              : 'Notifications',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification =
                          notifications[index];

                      final isRead =
                          notification['is_read'] as bool? ??
                              false;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              isRead
                                  ? Icons.notifications_none
                                  : Icons.notifications,
                            ),
                          ),
                          title: Text(
                            notification['title'] ??
                                'Notification',
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            notification['body'] ?? '',
                          ),
                          trailing: isRead
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  size: 10,
                                ),
                          onTap: () {
                            if (!isRead) {
                              markAsRead(
                                notification['id'].toString(),
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
