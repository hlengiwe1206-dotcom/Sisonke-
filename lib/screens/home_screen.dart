import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  int unreadNotifications = 0;

  String userName = 'Sisonke User';
  String? avatarUrl;

  bool isLoadingProfile = true;

  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();

    loadProfile();
    loadUnreadNotifications();
    listenForNotifications();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoadingProfile = false;
          });
        }
        return;
      }

      final data = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (data != null) {
          userName =
              data['full_name']?.toString().trim().isNotEmpty == true
                  ? data['full_name'].toString()
                  : user.email?.split('@').first ?? 'Sisonke User';

          avatarUrl = data['avatar_url']?.toString();
        } else {
          userName =
              user.email?.split('@').first ?? 'Sisonke User';
        }

        isLoadingProfile = false;
      });
    } catch (error) {
      debugPrint('Error loading profile: $error');

      final user = supabase.auth.currentUser;

      if (mounted) {
        setState(() {
          userName =
              user?.email?.split('@').first ?? 'Sisonke User';
          isLoadingProfile = false;
        });
      }
    }
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
            loadUnreadNotifications();
          },
        )
        .subscribe();
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NotificationsScreen(),
      ),
    );

    loadUnreadNotifications();
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfileScreen(),
      ),
    );

    loadProfile();
  }

  @override
  void dispose() {
    if (notificationChannel != null) {
      supabase.removeChannel(notificationChannel!);
    }

    super.dispose();
  }

  String getFirstName() {
    if (userName.trim().isEmpty) {
      return 'there';
    }

    return userName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await loadProfile();
            await loadUnreadNotifications();
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 30),

                _buildWelcomeSection(),

                const SizedBox(height: 30),

                _buildQuickActions(),

                const SizedBox(height: 30),

                _buildGettingStartedCard(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                'assets/images/sisonke_logo.png',
                height: 52,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                  return const Text(
                    'Sisonke',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    size: 30,
                  ),
                  onPressed: openNotifications,
                ),

                if (unreadNotifications > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      constraints:
                          const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        unreadNotifications > 99
                            ? '99+'
                            : unreadNotifications
                                .toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 4),

            GestureDetector(
              onTap: openProfile,
              child: _buildAvatar(
                radius: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (isLoadingProfile)
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 18,
            ),
          )
        else
          Text(
            'Welcome back, ${getFirstName()} 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

        const SizedBox(height: 10),

        const Text(
          'Discover opportunities, connect with people and grow with Sisonke.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_outline,
                title: 'My Profile',
                subtitle:
                    'Update your profile',
                onTap: openProfile,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildActionCard(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: unreadNotifications > 0
                    ? '$unreadNotifications unread'
                    : 'All caught up',
                onTap: openNotifications,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
              ),

              const SizedBox(height: 18),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGettingStartedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 30,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Make your profile visible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Add your name and profile picture so other Sisonke users can recognise and connect with you.',
                    style: TextStyle(
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton.icon(
                    onPressed: openProfile,
                    icon: const Icon(
                      Icons.edit,
                    ),
                    label: const Text(
                      'Complete Profile',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required double radius,
  }) {
    final hasAvatar =
        avatarUrl != null &&
            avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .primaryContainer,
      backgroundImage: hasAvatar
          ? NetworkImage(avatarUrl!)
          : null,
      child: hasAvatar
          ? null
          : Icon(
              Icons.person,
              size: radius,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
    );
  }
}
