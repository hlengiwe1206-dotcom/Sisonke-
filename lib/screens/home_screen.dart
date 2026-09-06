import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF5F3EE);
  static const Color _textColor = Color(0xFF20242C);
  static const Color _mutedTextColor = Color(0xFF69717D);

  static const Color _helpColor = Color(0xFFE9342D);
  static const Color _offerColor = Color(0xFF0F6B4A);
  static const Color _opportunityColor = Color(0xFF1E4F7E);
  static const Color _shareColor = Color(0xFFFFB51B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 8),
              _buildLocation(),
              const SizedBox(height: 32),

              _buildActionGrid(context),

              const SizedBox(height: 32),

              _buildCommunityInsight(),

              const SizedBox(height: 28),

              _buildInformationHubHeader(),

              const SizedBox(height: 16),

              _buildInformationCard(
                icon: Icons.campaign_outlined,
                category: 'COMMUNITY UPDATE',
                title: 'Important information for Johannesburg communities',
                description:
                    'Verified information, updates and opportunities will appear here.',
                color: _shareColor,
              ),

              const SizedBox(height: 16),

              _buildInformationCard(
                icon: Icons.work_outline,
                category: 'OPPORTUNITY',
                title: 'New opportunities shared with the community',
                description:
                    'Jobs, learnerships, bursaries and skills development opportunities.',
                color: _opportunityColor,
              ),

              const SizedBox(height: 16),

              _buildInformationCard(
                icon: Icons.people_outline,
                category: 'COMMUNITY',
                title: 'Sisonke connects people, information and action',
                description:
                    'The Information Hub will help ensure useful verified information reaches the community.',
                color: _offerColor,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Good morning,',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Together, we can\nmove forward.',
          style: TextStyle(
            fontSize: 38,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return const Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 28,
          color: _mutedTextColor,
        ),
        SizedBox(width: 8),
        Text(
          'Johannesburg, Gauteng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.02,
      children: [
        _QuickAction(
          icon: Icons.volunteer_activism_outlined,
          title: 'ASK FOR\nHELP',
          backgroundColor: _helpColor,
          onTap: () {
            _showComingSoon(context, 'Ask for Help');
          },
        ),
        _QuickAction(
          icon: Icons.handshake_outlined,
          title: 'OFFER\nHELP',
          backgroundColor: _offerColor,
          onTap: () {
            _showComingSoon(context, 'Offer Help');
          },
        ),
        _QuickAction(
          icon: Icons.business_center_outlined,
          title: 'OPPORTUNITIES',
          backgroundColor: _opportunityColor,
          onTap: () {
            _showComingSoon(context, 'Opportunities');
          },
        ),
        _QuickAction(
          icon: Icons.campaign_outlined,
          title: 'SHARE\nINFO',
          backgroundColor: _shareColor,
          onTap: () {
            _showComingSoon(context, 'Share Information');
          },
        ),
      ],
    );
  }

  Widget _buildCommunityInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'COMMUNITY INSIGHT',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFBE32),
            ),
          ),
          SizedBox(height: 22),
          Text(
            'Employment support is one of the most discussed needs this week.',
            style: TextStyle(
              fontSize: 28,
              height: 1.22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'Sisonke helps turn information into connection and action.',
            style: TextStyle(
              fontSize: 19,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB9BDC5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationHubHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMATION HUB',
          style: TextStyle(
            fontSize: 15,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFA800),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'What is happening in your community?',
          style: TextStyle(
            fontSize: 27,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Verified information, opportunities and community updates.',
          style: TextStyle(
            fontSize: 17,
            height: 1.4,
            color: _mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String category,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title section is being connected to the Sisonke Hub.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 44,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
