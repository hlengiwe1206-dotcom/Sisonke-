import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _postsFuture;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = const [
    'All',
    'Community',
    'Safety',
    'Jobs',
    'Tenders',
    'Funding',
    'Training',
    'Business',
    'Education',
    'Events',
  ];

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadPosts() async {
    try {
      final List<dynamic> data = await _supabase
          .from('information_posts')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> posts =
          List<Map<String, dynamic>>.from(data);

      final List<Map<String, dynamic>> verifiedPosts = posts.where((post) {
        return _safeBool(
          post['is_verified'],
          fallback: true,
        );
      }).toList();

      return verifiedPosts;
    } catch (error) {
      throw Exception('Unable to load community information: $error');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _loadPosts();
    });

    await _postsFuture;
  }

  List<Map<String, dynamic>> _filterPosts(
    List<Map<String, dynamic>> posts,
  ) {
    return posts.where((post) {
      final String category = _safeText(post['category']);

      final String title = _safeText(post['title']);
      final String description = _safeText(post['description']);
      final String organisation = _safeText(
        post['organisation'] ??
            post['organization'] ??
            post['source'],
      );
      final String location = _safeText(
        post['location'] ??
            post['municipality'] ??
            post['province'],
      );

      final bool categoryMatches =
          _selectedCategory == 'All' ||
              category.toLowerCase() ==
                  _selectedCategory.toLowerCase();

      final String searchableText = [
        title,
        description,
        organisation,
        location,
        category,
      ].join(' ').toLowerCase();

      final bool searchMatches =
          _searchQuery.trim().isEmpty ||
              searchableText.contains(
                _searchQuery.trim().toLowerCase(),
              );

      return categoryMatches && searchMatches;
    }).toList();
  }

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  bool _safeBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    final String text = value.toString().trim().toLowerCase();

    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }

    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }

    return fallback;
  }

  DateTime? _postDate(Map<String, dynamic> post) {
    final dynamic value =
        post['published_at'] ??
            post['created_at'] ??
            post['updated_at'];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Recently added';
    }

    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date.toLocal());

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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'jobs':
        return Icons.work_outline_rounded;

      case 'tenders':
        return Icons.assignment_outlined;

      case 'funding':
        return Icons.account_balance_wallet_outlined;

      case 'training':
        return Icons.school_outlined;

      case 'business':
        return Icons.business_outlined;

      case 'education':
        return Icons.menu_book_outlined;

      case 'safety':
        return Icons.health_and_safety_outlined;

      case 'events':
        return Icons.event_outlined;

      case 'community':
        return Icons.groups_outlined;

      default:
        return Icons.public_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'jobs':
        return Colors.blue;

      case 'tenders':
        return Colors.deepPurple;

      case 'funding':
        return Colors.green;

      case 'training':
        return Colors.orange;

      case 'business':
        return Colors.indigo;

      case 'education':
        return Colors.teal;

      case 'safety':
        return Colors.red;

      case 'events':
        return Colors.pink;

      case 'community':
        return Colors.cyan;

      default:
        return Colors.blueGrey;
    }
  }

  void _showPostDetails(Map<String, dynamic> post) {
    final String title = _safeText(
      post['title'],
      fallback: 'Community Information',
    );

    final String description = _safeText(
      post['description'] ??
          post['content'] ??
          post['body'],
      fallback: 'No additional information is available.',
    );

    final String category = _safeText(
      post['category'],
      fallback: 'Community',
    );

    final String organisation = _safeText(
      post['organisation'] ??
          post['organization'] ??
          post['source'],
    );

    final String location = _safeText(
      post['location'] ??
          post['municipality'] ??
          post['province'],
    );

    final String contact = _safeText(
      post['contact'] ??
          post['contact_details'] ??
          post['email'],
    );

    final String link = _safeText(
      post['link'] ??
          post['url'] ??
          post['website'],
    );

    final DateTime? date = _postDate(post);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        40,
                      ),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _categoryColor(category)
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _categoryIcon(category),
                                color: _categoryColor(category),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color:
                                          _categoryColor(category),
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified information',
                                        style: TextStyle(
                                          color:
                                              Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        if (organisation.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _detailTile(
                            icon: Icons.business_outlined,
                            title: 'Source',
                            value: organisation,
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _detailTile(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            value: location,
                          ),
                        ],
                        if (contact.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _detailTile(
                            icon: Icons.contact_mail_outlined,
                            title: 'Contact',
                            value: contact,
                          ),
                        ],
                        if (link.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _detailTile(
                            icon: Icons.link_rounded,
                            title: 'More information',
                            value: link,
                          ),
                        ],
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

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Verified community information',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search opportunities and information...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1F7A5A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  return const SizedBox(width: 8);
                },
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final String category =
                      _categories[index];

                  final bool selected =
                      category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor:
                        const Color(0xFF1F7A5A),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF1F7A5A)
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<Map<String, dynamic>>>
                      snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(
                      snapshot.error.toString(),
                    );
                  }

                  final List<Map<String, dynamic>>
                      posts =
                      _filterPosts(
                    snapshot.data ?? [],
                  );

                  if (posts.isEmpty) {
                    return _emptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshPosts,
                    child: ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        return _postCard(posts[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(Map<String, dynamic> post) {
    final String title = _safeText(
      post['title'],
      fallback: 'Community Information',
    );

    final String description = _safeText(
      post['description'] ??
          post['content'] ??
          post['body'],
      fallback: 'Tap to view more information.',
    );

    final String category = _safeText(
      post['category'],
      fallback: 'Community',
    );

    final String organisation = _safeText(
      post['organisation'] ??
          post['organization'] ??
          post['source'],
    );

    final DateTime? date = _postDate(post);

    final Color categoryColor =
        _categoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showPostDetails(post),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: categoryColor
                            .withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _categoryIcon(category),
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.green,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Verified',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (organisation.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 16,
                              color:
                                  Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                organisation,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.55,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF1F7A5A,
                        ).withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        size: 40,
                        color: Color(0xFF1F7A5A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nothing to discover yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory == 'All'
                          ? 'Verified community information will appear here as it becomes available.'
                          : 'No verified information is currently available in the $_selectedCategory category.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _refreshPosts,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text(
                        'Refresh',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load information',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
