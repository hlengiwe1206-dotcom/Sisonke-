import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;

  const NotificationBell({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_rounded),
        onPressed: onPressed,
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];

        final unreadCount = notifications
            .where((notification) => notification['read_at'] == null)
            .length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
              ),
              tooltip: 'Notifications',
              onPressed: onPressed,
            ),

            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99
                          ? '99+'
                          : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
