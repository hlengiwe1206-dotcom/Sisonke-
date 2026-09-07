import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _firstName = 'Friend';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        final fullName =
            (data['full_name'] ??
                    data['name'] ??
                    data['display_name'] ??
                    '')
                .toString()
                .trim();

        if (fullName.isNotEmpty) {
          _firstName = fullName.split(' ').first;
        }
      }
    } catch (_) {
      // Keep the default greeting if profile loading fails.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to sign out. Please try again.'),
        ),
      );
    }
  }

  void _showActionSheet({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onContinue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1B1D),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 36),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    icon,
                    size: 64,
                    color: color,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 19,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 38),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();

                      if (onContinue != null) {
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          () {
                            if (mounted) {
                              onContinue();
                            }
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Ink(
          height: 250,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(38),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 58,
                  ),
                ),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE9E9E9),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: true,
            onTap: () {},
          ),
          _bottomNavItem(
            icon: Icons.explore_outlined,
            label: 'Discover',
            onTap: () {
              Navigator.of(context).pushNamed('/discover');
            },
          ),
          _bottomNavItem(
            icon: Icons.notifications_outlined,
            label: 'Alerts',
            onTap: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),
          _bottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    const selectedColor = Color(0xFF1E4F7F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? selectedColor
                  : const Color(0xFF8A8A8A),
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isSelected
                    ? selectedColor
                    : const Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48 - 16) / 2;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Sisonke',
          style: TextStyle(
            color: Color(0xFF151922),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF151922),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF151922),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).pushNamed('/profile');
              }

              if (value == 'signout') {
                _signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move\nforward.',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontSize: 52,
                        height: 0.98,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 32,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Johannesburg, Gauteng',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Hello, $_firstName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF151922),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'What would you like to do today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _buildActionCard(
                            title: 'ASK\nFOR',
                            icon: Icons.volunteer_activism_outlined,
                            color: const Color(0xFF8B1E19),
                            onTap: () {
                              _showActionSheet(
                                title: 'Ask for Help',
                                description:
                                    'Reach out to the Sisonke community and request assistance.',
                                icon:
                                    Icons.volunteer_activism_outlined,
                                color: const Color(0xFF8B1E19),
                                onContinue: () {
                                  Navigator.of(context).pushNamed(
                                    '/create-help-request',
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(
                          width: cardWidth,
                          child: _buildActionCard(
                            title: 'OFFER\nHELP',
                            icon: Icons.handshake_outlined,
                            color: const Color(0xFF0B3B2E),
                            onTap: () {
                              _showActionSheet(
                                title: 'Offer Help',
                                description:
                                    'Discover people in your community who need your skills and support.',
                                icon: Icons.handshake_outlined,
                                color: const Color(0xFF0B3B2E),
                                onContinue: () {
                                  Navigator.of(context).pushNamed(
                                    '/help-exchange',
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(
                          width: cardWidth,
                          child: _buildActionCard(
                            title: 'DISCOVER',
                            icon: Icons.explore_outlined,
                            color: const Color(0xFF1E4F7F),
                            onTap: () {
                              _showActionSheet(
                                title: 'Discover',
                                description:
                                    'Explore people, skills and opportunities in the Sisonke community.',
                                icon: Icons.explore_outlined,
                                color: const Color(0xFF1E4F7F),
                                onContinue: () {
                                  Navigator.of(context).pushNamed(
                                    '/discover',
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(
                          width: cardWidth,
                          child: _buildActionCard(
                            title: 'OPPORTUNITIES',
                            icon: Icons.business_center_outlined,
                            color: const Color(0xFF9A6805),

                            // THIS IS THE IMPORTANT FIX.
                            onTap: () {
                              _showActionSheet(
                                title: 'Opportunities',
                                description:
                                    'Discover jobs, tenders, training, funding and other opportunities.',
                                icon:
                                    Icons.business_center_outlined,
                                color: const Color(0xFF9A6805),

                                onContinue: () {
                                  Navigator.of(context).pushNamed(
                                    '/opportunities',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}
