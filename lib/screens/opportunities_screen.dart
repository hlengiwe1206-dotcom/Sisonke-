import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState
    extends State<OpportunitiesScreen> {
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

      return List<Map<String, dynamic>>.from(data);
    } catch (error) {
      throw Exception(
        'Unable to load opportunities: $error',
      );
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
      final String category =
          opportunity['category']?.toString() ?? '';

      return category.toLowerCase() ==
          _selectedCategory.toLowerCase();
    }).toList();
  }

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    return value.toString();
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
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
        return const Color(0xFF1565C0);

      case 'tenders':
        return const Color(0xFF7B1FA2);

      case 'funding':
        return const Color(0xFF2E7D32);

      case 'training':
        return const Color(0xFFF57C00);

      case 'business':
        return const Color(0xFF00838F);

      case 'education':
        return const Color(0xFFC62828);

      default:
        return const Color(0xFF37474F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'Opportunities',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshOpportunities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOpportunities,
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryFilter(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _opportunitiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(
                      snapshot.error.toString(),
                    );
                  }

                  final List<Map<String, dynamic>>
                      opportunities =
                      _filterOpportunities(
                    snapshot.data ?? [],
                  );

                  if (opportunities.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      30,
                    ),
                    itemCount: opportunities.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return _buildOpportunityCard(
                        opportunities[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      color: Colors.white,
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Find your next opportunity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F1F1F),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Verified jobs, tenders, funding, training and opportunities for our community.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 62,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        itemCount: _categories.length,
        separatorBuilder: (
          context,
          index,
        ) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (
          context,
          index,
        ) {
          final String category =
              _categories[index];

          final bool selected =
              category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            selectedColor:
                const Color(0xFF111111),
            backgroundColor:
                const Color(0xFFF0F0F0),
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
            onSelected: (bool value) {
              if (value) {
                setState(() {
                  _selectedCategory =
                      category;
                });
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildOpportunityCard(
    Map<String, dynamic> opportunity,
  ) {
    final String title = _safeText(
      opportunity['title'],
      fallback: 'Untitled opportunity',
    );

    final String description = _safeText(
      opportunity['description'],
    );

    final String category = _safeText(
      opportunity['category'],
      fallback: 'Opportunity',
    );

    final String organisation = _safeText(
      opportunity['organisation'] ??
          opportunity['company'] ??
          opportunity['source'],
    );

    final String location = _safeText(
      opportunity['location'],
    );

    final String link = _safeText(
      opportunity['link'] ??
          opportunity['url'] ??
          opportunity['application_link'],
    );

    final DateTime? closingDate = _parseDate(
      opportunity['closing_date'],
    );

    final bool verified = _safeBool(
      opportunity['is_verified'],
    );

    final Color categoryColor =
        _categoryColor(category);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE8E8E8),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _showOpportunityDetails(
            opportunity,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          categoryColor.withOpacity(
                        0.12,
                      ),
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
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight:
                                FontWeight.w800,
                            color: categoryColor,
                          ),
                        ),
                        if (verified)
                          const SizedBox(height: 4),
                        if (verified)
                          const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 15,
                                color:
                                    Color(0xFF1B8F4B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFF1B8F4B),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.25,
                  fontWeight:
                      FontWeight.w800,
                  color: Color(0xFF202020),
                ),
              ),
              if (organisation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  organisation,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  if (location.isNotEmpty)
                    _buildInfoItem(
                      Icons.location_on_outlined,
                      location,
                    ),
                  if (closingDate != null)
                    _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Closes ${_formatDate(closingDate)}',
                    ),
                ],
              ),
              if (link.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Text(
                      'View opportunity',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF111111),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF777777),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF777777),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 80),
        Icon(
          Icons.search_off_outlined,
          size: 58,
          color: Color(0xFF999999),
        ),
        SizedBox(height: 16),
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
          padding:
              EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'New verified opportunities will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF777777),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    String error,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.cloud_off_outlined,
          size: 58,
          color: Color(0xFF999999),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Unable to load opportunities',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          error,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed:
                _refreshOpportunities,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try again',
            ),
          ),
        ),
      ],
    );
  }

  void _showOpportunityDetails(
    Map<String, dynamic> opportunity,
  ) {
    final String title = _safeText(
      opportunity['title'],
      fallback: 'Opportunity',
    );

    final String description =
        _safeText(
      opportunity['description'],
    );

    final String category =
        _safeText(
      opportunity['category'],
      fallback: 'Opportunity',
    );

    final String organisation =
        _safeText(
      opportunity['organisation'] ??
          opportunity['company'] ??
          opportunity['source'],
    );

    final String location =
        _safeText(
      opportunity['location'],
    );

    final DateTime? closingDate =
        _parseDate(
      opportunity['closing_date'],
    );

    final bool verified =
        _safeBool(
      opportunity['is_verified'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller:
                    scrollController,
                padding:
                    const EdgeInsets.all(22),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFFD0D0D0),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          _categoryColor(
                        category,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 25,
                      height: 1.2,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  if (verified)
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color:
                              Color(0xFF1B8F4B),
                        ),
                        SizedBox(
                          width: 7,
                        ),
                        Text(
                          'Verified opportunity',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                Color(
                              0xFF1B8F4B,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (organisation
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 14,
                    ),
                    _buildDetailRow(
                      Icons.business_outlined,
                      organisation,
                    ),
                  ],
                  if (location
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      location,
                    ),
                  ],
                  if (closingDate !=
                      null) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    _buildDetailRow(
                      Icons
                          .calendar_today_outlined,
                      'Closing date: ${_formatDate(closingDate)}',
                    ),
                  ],
                  if (description
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 24,
                    ),
                    const Text(
                      'About this opportunity',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      description,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color:
                            Color(0xFF555555),
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 40,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(
            0xFF666666,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  Color(0xFF555555),
            ),
          ),
        ),
      ],
    );
  }
}
