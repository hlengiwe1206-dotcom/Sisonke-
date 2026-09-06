import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Stream<List<Map<String, dynamic>>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _loadPosts();
  }

  Stream<List<Map<String, dynamic>>> _loadPosts() {
    return _supabase
        .from('information_posts')
        .stream(primaryKey: ['id'])
        .map((posts) {
      final sortedPosts = List<Map<String, dynamic>>.from(posts);

      sortedPosts.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return sortedPosts;
    });
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsStream = _loadPosts();
    });

    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _safeText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  bool _safeBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;

    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

  DateTime? _postDate(Map<String, dynamic> post) {
    final value = post['published_at'] ??
        post['created_at'] ??
        post['updated_at'];

    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently added';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _categoryColor(String category) {
    final value = category.toLowerCase();

    if (value.contains('employment') || value.contains('job')) {
      return const Color(0xFF0E6B4A);
    }

    if (value.contains('education') ||
        value.contains('training') ||
        value.contains('learnership')) {
      return const Color(0xFF1E4F7A);
    }

    if (value.contains('business') ||
        value.contains('tender') ||
        value.contains('opportunit')) {
      return const Color(0xFFF0A500);
    }

    if (value.contains('alert') ||
        value.contains('urgent') ||
        value.contains('emergency')) {
      return const Color(0xFFE53935);
    }

    return const Color(0xFF6B7280);
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('employment') || value.contains('job')) {
      return Icons.work_outline;
    }

    if (value.contains('education') ||
        value.contains('training') ||
        value.contains('learnership')) {
      return Icons.school_outlined;
    }

    if (value.contains('business') ||
        value.contains('tender') ||
        value.contains('opportunit')) {
      return Icons.business_center_outlined;
    }

    if (value.contains('alert') ||
        value.contains('urgent') ||
        value.contains('emergency')) {
      return Icons.warning_amber_rounded;
    }

    if (value.contains('health')) {
      return Icons.health_and_safety_outlined;
    }

    if (value.contains('government')) {
      return Icons.account_balance_outlined;
    }

    return Icons.info_outline;
  }

  void _showPostDetails(Map<String, dynamic> post) {
    final title = _safeText(post['title'], fallback: 'Information update');

    final description =
        _safeText(post['description'], fallback: 'No additional information.');

    final category = _safeText(
      post['category'],
      fallback: 'Community Information',
    );

    final source = _safeText(post['source']);

    final verified = _safeBool(
      post['is_verified'] ?? post['verified'],
    );

    final categoryColor = _categoryColor(category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CategoryBadge(
                              label: category,
                              color: categoryColor,
                            ),
                            if (verified)
                              const _VerifiedBadge(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _SisonkeColors.textDark,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.6,
                            color: _SisonkeColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (source.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: _SisonkeColors.green,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Source: $source',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _SisonkeColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SisonkeColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: _SisonkeColors.green,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _postsStream,
            builder: (context, snapshot) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          const _WelcomeHeader(),
                          const SizedBox(height: 28),

                          // MAIN ACTIONS
                          _ActionGrid(
                            onAskForHelp: () {
                              _showComingSoon('Ask for Help');
                            },
                            onOfferHelp: () {
                              _showComingSoon('Offer Help');
                            },
                            onOpportunities: () {
                              _showComingSoon('Opportunities');
                            },
                            onShareInfo: () {
                              _showComingSoon('Share Info');
                            },
                          ),

                          const SizedBox(height: 32),

                          // INFORMATION HUB HEADER
                          const _InformationHubHeader(),

                          const SizedBox(height: 16),

                          // LIVE CONTENT
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData)
                            const _LoadingPosts()

                          else if (snapshot.hasError)
                            _ErrorPosts(
                              message: snapshot.error.toString(),
                              onRetry: _refreshPosts,
                            )

                          else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty)
                            const _EmptyPosts()

                          else
                            ...snapshot.data!
                                .map(
                                  (post) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 14),
                                    child: _InformationPostCard(
                                      post: post,
                                      safeText: _safeText,
                                      safeBool: _safeBool,
                                      formatDate: _formatDate,
                                      postDate: _postDate,
                                      categoryColor: _categoryColor,
                                      categoryIcon: _categoryIcon,
                                      onTap: () => _showPostDetails(post),
                                    ),
                                  ),
                                )
                                .toList(),

                          const SizedBox(height: 40),

                          // COMMUNITY INSIGHT
                          const _CommunityInsightCard(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning,',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _SisonkeColors.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Together, we can\nmove forward.',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.05,
            color: _SisonkeColors.textDark,
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 28,
              color: _SisonkeColors.textGrey,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Johannesburg, Gauteng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: _SisonkeColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final VoidCallback onAskForHelp;
  final VoidCallback onOfferHelp;
  final VoidCallback onOpportunities;
  final VoidCallback onShareInfo;

  const _ActionGrid({
    required this.onAskForHelp,
    required this.onOfferHelp,
    required this.onOpportunities,
    required this.onShareInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                backgroundColor: _SisonkeColors.red,
                icon: Icons.volunteer_activism_outlined,
                title: 'ASK FOR\nHELP',
                onTap: onAskForHelp,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                backgroundColor: _SisonkeColors.green,
                icon: Icons.handshake_outlined,
                title: 'OFFER\nHELP',
                onTap: onOfferHelp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                backgroundColor: _SisonkeColors.blue,
                icon: Icons.business_center_outlined,
                title: 'OPPORTUNITIES',
                onTap: onOpportunities,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                backgroundColor: _SisonkeColors.gold,
                icon: Icons.campaign_outlined,
                title: 'SHARE\nINFO',
                onTap: onShareInfo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.backgroundColor,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.98,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(34),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(34),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 46,
                  color: Colors.white,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        title,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

class _InformationHubHeader extends StatelessWidget {
  const _InformationHubHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SISONKE INFORMATION HUB',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _SisonkeColors.gold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'What you need to know',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: _SisonkeColors.textDark,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.fiber_manual_record,
          size: 13,
          color: _SisonkeColors.green,
        ),
        const SizedBox(width: 6),
        const Text(
          'LIVE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _SisonkeColors.green,
          ),
        ),
      ],
    );
  }
}

class _InformationPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String Function(dynamic value, {String fallback}) safeText;
  final bool Function(dynamic value, {bool fallback}) safeBool;
  final String Function(DateTime? date) formatDate;
  final DateTime? Function(Map<String, dynamic> post) postDate;
  final Color Function(String category) categoryColor;
  final IconData Function(String category) categoryIcon;
  final VoidCallback onTap;

  const _InformationPostCard({
    required this.post,
    required this.safeText,
    required this.safeBool,
    required this.formatDate,
    required this.postDate,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = safeText(
      post['title'],
      fallback: 'Information update',
    );

    final description = safeText(
      post['description'],
      fallback: 'Tap to view more information.',
    );

    final category = safeText(
      post['category'],
      fallback: 'Community Information',
    );

    final verified = safeBool(
      post['is_verified'] ?? post['verified'],
    );

    final color = categoryColor(category);
    final icon = categoryIcon(category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryBadge(
                          label: category,
                          color: color,
                        ),
                        if (verified) const _VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: _SisonkeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _SisonkeColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: _SisonkeColors.textGrey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatDate(postDate(post)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _SisonkeColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: _SisonkeColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _SisonkeColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 13,
            color: _SisonkeColors.green,
          ),
          SizedBox(width: 4),
          Text(
            'VERIFIED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _SisonkeColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPosts extends StatelessWidget {
  const _LoadingPosts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: _SisonkeColors.green,
            ),
            SizedBox(height: 18),
            Text(
              'Loading verified information...',
              style: TextStyle(
                fontSize: 15,
                color: _SisonkeColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 52,
            color: _SisonkeColors.green,
          ),
          SizedBox(height: 16),
          Text(
            'The Information Hub is warming up.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _SisonkeColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Verified community information will appear here as it is added.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _SisonkeColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPosts extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorPosts({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 50,
            color: _SisonkeColors.red,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _SisonkeColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _SisonkeColors.textGrey,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('TRY AGAIN'),
          ),
        ],
      ),
    );
  }
}

class _CommunityInsightCard extends StatelessWidget {
  const _CommunityInsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _SisonkeColors.black,
        borderRadius: BorderRadius.circular(34),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY INSIGHT',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: _SisonkeColors.gold,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Information becomes powerful when it reaches the right people.',
            style: TextStyle(
              fontSize: 28,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'Sisonke brings verified information, opportunities and community support together in one place.',
            style: TextStyle(
              fontSize: 17,
              height: 1.55,
              color: Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }
}

class _SisonkeColors {
  static const Color background = Color(0xFFF4F2ED);

  static const Color textDark = Color(0xFF20242C);
  static const Color textGrey = Color(0xFF69707C);

  static const Color red = Color(0xFFE8342B);
  static const Color green = Color(0xFF0D6A4A);
  static const Color blue = Color(0xFF1E4F7A);
  static const Color gold = Color(0xFFFFB21A);

  static const Color black = Color(0xFF171717);
}
