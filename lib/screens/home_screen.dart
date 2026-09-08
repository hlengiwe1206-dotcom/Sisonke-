import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    loadUnreadNotifications();
  }

  Future<void> loadUnreadNotifications() async {
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
        unreadNotifications = data.length;
      });
    } catch (error) {
      debugPrint(
        'Error loading unread notifications: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sisonke',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  size: 30,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationsScreen(),
                    ),
                  );

                  loadUnreadNotifications();
                },
              ),

              if (unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifications > 99
                            ? '99+'
                            : unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'Welcome to Sisonke',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
} 
