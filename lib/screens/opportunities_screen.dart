import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'opportunity_details_screen.dart';
import 'saved_opportunities_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState
    extends State<OpportunitiesScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  late Future<List<Map<String, dynamic>>>
      _opportunitiesFuture;

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Jobs',
    'Tenders',
    'Funding',
    'Learnerships',
    'Training',
    'Business',
    'Education',
  ];

  @override
  void initState() {
    super.initState();

    _opportunitiesFuture =
        _loadOpportunities();
  }

  Future<List<Map<String, dynamic>>>
      _loadOpportunities() async {
    try {
      final response = await _supabase
          .from('opportunities')
          .select()
          .eq('is_published', true)
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(
        response,
      );
    } catch (error) {
      throw Exception(
        'Unable to load opportunities: $error',
      );
    }
  }

  Future<void> _refreshOpportunities() async {
    setState(() {
      _opportunitiesFuture =
          _loadOpportunities();
    });

    await _opportunitiesFuture;
  }

  String _getString(
    Map<String, dynamic> opportunity,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value =
          opportunity[key];

      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return fallback;
  }

  bool _getBool(
    Map<String, dynamic> opportunity,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value =
          opportunity[key];

      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      final text =
          value
              .toString()
              .trim()
              .toLowerCase();

      return text == 'true' ||
          text == '1' ||
          text == 'yes';
    }

    return fallback;
  }

  String _title(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback:
          'Untitled Opportunity',
    );
  }

  String _description(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'description',
        'summary',
        'details',
      ],
    );
  }

  String _category(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'category',
        'type',
      ],
      fallback:
          'Opportunity',
    );
  }

  String _organisation(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'organisation',
        'organization',
        'company',
        'provider',
        'source',
      ],
    );
  }

  String _location(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'location',
        'province',
        'city',
      ],
    );
  }

  DateTime? _closingDate(
    Map<String, dynamic> opportunity,
  ) {
    const possibleKeys = [
      'closing_date',
      'deadline',
      'application_deadline',
      'expiry_date',
    ];

    for (final key in possibleKeys) {
      final value =
          opportunity[key];

      if (value == null) {
        continue;
      }

      final date =
          DateTime.tryParse(
        value.toString(),
      );

      if (date != null) {
        return date.toLocal();
      }
    }

    return null;
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  List<Map<String, dynamic>>
      _filteredOpportunities(
    List<Map<String, dynamic>> opportunities,
  ) {
    if (_selectedCategory == 'All') {
      return opportunities;
    }

    return opportunities.where(
      (opportunity) {
        final category =
            _category(opportunity)
                .toLowerCase();

        final selected =
            _selectedCategory
                .toLowerCase();

        if (selected == 'learnerships') {
          return category.contains(
                'learnership',
              ) ||
              category.contains(
                'internship',
              ) ||
              category.contains(
                'apprenticeship',
              );
        }

        return category == selected ||
            category.contains(
              selected.substring(
                0,
                selected.length - 1,
              ),
            );
      },
    ).toList();
  }

  IconData _categoryIcon(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('tender')) {
      return Icons.description_outlined;
    }

    if (value.contains('job') ||
        value.contains('employment')) {
      return Icons.work_outline;
    }

    if (value.contains('fund') ||
        value.contains('grant')) {
      return Icons.account_balance_outlined;
    }

    if (value.contains('learnership') ||
        value.contains('internship') ||
        value.contains('apprenticeship')) {
      return Icons.school_outlined;
    }

    if (value.contains('training')) {
      return Icons.menu_book_outlined;
    }

    if (value.contains('business')) {
      return Icons.business_center_outlined;
    }

    if (value.contains('education')) {
      return Icons.auto_stories_outlined;
    }

    return Icons.campaign_outlined;
  }

  Color _categoryColor(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('tender')) {
      return const Color(0xFF7B1FA2);
    }

    if (value.contains('job') ||
        value.contains('employment')) {
      return const Color(0xFF1565C0);
    }

    if (value.contains('fund') ||
        value.contains('grant')) {
      return const Color(0xFF2E7D32);
    }

    if (value.contains('learnership') ||
        value.contains('internship') ||
        value.contains('apprenticeship')) {
      return const Color(0xFFF57C00);
    }

    if (value.contains('training')) {
      return const Color(0xFF00838F);
    }

    if (value.contains('business')) {
      return const Color(0xFF5D4037);
    }

    if (value.contains('education')) {
      return const Color(0xFFC62828);
    }

    return const Color(0xFF37474F);
  }

  Future<void> _openOpportunity(
    Map<String, dynamic> opportunity,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            OpportunityDetailsScreen(
          opportunity:
              opportunity,
        ),
      ),
    );

    if (mounted) {
      _refreshOpportunities();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7F4),

      appBar: AppBar(
        title:
            const Text('Opportunities'),

        backgroundColor:
            const Color(0xFFF8F7F4),

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        actions: [
          IconButton(
            tooltip:
                'Saved Opportunities',
            icon: const Icon(
              Icons.bookmark_outline,
            ),
            onPressed: () async {
              await Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) =>
                      const SavedOpportunitiesScreen(),
                ),
              );
            },
          ),

          IconButton(
            tooltip:
                'Refresh',
            icon:
                const Icon(Icons.refresh),
            onPressed:
                _refreshOpportunities,
          ),
        ],
      ),

      body: Column(
        children: [
          _buildHeader(),

          _buildCategoryFilter(),

          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  _refreshOpportunities,

              child: FutureBuilder<
                  List<Map<String, dynamic>>>(
                future:
                    _opportunitiesFuture,

                builder:
                    (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(
                      snapshot.error.toString(),
                    );
                  }

                  final opportunities =
                      _filteredOpportunities(
                    snapshot.data ?? [],
                  );

                  if (opportunities.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      30,
                    ),

                    itemCount:
                        opportunities.length,

                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 12,
                    ),

                    itemBuilder:
                        (context, index) {
                      return _buildOpportunityCard(
                        opportunities[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),

      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Find your next opportunity',
            style: TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF1F232B),
            ),
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'Jobs, tenders, funding, learnerships, training and more.',
            style: TextStyle(
              fontSize: 14,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 58,

      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),

        itemCount:
            _categories.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),

        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          final selected =
              category ==
                  _selectedCategory;

          return ChoiceChip(
            label:
                Text(category),

            selected:
                selected,

            selectedColor:
                const Color(
              0xFF1F232B,
            ),

            backgroundColor:
                Colors.white,

            side:
                BorderSide.none,

            labelStyle:
                TextStyle(
              fontWeight:
                  FontWeight.w600,

              color:
                  selected
                      ? Colors.white
                      : const Color(
                          0xFF4B5563,
                        ),
            ),

            onSelected:
                (value) {
              if (!value) {
                return;
              }

              setState(() {
                _selectedCategory =
                    category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildOpportunityCard(
    Map<String, dynamic> opportunity,
  ) {
    final title =
        _title(opportunity);

    final description =
        _description(opportunity);

    final category =
        _category(opportunity);

    final organisation =
        _organisation(opportunity);

    final location =
        _location(opportunity);

    final closingDate =
        _closingDate(opportunity);

    final verified =
        _getBool(
      opportunity,
      [
        'is_verified',
        'verified',
      ],
    );

    final color =
        _categoryColor(category);

    return Card(
      elevation: 0,

      color:
          Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        side:
            const BorderSide(
          color:
              Color(0xFFEAEAEA),
        ),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        onTap: () =>
            _openOpportunity(
          opportunity,
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration:
                        BoxDecoration(
                      color:
                          color.withOpacity(
                        0.12,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: Icon(
                      _categoryIcon(
                        category,
                      ),

                      color:
                          color,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          category.toUpperCase(),

                          style:
                              TextStyle(
                            fontSize: 11,

                            letterSpacing:
                                0.8,

                            fontWeight:
                                FontWeight
                                    .w800,

                            color:
                                color,
                          ),
                        ),

                        if (verified)
                          const Padding(
                            padding:
                                EdgeInsets.only(
                              top: 3,
                            ),

                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .verified,
                                  size: 14,
                                  color:
                                      Color(
                                    0xFF198754,
                                  ),
                                ),

                                SizedBox(
                                  width: 4,
                                ),

                                Text(
                                  'VERIFIED',
                                  style:
                                      TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    color:
                                        Color(
                                      0xFF198754,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 16,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                title,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  fontSize: 19,

                  height: 1.25,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(0xFF1F232B),
                ),
              ),

              if (organisation
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 6,
                ),

                Text(
                  organisation,

                  style:
                      const TextStyle(
                    fontSize: 14,

                    fontWeight:
                        FontWeight.w600,

                    color:
                        Color(0xFF6B7280),
                  ),
                ),
              ],

              if (description
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 10,
                ),

                Text(
                  description,

                  maxLines: 3,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 14,

                    height: 1.45,

                    color:
                        Color(0xFF6B7280),
                  ),
                ),
              ],

              if (location.isNotEmpty ||
                  closingDate != null) ...[
                const SizedBox(
                  height: 14,
                ),

                Wrap(
                  spacing: 14,
                  runSpacing: 8,

                  children: [
                    if (location
                        .isNotEmpty)
                      _infoItem(
                        Icons
                            .location_on_outlined,
                        location,
                      ),

                    if (closingDate !=
                        null)
                      _infoItem(
                        Icons
                            .calendar_today_outlined,
                        'Closes ${_formatDate(closingDate)}',
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

  Widget _infoItem(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,

      children: [
        Icon(
          icon,

          size: 15,

          color:
              const Color(
            0xFF9CA3AF,
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        Text(
          text,

          style:
              const TextStyle(
            fontSize: 12,
            color:
                Color(0xFF6B7280),
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
        SizedBox(
          height: 120,
        ),

        Icon(
          Icons
              .search_off_outlined,

          size: 64,

          color:
              Color(0xFF9CA3AF),
        ),

        SizedBox(
          height: 18,
        ),

        Center(
          child: Text(
            'No opportunities found',

            style:
                TextStyle(
              fontSize: 19,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        SizedBox(
          height: 8,
        ),

        Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 40,
          ),

          child: Text(
            'New opportunities will appear here as they are published.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Color(
                0xFF6B7280,
              ),
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
          const EdgeInsets.all(
        24,
      ),

      children: [
        const SizedBox(
          height: 100,
        ),

        const Icon(
          Icons
              .cloud_off_outlined,

          size: 64,

          color:
              Color(0xFF9CA3AF),
        ),

        const SizedBox(
          height: 18,
        ),

        const Center(
          child: Text(
            'Unable to load opportunities',

            style:
                TextStyle(
              fontSize: 19,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Text(
          error,

          textAlign:
              TextAlign.center,

          style:
              const TextStyle(
            fontSize: 12,

            color:
                Color(
              0xFF9CA3AF,
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Center(
          child:
              ElevatedButton.icon(
            onPressed:
                _refreshOpportunities,

            icon:
                const Icon(
              Icons.refresh,
            ),

            label:
                const Text(
              'Try Again',
            ),
          ),
        ),
      ],
    );
  }
}
