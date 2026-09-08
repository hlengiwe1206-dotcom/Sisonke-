import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  int unreadCount = 0;

  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();

    loadUnreadCount();
    listenForNotifications();
  }

  Future<void> loadUnreadCount() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      if (!mounted) return;

      setState(() {
        unreadCount = data.length;
      });
    } catch (error) {
      debugPrint('Error loading unread notifications: $error');
    }
  }

  void listenForNotifications() {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    notificationChannel = supabase
        .channel('home-notifications-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            loadUnreadCount();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (notificationChannel != null) {
      supabase.removeChannel(notificationChannel!);
    }

    super.dispose();
  }

  Future<void> openNotifications() async {
    await Navigator.pushNamed(
      context,
      '/notifications',
    );

    loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sisonke'),

        actions: [
          IconButton(
            onPressed: openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                ),

                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9
                            ? '9+'
                            : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'Home Screen',
        ),
      ),
    );
  }
}
