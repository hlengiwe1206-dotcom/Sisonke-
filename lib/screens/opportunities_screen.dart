import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'opportunity_details_screen.dart';

class SavedOpportunitiesScreen
    extends StatefulWidget {
  const SavedOpportunitiesScreen({
    super.key,
  });

  @override
  State<SavedOpportunitiesScreen>
      createState() =>
          _SavedOpportunitiesScreenState();
}

class _SavedOpportunitiesScreenState
    extends State<SavedOpportunitiesScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>>
      _savedOpportunities = [];

  @override
  void initState() {
    super.initState();
    _loadSavedOpportunities();
  }

  Future<void> _loadSavedOpportunities() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _savedOpportunities = [];
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('opportunity_saves')
          .select('''
            id,
            created_at,
            opportunity_id,
            opportunities (
              *
            )
          ''')
          .eq('user_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      final saves =
          List<Map<String, dynamic>>.from(
        response,
      );

      final opportunities =
          <Map<String, dynamic>>[];

      for (final save in saves) {
        final opportunity =
            save['opportunities'];

        if (opportunity is Map) {
          opportunities.add(
            Map<String, dynamic>.from(
              opportunity,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _savedOpportunities =
            opportunities;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            error.toString();

        _isLoading = false;
      });
    }
  }

  String _getString(
    Map<String, dynamic> opportunity,
    List<String> columns, {
    String fallback = '',
  }) {
    for (final column in columns) {
      final value =
          opportunity[column];

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
        'opportunity_type',
      ],
      fallback:
          'Opportunity',
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
    final possibleColumns = [
      'closing_date',
      'deadline',
      'application_deadline',
      'expiry_date',
    ];

    for (final column
        in possibleColumns) {
      final value =
          opportunity[column];

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

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _iconForCategory(
    String category,
  ) {
    switch (
        category.toLowerCase()) {
      case 'tender':
      case 'tenders':
        return Icons
            .description_outlined;

      case 'employment':
      case 'job':
      case 'jobs':
        return Icons.work_outline;

      case 'funding':
      case 'grant':
      case 'grants':
        return Icons
            .account_balance_outlined;

      case 'learnership':
      case 'learnerships':
      case 'internship':
      case 'internships':
        return Icons.school_outlined;

      default:
        return Icons
            .campaign_outlined;
    }
  }

  Future<void> _removeSave(
    Map<String, dynamic> opportunity,
  ) async {
    final user =
        _supabase.auth.currentUser;

    final opportunityId =
        opportunity['id']?.toString();

    if (user == null ||
        opportunityId == null) {
      return;
    }

    try {
      await _supabase
          .from('opportunity_saves')
          .delete()
          .eq('user_id', user.id)
          .eq(
            'opportunity_id',
            opportunityId,
          );

      if (!mounted) return;

      setState(() {
        _savedOpportunities.removeWhere(
          (item) =>
              item['id']
                  ?.toString() ==
              opportunityId,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Removed from saved opportunities.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove saved opportunity: $error',
          ),
        ),
      );
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
        title: const Text(
          'Saved Opportunities',
        ),

        backgroundColor:
            const Color(0xFFF8F7F4),

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        actions: [
          IconButton(
            onPressed:
                _loadSavedOpportunities,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh:
            _loadSavedOpportunities,

        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          SizedBox(
            height: 500,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  30,
                ),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 52,
                      color:
                          Color(
                        0xFFE9322A,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Unable to load saved opportunities',
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton(
                      onPressed:
                          _loadSavedOpportunities,

                      child: const Text(
                        'Try Again',
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

    if (_savedOpportunities
        .isEmpty) {
      return ListView(
        children: const [
          SizedBox(
            height: 500,

            child: Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Icon(
                    Icons
                        .bookmark_border,
                    size: 70,
                    color:
                        Colors.grey,
                  ),

                  SizedBox(
                    height: 16,
                  ),

                  Text(
                    'No saved opportunities yet',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Save opportunities to find them easily later.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.all(16),

      itemCount:
          _savedOpportunities.length,

      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height: 12,
      ),

      itemBuilder:
          (context, index) {
        final opportunity =
            _savedOpportunities[index];

        return _buildCard(
          opportunity,
        );
      },
    );
  }

  Widget _buildCard(
    Map<String, dynamic> opportunity,
  ) {
    final title =
        _title(opportunity);

    final organisation =
        _organisation(opportunity);

    final category =
        _category(opportunity);

    final location =
        _location(opportunity);

    final closingDate =
        _closingDate(opportunity);

    return Card(
      elevation: 0,

      color: Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),

        onTap: () async {
          await Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) =>
                  OpportunityDetailsScreen(
                opportunity:
                    opportunity,
              ),
            ),
          );

          _loadSavedOpportunities();
        },

        child: Padding(
          padding:
              const EdgeInsets.all(
            18,
          ),

          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3F4F6,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Icon(
                  _iconForCategory(
                    category,
                  ),
                  color:
                      const Color(
                    0xFF1F232B,
                  ),
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
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      title,
                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight
                                .w800,
                        color:
                            Color(
                          0xFF1F232B,
                        ),
                      ),
                    ),

                    if (organisation
                        .isNotEmpty) ...[
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
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],

                    if (location
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        location,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Color(
                            0xFF9CA3AF,
                          ),
                        ),
                      ),
                    ],

                    if (closingDate !=
                        null) ...[
                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        'Closes ${_formatDate(closingDate)}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight
                                  .w600,
                          color:
                              Color(
                            0xFFE9322A,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                onPressed: () =>
                    _removeSave(
                  opportunity,
                ),

                icon: const Icon(
                  Icons.bookmark,
                  color:
                      Color(
                    0xFFE9322A,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
