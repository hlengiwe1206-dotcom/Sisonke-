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
    final currentTheme = Theme.of(context);

    return Theme(
      data: currentTheme.copyWith(
        textTheme: currentTheme.textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          displaySmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          headlineLarge: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          headlineMedium: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          headlineSmall: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: SisonkeColors.ink,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SisonkeColors.ink,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SisonkeColors.ink,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.4,
            color: SisonkeColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: SisonkeColors.ink,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            height: 1.3,
            color: SisonkeColors.muted,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: SisonkeColors.ivory,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ============================================================
              // HEADER
              // ============================================================

              Row(
                children: [
                  const Expanded(
                    child: SisonkeLogo(
                      size: 40,
                      showWordmark: true,
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // WELCOME TEXT
              // ============================================================

              const Text(
                'Good morning,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: SisonkeColors.muted,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Together, we can move forward.',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: SisonkeColors.ink,
                ),
              ),

              const SizedBox(height: 8),

              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: SisonkeColors.muted,
                  ),

                  SizedBox(width: 4),

                  Text(
                    'Johannesburg, Gauteng',
                    style: TextStyle(
                      fontSize: 14,
                      color: SisonkeColors.muted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // QUICK ACTIONS
              // ============================================================

              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _QuickAction(
                    label: 'ASK FOR HELP',
                    icon: Icons.volunteer_activism_outlined,
                    color: SisonkeColors.red,
                    onTap: onAction,
                  ),

                  _QuickAction(
                    label: 'OFFER HELP',
                    icon: Icons.handshake_outlined,
                    color: SisonkeColors.green,
                    onTap: onAction,
                  ),

                  _QuickAction(
                    label: 'OPPORTUNITIES',
                    icon: Icons.work_outline,
                    color: SisonkeColors.blue,
                    onTap: onAction,
                  ),

                  _QuickAction(
                    label: 'SHARE INFO',
                    icon: Icons.campaign_outlined,
                    color: SisonkeColors.gold,
                    onTap: onAction,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ============================================================
              // COMMUNITY INSIGHT
              // ============================================================

              const _InsightCard(),

              const SizedBox(height: 28),

              // ============================================================
              // COMMUNITY FEED TITLE
              // ============================================================

              const Text(
                'Your community',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SisonkeColors.ink,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'People, opportunities and support around you.',
                style: TextStyle(
                  fontSize: 14,
                  color: SisonkeColors.muted,
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // COMMUNITY POSTS
              // ============================================================

              ...demoPosts.map(
                (post) => PostCard(post: post),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// QUICK ACTION CARD
// ============================================================================

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 34,
                  color: Colors.white,
                ),

                const SizedBox(height: 18),

                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ============================================================================
// COMMUNITY INSIGHT CARD
// ============================================================================

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SisonkeColors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY INSIGHT',
            style: TextStyle(
              color: SisonkeColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),

          SizedBox(height: 14),

          Text(
            'Employment support is one of the most discussed needs this week.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),

          SizedBox(height: 14),

          Text(
            'Sisonke helps turn information into connection and action.',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 
