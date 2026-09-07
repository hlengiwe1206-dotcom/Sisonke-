import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _opportunities = [];

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Jobs',
    'Tenders',
    'Funding',
    'Training',
    'Learnerships',
  ];

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  Future<void> _loadOpportunities() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('SISONKE: Loading opportunities from Supabase...');

      final response = await _supabase
          .from('opportunities')
          .select();

      final opportunities =
          List<Map<String, dynamic>>.from(response);

      debugPrint(
        'SISONKE: ${opportunities.length} opportunities loaded.',
      );

      if (!mounted) return;

      setState(() {
        _opportunities = opportunities;
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE SUPABASE ERROR: '
        '${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load opportunities.\n\n'
            '${error.message}';

        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'SISONKE UNKNOWN ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something went wrong while loading opportunities.\n\n'
            '$error';

        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOpportunities {
    if (_selectedCategory == 'All') {
      return _opportunities;
    }

    return _opportunities.where((opportunity) {
      final category = _readCategory(opportunity);

      return category
          .toLowerCase()
          .contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  String _readCategory(
    Map<String, dynamic> opportunity,
  ) {
    final possibleValues = [
      opportunity['category'],
      opportunity['type'],
      opportunity['opportunity_type'],
      opportunity['opportunity_category'],
    ];

    for (final value in possibleValues) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return 'Other';
  }

  String _readTitle(
    Map<String, dynamic> opportunity,
  ) {
    return _firstAvailableValue(
      opportunity,
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback: 'Untitled Opportunity',
    );
  }

  String _readDescription(
    Map<String, dynamic> opportunity,
  ) {
    return _firstAvailableValue(
      opportunity,
      [
        'description',
        'details',
        'summary',
      ],
      fallback: 'No description available.',
    );
  }

  String _readOrganisation(
    Map<String, dynamic> opportunity,
  ) {
    return _firstAvailableValue(
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

  String _readLocation(
    Map<String, dynamic> opportunity,
  ) {
    return _firstAvailableValue(
      opportunity,
      [
        'location',
        'province',
        'city',
      ],
      fallback: '',
    );
  }

  String _firstAvailableValue(
    Map<String, dynamic> opportunity,
    List<String> keys, {
    required String fallback,
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

  IconData _categoryIcon(
    String category,
  ) {
    final value = category.toLowerCase();

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

    return Icons.campaign_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final filteredOpportunities =
        _filteredOpportunities;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Opportunities',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadOpportunities,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip: 'Refresh opportunities',
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadOpportunities,

        child: _buildBody(
          filteredOpportunities,
        ),
      ),
    );
  }

  Widget _buildBody(
    List<Map<String, dynamic>>
        filteredOpportunities,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildHeader(),

        _buildCategoryFilters(),

        Expanded(
          child: filteredOpportunities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    24,
                  ),
                  itemCount:
                      filteredOpportunities.length,
                  itemBuilder:
                      (context, index) {
                    final opportunity =
                        filteredOpportunities[index];

                    return _OpportunityCard(
                      opportunity: opportunity,
                      title:
                          _readTitle(opportunity),
                      description:
                          _readDescription(
                        opportunity,
                      ),
                      organisation:
                          _readOrganisation(
                        opportunity,
                      ),
                      location:
                          _readLocation(
                        opportunity,
                      ),
                      category:
                          _readCategory(
                        opportunity,
                      ),
                      icon: _categoryIcon(
                        _readCategory(
                          opportunity,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your next\nopportunity',
            style: TextStyle(
              fontSize: 42,
              fontWeight:
                  FontWeight.w700,
              height: 1.05,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            'Jobs, tenders, funding, learnerships, '
            'training and more.',
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '${_opportunities.length} opportunity'
            '${_opportunities.length == 1 ? '' : 'ies'} available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
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
          vertical: 8,
        ),
        itemCount:
            _categories.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 12),
        itemBuilder:
            (context, index) {
          final category =
              _categories[index];

          final isSelected =
              category ==
                  _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
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

  Widget _buildEmptyState() {
    final hasData =
        _opportunities.isNotEmpty;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 380,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    hasData
                        ? Icons.filter_alt_off_outlined
                        : Icons.travel_explore,
                    size: 72,
                    color:
                        Colors.grey.shade400,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Text(
                    hasData
                        ? 'No matching opportunities'
                        : 'No opportunities found',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.w600,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    hasData
                        ? 'Try selecting a different category.'
                        : 'New opportunities will appear here as they are published.',
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          Colors.grey.shade600,
                    ),
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  OutlinedButton.icon(
                    onPressed:
                        _loadOpportunities,
                    icon: const Icon(
                      Icons.refresh,
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
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.all(24),
      children: [
        const SizedBox(
          height: 100,
        ),

        Icon(
          Icons.error_outline,
          size: 72,
          color: Colors.red.shade400,
        ),

        const SizedBox(
          height: 24,
        ),

        const Text(
          'Unable to load opportunities',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Text(
          _errorMessage ??
              'An unknown error occurred.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(
          height: 28,
        ),

        Center(
          child: ElevatedButton.icon(
            onPressed:
                _loadOpportunities,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Map<String, dynamic>
      opportunity;

  final String title;
  final String description;
  final String organisation;
  final String location;
  final String category;
  final IconData icon;

  const _OpportunityCard({
    required this.opportunity,
    required this.title,
    required this.description,
    required this.organisation,
    required this.location,
    required this.category,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),

        onTap: () {
          Navigator.pushNamed(
            context,
            '/opportunity-details',
            arguments: opportunity,
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .primary
                          .withOpacity(0.10),
                    ),

                    child: Icon(
                      icon,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

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
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          organisation,
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

              const SizedBox(
                height: 18,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                description,
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

              if (location.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color:
                          Colors.grey.shade600,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
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
}
