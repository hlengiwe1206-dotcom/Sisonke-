import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _opportunitiesFuture;

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Jobs',
    'Tenders',
    'Funding',
    'Training',
    'Business',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _opportunitiesFuture = _loadOpportunities();
  }

  Future<List<Map<String, dynamic>>> _loadOpportunities() async {
    try {
      final List<dynamic> data = await _supabase
          .from('opportunities')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (error) {
      throw Exception('Unable to load opportunities: $error');
    }
  }

  Future<void> _refreshOpportunities() async {
    setState(() {
      _opportunitiesFuture = _loadOpportunities();
    });

    await _opportunitiesFuture;
  }

  List<Map<String, dynamic>> _filterOpportunities(
    List<Map<String, dynamic>> opportunities,
  ) {
    if (_selectedCategory == 'All') {
      return opportunities;
    }

    return opportunities.where((opportunity) {
      final category =
          _safeText(opportunity['category']).trim().toLowerCase();

      return category == _selectedCategory.toLowerCase();
    }).toList();
  }

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
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

    return value.toString().toLowerCase() == 'true';
  }

  DateTime? _safeDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic value) {
    final date = _safeDate(value);

    if (date == null) {
      return '';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatRelativeDate(dynamic value) {
    final date = _safeDate(value);

    if (date == null) {
      return 'Recently added';
    }

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

    return _formatDate(date);
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'jobs':
        return Icons.work_outline;

      case 'tenders':
        return Icons.description_outlined;

      case 'funding':
        return Icons.account_balance_outlined;

      case 'training':
        return Icons.school_outlined;

      case 'business':
        return Icons.business_center_outlined;

      case 'education':
        return Icons.menu_book_outlined;

      default:
        return Icons.campaign_outlined;
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

      default:
        return Colors.grey;
    }
  }

  void _openOpportunity(Map<String, dynamic> opportunity) {
    final title = _safeText(
      opportunity['title'],
      fallback: 'Opportunity',
    );

    final description = _safeText(
      opportunity['description'],
      fallback: 'No additional information is available.',
    );

    final category = _safeText(
      opportunity['category'],
      fallback: 'Opportunity',
    );

    final organisation = _safeText(
      opportunity['organisation'] ??
          opportunity['organization'] ??
          opportunity['company'] ??
          opportunity['provider'],
    );

    final location = _safeText(opportunity['location']);

    final deadline = _formatDate(
      opportunity['closing_date'] ??
          opportunity['deadline'] ??
          opportunity['application_deadline'],
    );

    final briefingDate = _formatDate(
      opportunity['briefing_date'],
    );

    final briefingRequired = _safeBool(
      opportunity['briefing_required'],
    );

    final link = _safeText(
      opportunity['link'] ??
          opportunity['url'] ??
          opportunity['application_link'],
    );

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
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _categoryColor(category)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _categoryIcon(category),
                                color: _categoryColor(category),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: _categoryColor(category),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        if (organisation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  organisation,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          'About this opportunity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.55,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        if (deadline.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _detailTile(
                            icon: Icons.event_outlined,
                            title: 'Closing date',
                            value: deadline,
                            color: Colors.redAccent,
                          ),
                        ],
                        if (briefingRequired) ...[
                          const SizedBox(height: 12),
                          _detailTile(
                            icon: Icons.groups_outlined,
                            title: 'Briefing',
                            value: briefingDate.isNotEmpty
                                ? 'Required • $briefingDate'
                                : 'Briefing required',
                            color: Colors.orange,
                          ),
                        ],
                        if (link.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);

                                ScaffoldMessenger.of(this.context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Application link is available in the opportunity record.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text(
                                'View Application Details',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
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
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Opportunities',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _opportunitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          final opportunities = snapshot.data ?? [];

          final filteredOpportunities =
              _filterOpportunities(opportunities);

          return RefreshIndicator(
            onRefresh: _refreshOpportunities,
            child: Column(
              children: [
                _buildHeader(
                  opportunities.length,
                ),
                _buildCategories(),
                Expanded(
                  child: filteredOpportunities.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount: filteredOpportunities.length,
                          itemBuilder: (context, index) {
                            return _buildOpportunityCard(
                              filteredOpportunities[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int totalOpportunities) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover opportunities',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$totalOpportunities opportunities available for you',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 64,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        itemCount: _categories.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final category = _categories[index];

          final isSelected =
              category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
            selectedColor: const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFF3F4F6),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunityCard(
    Map<String, dynamic> opportunity,
  ) {
    final title = _safeText(
      opportunity['title'],
      fallback: 'Untitled opportunity',
    );

    final description = _safeText(
      opportunity['description'],
      fallback: 'Tap to view more information.',
    );

    final category = _safeText(
      opportunity['category'],
      fallback: 'Opportunity',
    );

    final organisation = _safeText(
      opportunity['organisation'] ??
          opportunity['organization'] ??
          opportunity['company'] ??
          opportunity['provider'],
    );

    final deadline = _formatDate(
      opportunity['closing_date'] ??
          opportunity['deadline'] ??
          opportunity['application_deadline'],
    );

    final createdAt = _formatRelativeDate(
      opportunity['published_at'] ??
          opportunity['created_at'],
    );

    final color = _categoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _openOpportunity(opportunity);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categoryIcon(category),
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.25,
                  ),
                ),
                if (organisation.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    organisation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: const Color(0xFFF0F0F0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              createdAt,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (deadline.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            deadline,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.search_off_outlined,
          size: 64,
          color: Colors.grey,
        ),
        SizedBox(height: 18),
        Center(
          child: Text(
            'No opportunities found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'New opportunities will appear here as they are published.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: _refreshOpportunities,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Unable to load opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _refreshOpportunities,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}
