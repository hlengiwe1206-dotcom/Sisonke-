import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _green = Color(0xFF1B7A4A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // PROFILE HEADER
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: _green,
                        child: Text(
                          'H',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Member',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Johannesburg, Gauteng',
                              style: TextStyle(
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showComingSoon(
                            context,
                            'Profile editing will be available soon.',
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit profile',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: _border),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Sisonke community profile',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // IMPACT SECTION
          Text(
            'My Sisonke Impact',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: const [
              _ImpactCard(
                value: '12',
                label: 'People helped',
                icon: Icons.volunteer_activism_outlined,
              ),
              _ImpactCard(
                value: '5',
                label: 'Help received',
                icon: Icons.favorite_outline,
              ),
              _ImpactCard(
                value: '8',
                label: 'Impact shared',
                icon: Icons.share_outlined,
              ),
              _ImpactCard(
                value: '4',
                label: 'Actions joined',
                icon: Icons.groups_outlined,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ACCOUNT SECTION
          Text(
            'Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 14),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            child: Column(
              children: [
                _ProfileOption(
                  icon: Icons.bookmark_border,
                  title: 'Saved content',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Saved content will be available soon.',
                    );
                  },
                ),
                const Divider(height: 1, color: _border),
                _ProfileOption(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Settings will be available soon.',
                    );
                  },
                ),
                const Divider(height: 1, color: _border),
                _ProfileOption(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & safety',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Privacy and safety settings will be available soon.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // COMMUNITY SECTION
          Text(
            'Community',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 14),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _border),
            ),
            child: Column(
              children: [
                _ProfileOption(
                  icon: Icons.info_outline,
                  title: 'About Sisonke',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'About Sisonke will be available soon.',
                    );
                  },
                ),
                const Divider(height: 1, color: _border),
                _ProfileOption(
                  icon: Icons.help_outline,
                  title: 'Help & support',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Help and support will be available soon.',
                    );
                  },
                ),
                const Divider(height: 1, color: _border),
                _ProfileOption(
                  icon: Icons.description_outlined,
                  title: 'Terms & policies',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Terms and policies will be available soon.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          OutlinedButton.icon(
            onPressed: () {
              _showSignOutDialog(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoon(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'Are you sure you want to sign out of Sisonke?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sign out functionality will be connected soon.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  static const Color _green = Color(0xFF1B7A4A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: _green,
              size: 25,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
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
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  static const Color _green = Color(0xFF1B7A4A);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: _green,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
    );
  }
}
