import 'package:flutter/material.dart';
import '../core/core.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // PROFILE HEADER
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: SisonkeColors.green,
                        child: const Text(
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
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Johannesburg, Gauteng',
                              style: TextStyle(
                                color: SisonkeColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit profile',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: SisonkeColors.border),
                  const SizedBox(height: 16),

                  Text(
                    'Your Sisonke community profile',
                    style: TextStyle(
                      color: SisonkeColors.muted,
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),

          Card(
            child: Column(
              children: [
                _ProfileOption(
                  icon: Icons.bookmark_border,
                  title: 'Saved content',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: SisonkeColors.border,
                ),
                _ProfileOption(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: SisonkeColors.border,
                ),
                _ProfileOption(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & safety',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // COMMUNITY SECTION
          Text(
            'Community',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),

          Card(
            child: Column(
              children: [
                _ProfileOption(
                  icon: Icons.info_outline,
                  title: 'About Sisonke',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: SisonkeColors.border,
                ),
                _ProfileOption(
                  icon: Icons.help_outline,
                  title: 'Help & support',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: SisonkeColors.border,
                ),
                _ProfileOption(
                  icon: Icons.description_outlined,
                  title: 'Terms & policies',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: () {
              _showSignOutDialog(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(
                color: Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
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
                    content: Text('Sign out functionality coming soon.'),
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
  final String value;
  final String label;
  final IconData icon;

  const _ImpactCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: SisonkeColors.green,
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
                      fontWeight: FontWeight.w900,
                      color: SisonkeColors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SisonkeColors.muted,
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
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: SisonkeColors.green,
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.chevron_right,
      ),
    );
  }
}
