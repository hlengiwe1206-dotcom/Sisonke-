import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'opportunity_details_screen.dart';
import 'opportunity_preferences_screen.dart';

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

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _opportunities = [];

  Map<String, dynamic>? _preferences;

  String _selectedCategory = 'All';
  String _searchQuery = '';

  bool _recommendedFirst = true;

  final TextEditingController _searchController =
      TextEditingController();

  final List<String> _categories = [
    'All',
    'Jobs',
    'Tenders',
    'Funding',
    'Training',
    'Learnerships',
    'Internships',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadEverything() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadOpportunities(),
        _loadUserPreferences(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'SISONKE OPPORTUNITIES ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load opportunities.\n\n$error';

        _isLoading = false;
      });
    }
  }

  Future<void> _loadOpportunities() async {
    final response = await _supabase
        .from('opportunities')
        .select();

    _opportunities =
        List<Map<String, dynamic>>.from(response);
  }

  Future<void> _loadUserPreferences() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _preferences = null;
      return;
    }

    try {
      final response = await _supabase
          .from('user_opportunity_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      _preferences = response;
    } catch (error) {
      debugPrint(
        'Unable to load opportunity preferences: $error',
      );

      _preferences = null;
    }
  }

  // ==========================================================
  // PERSONALISE BUTTON
  // ==========================================================

  Future<void> _openPreferences() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const OpportunityPreferencesScreen(),
      ),
    );

    // Reload everything when preferences are saved.
    if (result == true) {
      await _loadEverything();
    }
  }

  // ==========================================================
  // VALUE HELPERS
  // ==========================================================

  String _value(
    Map<String, dynamic> opportunity,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = opportunity[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _title(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback: 'Untitled Opportunity',
    );
  }

  String _description(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'description',
        'details',
        'summary',
      ],
      fallback: 'No description available.',
    );
  }

  String _organisation(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'organisation',
        'organization',
        'company',
        'provider',
      ],
      fallback: 'Organisation not specified',
    );
  }

  String _category(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'opportunity_type',
        'category',
        'type',
        'opportunity_category',
      ],
      fallback: 'Other',
    );
  }

  String _province(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      ['province'],
    );
  }

  String _location(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'location',
        'city',
        'province',
      ],
    );
  }

  String _industry(
    Map<String, dynamic> opportunity,
  ) {
    return _value(
      opportunity,
      [
        'industry',
        'sector',
      ],
    );
  }

  // ==========================================================
  // ARRAY HELPERS
  // ==========================================================

  List<String> _stringList(
    dynamic value,
  ) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value
          .map(
            (item) =>
                item.toString().trim(),
          )
          .where(
            (item) => item.isNotEmpty,
          )
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map(
            (item) => item.trim(),
          )
          .where(
            (item) => item.isNotEmpty,
          )
          .toList();
    }

    return [];
  }

  List<String> _opportunityKeywords(
    Map<String, dynamic> opportunity,
  ) {
    return _stringList(
      opportunity['keywords'],
    );
  }

  // ==========================================================
  // CLOSING DATE INTELLIGENCE
  // ==========================================================

  DateTime? _closingDate(
    Map<String, dynamic> opportunity,
  ) {
    final values = [
      opportunity['closing_date'],
      opportunity['deadline'],
      opportunity['closing'],
    ];

    for (final value in values) {
      if (value == null) continue;

      final parsed =
          DateTime.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return null;
  }

  _ClosingStatus _closingStatus(
    Map<String, dynamic> opportunity,
  ) {
    final closingDate =
        _closingDate(opportunity);

    if (closingDate == null) {
      return _ClosingStatus.noDate;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final closingDay = DateTime(
      closingDate.year,
      closingDate.month,
      closingDate.day,
    );

    final difference =
        closingDay.difference(today).inDays;

    if (difference < 0) {
      return _ClosingStatus.closed;
    }

    if (difference == 0) {
      return _ClosingStatus.closingToday;
    }

    if (difference <= 3) {
      return _ClosingStatus.closingSoon;
    }

    if (difference <= 7) {
      return _ClosingStatus.closingThisWeek;
    }

    return _ClosingStatus.open;
  }

  String _closingStatusText(
    Map<String, dynamic> opportunity,
  ) {
    switch (_closingStatus(opportunity)) {
      case _ClosingStatus.closed:
        return 'Closed';

      case _ClosingStatus.closingToday:
        return 'Closing Today';

      case _ClosingStatus.closingSoon:
        return 'Closing Soon';

      case _ClosingStatus.closingThisWeek:
        return 'Closing This Week';

      case _ClosingStatus.open:
        return 'Open';

      case _ClosingStatus.noDate:
        return 'Open';
    }
  }

  Color _closingStatusColor(
    Map<String, dynamic> opportunity,
  ) {
    switch (_closingStatus(opportunity)) {
      case _ClosingStatus.closed:
        return Colors.grey;

      case _ClosingStatus.closingToday:
        return Colors.red;

      case _ClosingStatus.closingSoon:
        return Colors.deepOrange;

      case _ClosingStatus.closingThisWeek:
        return Colors.orange;

      case _ClosingStatus.open:
        return Colors.green;

      case _ClosingStatus.noDate:
        return Colors.blueGrey;
    }
  }

  String _daysRemainingText(
    Map<String, dynamic> opportunity,
  ) {
    final closingDate =
        _closingDate(opportunity);

    if (closingDate == null) {
      return '';
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final closingDay = DateTime(
      closingDate.year,
      closingDate.month,
      closingDate.day,
    );

    final days =
        closingDay.difference(today).inDays;

    if (days < 0) {
      return 'Closed';
    }

    if (days == 0) {
      return 'Closes today';
    }

    if (days == 1) {
      return '1 day remaining';
    }

    return '$days days remaining';
  }

  String _formattedClosingDate(
    Map<String, dynamic> opportunity,
  ) {
    final date =
        _closingDate(opportunity);

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ==========================================================
  // MATCHING ENGINE
  // ==========================================================

  List<String> _preferenceList(
    String key,
  ) {
    if (_preferences == null) {
      return [];
    }

    return _stringList(
      _preferences![key],
    );
  }

  bool get _hasPreferences {
    if (_preferences == null) {
      return false;
    }

    return _preferenceList(
              'preferred_opportunity_types',
            )
            .isNotEmpty ||
        _preferenceList(
              'preferred_provinces',
            )
            .isNotEmpty ||
        _preferenceList(
              'preferred_industries',
            )
            .isNotEmpty ||
        _preferenceList('skills').isNotEmpty ||
        _preferenceList('keywords').isNotEmpty;
  }

  int _matchScore(
    Map<String, dynamic> opportunity,
  ) {
    if (!_hasPreferences) {
      return 0;
    }

    double score = 0;

    // Opportunity type = 30 points
    final preferredTypes =
        _preferenceList(
      'preferred_opportunity_types',
    );

    if (preferredTypes.isNotEmpty) {
      final category =
          _category(opportunity)
              .toLowerCase();

      final matched =
          preferredTypes.any(
        (item) =>
            category.contains(
              item.toLowerCase(),
            ) ||
            item.toLowerCase().contains(
              category,
            ),
      );

      if (matched) {
        score += 30;
      }
    }

    // Province = 20 points
    final preferredProvinces =
        _preferenceList(
      'preferred_provinces',
    );

    if (preferredProvinces.isNotEmpty) {
      final province =
          _province(opportunity)
              .toLowerCase();

      final matched =
          preferredProvinces.any(
        (item) =>
            province.contains(
              item.toLowerCase(),
            ) ||
            item.toLowerCase().contains(
              province,
            ),
      );

      if (matched && province.isNotEmpty) {
        score += 20;
      }
    }

    // Industry = 20 points
    final preferredIndustries =
        _preferenceList(
      'preferred_industries',
    );

    if (preferredIndustries.isNotEmpty) {
      final industry =
          _industry(opportunity)
              .toLowerCase();

      final matched =
          preferredIndustries.any(
        (item) =>
            industry.contains(
              item.toLowerCase(),
            ) ||
            item.toLowerCase().contains(
              industry,
            ),
      );

      if (matched && industry.isNotEmpty) {
        score += 20;
      }
    }

    // Skills + keywords = 30 points
    final userTerms = [
      ..._preferenceList('skills'),
      ..._preferenceList('keywords'),
    ]
        .map(
          (item) => item.toLowerCase(),
        )
        .toSet()
        .toList();

    if (userTerms.isNotEmpty) {
      final opportunityText = [
        _title(opportunity),
        _description(opportunity),
        _organisation(opportunity),
        _industry(opportunity),
        ..._opportunityKeywords(opportunity),
      ].join(' ').toLowerCase();

      var matches = 0;

      for (final term in userTerms) {
        if (term.isNotEmpty &&
            opportunityText.contains(term)) {
          matches++;
        }
      }

      if (matches > 0) {
        score +=
            (matches / userTerms.length) *
                30;
      }
    }

    return score
        .round()
        .clamp(0, 100);
  }

  String _matchLabel(int score) {
    if (!_hasPreferences) {
      return '';
    }

    if (score >= 80) {
      return 'Highly Recommended';
    }

    if (score >= 60) {
      return 'Good Match';
    }

    if (score >= 40) {
      return 'Potential Match';
    }

    return 'Low Match';
  }

  Color _matchColor(int score) {
    if (score >= 80) {
      return Colors.green;
    }

    if (score >= 60) {
      return Colors.blue;
    }

    if (score >= 40) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  // ==========================================================
  // FILTERING
  // ==========================================================

  List<Map<String, dynamic>>
      get _filteredOpportunities {
    var results =
        List<Map<String, dynamic>>.from(
      _opportunities,
    );

    if (_selectedCategory != 'All') {
      results =
          results.where((opportunity) {
        return _category(opportunity)
            .toLowerCase()
            .contains(
              _selectedCategory
                  .toLowerCase(),
            );
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query =
          _searchQuery.toLowerCase();

      results =
          results.where((opportunity) {
        final text = [
          _title(opportunity),
          _description(opportunity),
          _organisation(opportunity),
          _category(opportunity),
          _location(opportunity),
          _province(opportunity),
          _industry(opportunity),
          ..._opportunityKeywords(opportunity),
        ].join(' ').toLowerCase();

        return text.contains(query);
      }).toList();
    }

    if (_recommendedFirst &&
        _hasPreferences) {
      results.sort((a, b) {
        return _matchScore(b)
            .compareTo(
          _matchScore(a),
        );
      });
    } else {
      results.sort((a, b) {
        final aDate =
            _closingDate(a);

        final bDate =
            _closingDate(b);

        if (aDate == null &&
            bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return aDate.compareTo(bDate);
      });
    }

    return results;
  }

  // ==========================================================
  // CATEGORY ICON
  // ==========================================================

  IconData _categoryIcon(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('job')) {
      return Icons.work_outline;
    }

    if (value.contains('tender')) {
      return Icons.description_outlined;
    }

    if (value.contains('fund')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (value.contains('train')) {
      return Icons.school_outlined;
    }

    if (value.contains('learn')) {
      return Icons.menu_book_outlined;
    }

    if (value.contains('intern')) {
      return Icons.business_center_outlined;
    }

    return Icons.campaign_outlined;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final opportunities =
        _filteredOpportunities;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Opportunities'),

        centerTitle: true,

        actions: [
          // PERSONALISE BUTTON
          TextButton.icon(
            onPressed: _openPreferences,
            icon: const Icon(
              Icons.auto_awesome,
              size: 18,
            ),
            label: const Text(
              'Personalise',
            ),
          ),

          IconButton(
            tooltip: _recommendedFirst
                ? 'Recommended first'
                : 'Sort by closing date',

            icon: Icon(
              _recommendedFirst
                  ? Icons.auto_awesome
                  : Icons.schedule,
            ),

            onPressed: () {
              setState(() {
                _recommendedFirst =
                    !_recommendedFirst;
              });
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadEverything,
        child: _buildBody(opportunities),
      ),
    );
  }

  Widget _buildBody(
    List<Map<String, dynamic>>
        opportunities,
  ) {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildHeader(),

        _buildSearch(),

        _buildCategoryFilters(),

        if (_hasPreferences)
          _buildRecommendationInfo(),

        Expanded(
          child: opportunities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    30,
                  ),

                  itemCount:
                      opportunities.length,

                  itemBuilder:
                      (context, index) {
                    return _buildOpportunityCard(
                      opportunities[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final count =
        _filteredOpportunities.length;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        16,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Find your next\nopportunity',
            style: TextStyle(
              fontSize: 36,
              fontWeight:
                  FontWeight.w800,
              height: 1.08,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Jobs, tenders, funding, training, '
            'learnerships and more.',
            style: TextStyle(
              fontSize: 16,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$count opportunities found',
            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: TextField(
        controller:
            _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText:
              'Search opportunities...',
          prefixIcon:
              const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        itemCount:
            _categories.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 10),
        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          return ChoiceChip(
            label: Text(category),
            selected:
                category ==
                    _selectedCategory,
            onSelected: (_) {
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

  Widget _buildRecommendationInfo() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        12,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.08),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _recommendedFirst
                  ? 'Opportunities are ranked using your personal preferences.'
                  : 'Tap the sparkle icon to return to personalised recommendations.',
              style:
                  const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(
    Map<String, dynamic> opportunity,
  ) {
    final category =
        _category(opportunity);

    final matchScore =
        _matchScore(opportunity);

    final closingStatus =
        _closingStatus(opportunity);

    final isClosed =
        closingStatus ==
            _ClosingStatus.closed;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),

        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OpportunityDetailsScreen(
                opportunity: opportunity,
              ),
            ),
          );
        },

        child: Padding(
          padding:
              const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(
                                0.10,
                              ),
                    ),
                    child: Icon(
                      _categoryIcon(
                        category,
                      ),
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
                            color:
                                Colors.grey
                                    .shade600,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          _organisation(
                            opportunity,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                _title(opportunity),
                style:
                    const TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _description(opportunity),
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusBadge(
                    text:
                        _closingStatusText(
                      opportunity,
                    ),
                    color:
                        _closingStatusColor(
                      opportunity,
                    ),
                  ),

                  if (_hasPreferences)
                    _buildStatusBadge(
                      text:
                          '$matchScore% Match',
                      color:
                          _matchColor(
                        matchScore,
                      ),
                    ),
                ],
              ),

              if (_daysRemainingText(
                    opportunity,
                  )
                  .isNotEmpty) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      isClosed
                          ? Icons
                              .cancel_outlined
                          : Icons
                              .schedule_outlined,
                      size: 17,
                      color:
                          _closingStatusColor(
                        opportunity,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _daysRemainingText(
                        opportunity,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _closingStatusColor(
                          opportunity,
                        ),
                      ),
                    ),

                    if (_formattedClosingDate(
                          opportunity,
                        )
                        .isNotEmpty) ...[
                      const SizedBox(width: 10),

                      Text(
                        '• ${_formattedClosingDate(opportunity)}',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey
                                  .shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (_location(opportunity)
                  .isNotEmpty) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons
                          .location_on_outlined,
                      size: 17,
                      color:
                          Colors.grey
                              .shade600,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        _location(
                          opportunity,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey
                                  .shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_hasPreferences &&
                  matchScore >= 60) ...[
                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color:
                          _matchColor(
                        matchScore,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _matchLabel(
                        matchScore,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            _matchColor(
                          matchScore,
                        ),
                      ),
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

  Widget _buildStatusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch =
        _searchQuery.isNotEmpty;

    final hasCategoryFilter =
        _selectedCategory != 'All';

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 420,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .travel_explore_outlined,
                    size: 78,
                    color:
                        Colors.grey.shade400,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'No opportunities found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    hasSearch ||
                            hasCategoryFilter
                        ? 'Try changing your search or category filter.'
                        : 'New opportunities will appear here when they are published.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  if (hasSearch ||
                      hasCategoryFilter) ...[
                    const SizedBox(height: 22),

                    OutlinedButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                          _selectedCategory =
                              'All';
                        });
                      },
                      child:
                          const Text(
                        'CLEAR FILTERS',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 100),

        Icon(
          Icons.error_outline,
          size: 72,
          color:
              Colors.red.shade400,
        ),

        const SizedBox(height: 24),

        const Text(
          'Unable to load opportunities',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _errorMessage ?? '',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 28),

        Center(
          child:
              ElevatedButton.icon(
            onPressed:
                _loadEverything,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('TRY AGAIN'),
          ),
        ),
      ],
    );
  }
}

enum _ClosingStatus {
  closed,
  closingToday,
  closingSoon,
  closingThisWeek,
  open,
  noDate,
}
