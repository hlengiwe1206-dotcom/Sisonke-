import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Welcome to Sisonke',
        'message': 'Your account is ready. Start exploring opportunities.',
        'time': 'Just now',
        'read': false,
      },
      {
        'title': 'New Opportunity',
        'message': 'A new opportunity matching your interests is available.',
        'time': '2 hours ago',
        'read': false,
      },
      {
        'title': 'Profile Update',
        'message': 'Remember to keep your profile information up to date.',
        'time': 'Yesterday',
        'read': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isRead = notification['read'] as bool;

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
                notification['title'] as String,
                style: TextStyle(
                  fontWeight:
                      isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                notification['message'] as String,
              ),
              trailing: Text(
                notification['time'] as String,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}
