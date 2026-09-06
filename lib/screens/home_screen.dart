import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../data/demo_data.dart';
import '../widgets/post_card.dart';
import '../widgets/sisonke_logo.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onAction;

  const HomeScreen({
    super.key,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const SisonkeLogo(size: 42),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Good morning,',
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          Text(
            'Together, we can move forward.',
            style: Theme.of(context).textTheme.displaySmall,
          ),

          const SizedBox(height: 8),

          const Text(
            'Johannesburg, Gauteng',
            style: TextStyle(
              color: SisonkeColors.muted,
            ),
          ),

          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _QuickAction(
                'ASK FOR HELP',
                Icons.volunteer_activism_outlined,
                SisonkeColors.red,
                onAction,
              ),

              _QuickAction(
                'OFFER HELP',
                Icons.handshake_outlined,
                SisonkeColors.green,
                onAction,
              ),

              _QuickAction(
                'OPPORTUNITIES',
                Icons.work_outline,
                SisonkeColors.blue,
                onAction,
              ),

              _QuickAction(
                'SHARE INFO',
                Icons.campaign_outlined,
                SisonkeColors.gold,
                onAction,
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _InsightCard(),

          const SizedBox(height: 28),

          Text(
            'Your community',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 12),

          ...demoPosts.map(
            (post) => PostCard(post: post),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
    this.label,
    this.icon,
    this.color,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                ),

                const SizedBox(height: 8),

                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SisonkeColors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMMUNITY INSIGHT',
            style: TextStyle(
              color: SisonkeColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Employment support is one of the most discussed needs this week.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Sisonke helps turn information into connection and action.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
