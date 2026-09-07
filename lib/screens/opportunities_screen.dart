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
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _opportunities = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';

  RealtimeChannel? _opportunitiesChannel;

  @override
  void initState() {
    super.initState();

    _loadOpportunities();
    _listenForOpportunityChanges();
  }

  @override
  void dispose() {
    _searchController.dispose();

    if (_opportunitiesChannel != null) {
      _supabase.removeChannel(
        _opportunitiesChannel!,
      );
    }

    super.dispose();
  }

  Future<void> _loadOpportunities() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('opportunities')
          .select();

      final opportunities =
          List<Map<String, dynamic>>.from(
        response,
      );

      opportunities.sort((a, b) {
        final aDate = _getDate(a);
        final bDate = _getDate(b);

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _opportunities = opportunities;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _listenForOpportunityChanges() {
    _opportunitiesChannel = _supabase
        .channel('opportunities-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'opportunities',
          callback: (payload) {
            _loadOpportunities();
          },
        )
        .subscribe();
  }

  String _getString(
    Map<String, dynamic> opportunity,
    List<String> possibleColumns, {
    String fallback = '',
  }) {
    for (final column in possibleColumns) {
      final value = opportunity[column];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  DateTime? _getDate(
    Map<String, dynamic> opportunity,
  ) {
    final possibleColumns = [
      'created_at',
      'published_at',
      'updated_at',
      'closing_date',
      'deadline',
      'application_deadline',
      'expiry_date',
    ];

    for (final column in possibleColumns) {
      final value = opportunity[column];

      if (value == null) continue;

      try {
        return DateTime.parse(value.toString());
      } catch (_) {}
    }

    return null;
  }

  DateTime? _getClosingDate(
    Map<String, dynamic> opportunity,
  ) {
    final possibleColumns = [
      'closing_date',
      'deadline',
      'application_deadline',
      'expiry_date',
    ];

    for (final column in possibleColumns) {
      final value = opportunity[column];

      if (value == null) continue;

      try {
        return DateTime.parse(value.toString());
      } catch (_) {}
    }

    return null;
  }

  String _getCategory(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'category',
        'type',
        'opportunity_category',
        'opportunity_type',
      ],
      fallback: 'Other',
    );
  }

  String _getTitle(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback: 'Untitled Opportunity',
    );
  }

  String _getDescription(
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

  String _getOrganisation(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'organisation',
        'organization',
        'company',
        'provider',
      ],
    );
  }

  String _getLocation(
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

  String _getLink(
    Map<String, dynamic> opportunity,
  ) {
    return _getString(
      opportunity,
      [
        'link',
        'url',
        'application_url',
        'source_url',
      ],
    );
  }

  List<String> get _categories {
    final categories = <String>{};

    for (final opportunity in _opportunities) {
      final category =
          _getCategory(opportunity);

      if (category.isNotEmpty &&
          category != 'Other') {
        categories.add(category);
      }
    }

    final sortedCategories =
        categories.toList()
          ..sort(
            (a, b) => a.toLowerCase().compareTo(
              b.toLowerCase(),
            ),
          );

    return [
      'All',
      ...sortedCategories,
    ];
  }

  List<Map<String, dynamic>>
      get _filteredOpportunities {
    final searchText =
        _searchController.text
            .trim()
            .toLowerCase();

    return _opportunities.where(
      (opportunity) {
        final title =
            _getTitle(opportunity)
                .toLowerCase();

        final description =
            _getDescription(opportunity)
                .toLowerCase();

        final organisation =
            _getOrganisation(opportunity)
                .toLowerCase();

        final location =
            _getLocation(opportunity)
                .toLowerCase();

        final category =
            _getCategory(opportunity)
                .toLowerCase();

        final matchesSearch =
            searchText.isEmpty ||
                title.contains(searchText) ||
                description.contains(
                  searchText,
                ) ||
                organisation.contains(
                  searchText,
                ) ||
                location.contains(
                  searchText,
                ) ||
                category.contains(
                  searchText,
                );

        final matchesCategory =
            _selectedCategory == 'All' ||
                _getCategory(opportunity)
                        .toLowerCase() ==
                    _selectedCategory
                        .toLowerCase();

        return matchesSearch &&
            matchesCategory;
      },
    ).toList();
  }

  Color _categoryColor(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'tender':
      case 'tenders':
      case 'procurement':
        return const Color(0xFFF59E0B);

      case 'employment':
      case 'job':
      case 'jobs':
      case 'vacancy':
      case 'vacancies':
        return const Color(0xFF2563EB);

      case 'funding':
      case 'grant':
      case 'grants':
      case 'finance':
        return const Color(0xFF16A34A);

      case 'learnership':
      case 'learnerships':
      case 'internship':
      case 'internships':
      case 'education':
      case 'training':
        return const Color(0xFF9333EA);

      case 'business':
      case 'opportunity':
        return const Color(0xFFEA580C);

      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _categoryIcon(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'tender':
      case 'tenders':
      case 'procurement':
        return Icons.description_outlined;

      case 'employment':
      case 'job':
      case 'jobs':
      case 'vacancy':
      case 'vacancies':
        return Icons.work_outline;

      case 'funding':
      case 'grant':
      case 'grants':
      case 'finance':
        return Icons.account_balance_outlined;

      case 'learnership':
      case 'learnerships':
      case 'internship':
      case 'internships':
      case 'education':
      case 'training':
        return Icons.school_outlined;

      case 'business':
      case 'opportunity':
        return Icons.lightbulb_outline;

      default:
        return Icons.campaign_outlined;
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year = date.year;

    return '$day/$month/$year';
  }

  int? _daysRemaining(
    DateTime closingDate,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final closing = DateTime(
      closingDate.year,
      closingDate.month,
      closingDate.day,
    );

    return closing
        .difference(today)
        .inDays;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7F4),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOpportunities,

          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            slivers: [

              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  16,
                ),

                sliver: SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
              ),

              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                sliver: SliverToBoxAdapter(
                  child: _buildSearchField(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 18),
              ),

              SliverToBoxAdapter(
                child: _buildCategoryFilters(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 22),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,

                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )

              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,

                  child: _buildErrorState(),
                )

              else if (_filteredOpportunities
                  .isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,

                  child: _buildEmptyState(),
                )

              else
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    30,
                  ),

                  sliver: SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (
                        context,
                        index,
                      ) {
                        final opportunity =
                            _filteredOpportunities[
                                index
                            ];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),

                          child:
                              _buildOpportunityCard(
                            opportunity,
                          ),
                        );
                      },

                      childCount:
                          _filteredOpportunities
                              .length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final count =
        _filteredOpportunities.length;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(
          'Opportunities',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F232B),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Discover opportunities to work, learn, grow and build.',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
          ),

          child: Row(
            children: [

              const Icon(
                Icons.explore_outlined,
                color: Color(0xFF1F232B),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  '$count opportunity${count == 1 ? '' : 'ies'} available',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(0xFF1F232B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,

      onChanged: (_) {
        setState(() {});
      },

      decoration: InputDecoration(
        hintText:
            'Search opportunities...',

        prefixIcon: const Icon(
          Icons.search,
        ),

        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                    ),

                    onPressed: () {
                      _searchController.clear();

                      setState(() {});
                    },
                  )
                : null,

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),

          borderSide: const BorderSide(
            color: Color(0xFF1F232B),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = _categories;

    return SizedBox(
      height: 46,

      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),

        itemCount:
            categories.length,

        separatorBuilder:
            (context, index) {
          return const SizedBox(
            width: 10,
          );
        },

        itemBuilder:
            (context, index) {
          final category =
              categories[index];

          final isSelected =
              category ==
                  _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory =
                    category;
              });
            },

            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),

              decoration:
                  BoxDecoration(
                color: isSelected
                    ? const Color(
                        0xFF1F232B,
                      )
                    : Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                border:
                    Border.all(
                  color: isSelected
                      ? const Color(
                          0xFF1F232B,
                        )
                      : const Color(
                          0xFFE5E7EB,
                        ),
                ),
              ),

              alignment:
                  Alignment.center,

              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(
                          0xFF374151,
                        ),

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpportunityCard(
    Map<String, dynamic> opportunity,
  ) {
    final title =
        _getTitle(opportunity);

    final description =
        _getDescription(opportunity);

    final organisation =
        _getOrganisation(opportunity);

    final location =
        _getLocation(opportunity);

    final category =
        _getCategory(opportunity);

    final closingDate =
        _getClosingDate(opportunity);

    final categoryColor =
        _categoryColor(category);

    final categoryIcon =
        _categoryIcon(category);

    return InkWell(
      borderRadius:
          BorderRadius.circular(24),

      onTap: () {
        _showOpportunityDetails(
          opportunity,
        );
      },

      child: Container(
        padding:
            const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(24),

          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(
              children: [

                Container(
                  width: 52,
                  height: 52,

                  decoration:
                      BoxDecoration(
                    color: categoryColor
                        .withValues(
                      alpha: 0.12,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              categoryColor,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        organisation.isEmpty
                            ? 'Opportunity'
                            : organisation,

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 15,
                          color:
                              Color(0xFF6B7280),
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(
                    0xFF9CA3AF,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF1F232B),
              ),
            ),

            if (description.isNotEmpty) ...[

              const SizedBox(
                height: 10,
              ),

              Text(
                description,
                maxLines: 3,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color:
                      Color(0xFF6B7280),
                ),
              ),
            ],

            if (location.isNotEmpty ||
                closingDate != null) ...[

              const SizedBox(
                height: 18,
              ),

              const Divider(
                color: Color(
                  0xFFF0F0F0,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [

                  if (location.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [

                          const Icon(
                            Icons
                                .location_on_outlined,
                            size: 18,
                            color:
                                Color(
                              0xFF6B7280,
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          Expanded(
                            child: Text(
                              location,

                              maxLines: 1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontSize:
                                    14,
                                color:
                                    Color(
                                  0xFF6B7280,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (closingDate != null)
                    _buildClosingBadge(
                      closingDate,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClosingBadge(
    DateTime closingDate,
  ) {
    final days =
        _daysRemaining(closingDate);

    Color backgroundColor =
        const Color(0xFFF3F4F6);

    Color textColor =
        const Color(0xFF374151);

    String text =
        'Closes ${_formatDate(closingDate)}';

    if (days != null) {
      if (days < 0) {
        backgroundColor =
            const Color(0xFFFEE2E2);

        textColor =
            const Color(0xFFDC2626);

        text = 'Closed';
      } else if (days == 0) {
        backgroundColor =
            const Color(0xFFFFEDD5);

        textColor =
            const Color(0xFFEA580C);

        text = 'Closes today';
      } else if (days <= 3) {
        backgroundColor =
            const Color(0xFFFFEDD5);

        textColor =
            const Color(0xFFEA580C);

        text =
            '$days day${days == 1 ? '' : 's'} left';
      } else {
        text =
            'Closes ${_formatDate(closingDate)}';
      }
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius:
            BorderRadius.circular(10),
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
              ),

              child: const Icon(
                Icons.search_off_outlined,
                size: 42,
                color:
                    Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No opportunities found',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF1F232B),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Try changing your search or selecting a different category.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color:
                    Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.error_outline,
              size: 52,
              color: Color(
                0xFFE9322A,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load opportunities',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF1F232B),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton(
              onPressed:
                  _loadOpportunities,

              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOpportunityDetails(
    Map<String, dynamic> opportunity,
  ) {
    final title =
        _getTitle(opportunity);

    final description =
        _getDescription(opportunity);

    final organisation =
        _getOrganisation(opportunity);

    final location =
        _getLocation(opportunity);

    final category =
        _getCategory(opportunity);

    final closingDate =
        _getClosingDate(opportunity);

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,

          builder:
              (context, scrollController) {
            return Container(
              decoration:
                  const BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(
                    30,
                  ),
                ),
              ),

              child: ListView(
                controller:
                    scrollController,

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                children: [

                  Center(
                    child: Container(
                      width: 50,
                      height: 5,

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFD1D5DB,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
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
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Color(
                        0xFF1F232B,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  if (organisation.isNotEmpty)
                    _detailRow(
                      Icons.business_outlined,
                      organisation,
                    ),

                  if (location.isNotEmpty)
                    _detailRow(
                      Icons
                          .location_on_outlined,
                      location,
                    ),

                  if (closingDate != null)
                    _detailRow(
                      Icons
                          .calendar_today_outlined,
                      'Closing date: ${_formatDate(closingDate)}',
                    ),

                  if (description.isNotEmpty) ...[

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'About this opportunity',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF1F232B,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      description,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color:
                            Color(
                          0xFF4B5563,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 21,
            color:
                const Color(0xFF6B7280),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color:
                    Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
