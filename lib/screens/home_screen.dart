import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_help_request_screen.dart';
import 'notifications_screen.dart';

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
      final filteredPosts = posts.where((post) {
        final isPublished = _safeBool(
          post['is_published'],
          fallback: true,
        );

        final isVerified = _safeBool(
          post['is_verified'],
          fallback: true,
        );

        return isPublished && isVerified;
      }).toList();

      filteredPosts.sort((a, b) {
        final aDate = _postDate(a);
        final bDate = _postDate(b);

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return filteredPosts;
    });
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsStream = _loadPosts();
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );
  }

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  bool _safeBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value == null) return fallback;

    if (value is bool) return value;

    return value.toString().toLowerCase() == 'true';
  }

  DateTime? _postDate(Map<String, dynamic> post) {
    final value =
        post['published_at'] ??
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

    return '${date.day}/${date.month}/${date.year}';
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'opportunity':
      case 'opportunities':
        return const Color(0xFF1F4F7C);

      case 'community':
        return const Color(0xFF0E6B4B);

      case 'employment':
      case 'jobs':
        return const Color(0xFFE85D2A);

      case 'education':
        return const Color(0xFF6C4AB6);

      case 'health':
        return const Color(0xFFD64545);

      case 'government':
        return const Color(0xFF6B7280);

      case 'emergency':
        return const Color(0xFFC62828);

      default:
        return const Color(0xFFFFB000);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'opportunity':
      case 'opportunities':
        return Icons.work_outline_rounded;

      case 'community':
        return Icons.people_outline_rounded;

      case 'employment':
      case 'jobs':
        return Icons.business_center_outlined;

      case 'education':
        return Icons.school_outlined;

      case 'health':
        return Icons.health_and_safety_outlined;

      case 'government':
        return Icons.account_balance_outlined;

      case 'emergency':
        return Icons.warning_amber_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  void _showActionSheet({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            36,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF151515),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$title feature coming next.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    final title = _safeText(
      post['title'],
      fallback: 'Community Information',
    );

    final description = _safeText(
      post['description'],
      fallback: 'No additional information is available.',
    );

    final category = _safeText(
      post['category'],
      fallback: 'Information',
    );

    final source = _safeText(
      post['source_name'] ??
          post['source'] ??
          post['organisation'],
    );

    final date = _formatDate(
      _postDate(post),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  40,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor(
                            category,
                          ).withOpacity(0.18),
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            color: _categoryColor(category),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFFFC247),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'VERIFIED',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(
                    color: Colors.white12,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (source.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            source,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFFB000),
          onRefresh: _refreshPosts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    8,
                  ),
                  child: _buildHeader(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    8,
                  ),
                  child: _buildActionGrid(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    30,
                    24,
                    16,
                  ),
                  child: _buildInformationHeader(),
                ),
              ),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _postsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 45,
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFB000),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          10,
                          24,
                          40,
                        ),
                        child: _buildErrorState(),
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          10,
                          24,
                          50,
                        ),
                        child: _buildEmptyState(),
                      ),
                    );
                  }

                  return SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            index == 0 ? 0 : 12,
                            24,
                            index == posts.length - 1
                                ? 50
                                : 0,
                          ),
                          child: _buildPostCard(post),
                        );
                      },
                      childCount: posts.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning,',
          style: TextStyle(
            fontSize: 22,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Together, we can\nmove forward.',
          style: TextStyle(
            fontSize: 36,
            height: 1.08,
            color: Color(0xFF1F232B),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: const [
            Icon(
              Icons.location_on_outlined,
              color: Color(0xFF6B7280),
              size: 27,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Johannesburg, Gauteng',
                style: TextStyle(
                  fontSize: 19,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildActionCard(
                title: 'ASK FOR\nHELP',
                icon:
                    Icons.volunteer_activism_outlined,
                color: const Color(0xFFE9322A),

                // NOW OPENS THE REAL FORM
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const CreateHelpRequestScreen(),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildActionCard(
                title: 'OFFER\nHELP',
                icon: Icons.handshake_outlined,
                color: const Color(0xFF0F6B4A),
                onTap: () {
                  _showActionSheet(
                    title: 'Offer Help',
                    description:
                        'Offer your skills, resources, knowledge or time to help someone.',
                    icon:
                        Icons.handshake_outlined,
                    color: const Color(0xFF0F6B4A),
                  );
                },
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildActionCard(
                title: 'OPPORTUNITIES',
                icon:
                    Icons.business_center_outlined,
                color: const Color(0xFF1E4F7F),
                onTap: () {
                  _showActionSheet(
                    title: 'Opportunities',
                    description:
                        'Discover jobs, tenders, training, funding and other opportunities.',
                    icon:
                        Icons.business_center_outlined,
                    color: const Color(0xFF1E4F7F),
                  );
                },
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildActionCard(
                title: 'SHARE\nINFO',
                icon: Icons.campaign_outlined,
                color: const Color(0xFFFFB41F),
                onTap: () {
                  _showActionSheet(
                    title: 'Share Information',
                    description:
                        'Help your community by sharing useful and verified information.',
                    icon:
                        Icons.campaign_outlined,
                    color: const Color(0xFFFFB41F),
                  );
                },
              ),
            ),
          ],
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
      color: color,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          height: 210,
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 46,
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.08,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationHeader() {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'COMMUNITY INSIGHT',
          style: TextStyle(
            color: Color(0xFFFFB41F),
            fontSize: 15,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Verified information\nfor our community.',
          style: TextStyle(
            color: Color(0xFF1F232B),
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
  ) {
    final title = _safeText(
      post['title'],
      fallback: 'Community Information',
    );

    final description = _safeText(
      post['description'],
      fallback:
          'Tap to view more information about this community update.',
    );

    final category = _safeText(
      post['category'],
      fallback: 'Information',
    );

    final date = _formatDate(
      _postDate(post),
    );

    final source = _safeText(
      post['source_name'] ??
          post['source'] ??
          post['organisation'],
    );

    final color = _categoryColor(category);

    return Material(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () =>
            _showPostDetails(post),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          color.withOpacity(0.18),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _categoryIcon(category),
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFFFC247),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                maxLines: 4,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Divider(
                color: Colors.white12,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      source.isNotEmpty
                          ? source
                          : date,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFFFB41F),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.forum_outlined,
            size: 52,
            color: Color(0xFFFFB41F),
          ),
          const SizedBox(height: 18),
          const Text(
            'Information is coming',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F232B),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Verified community information will appear here as soon as it is published.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 50,
            color: Color(0xFFE9322A),
          ),
          const SizedBox(height: 18),
          const Text(
            'Unable to load information',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F232B),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your connection and pull down to try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
