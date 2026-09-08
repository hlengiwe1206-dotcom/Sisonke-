import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'help_request_detail_screen.dart';

class HelpExchangeScreen extends StatefulWidget {
  const HelpExchangeScreen({super.key});

  @override
  State<HelpExchangeScreen> createState() =>
      _HelpExchangeScreenState();
}

class _HelpExchangeScreenState
    extends State<HelpExchangeScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allRequests = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = 'All Locations';

  final TextEditingController _searchController =
      TextEditingController();

  RealtimeChannel? _requestsChannel;

  @override
  void initState() {
    super.initState();

    _loadRequests();
    _listenForRequests();
  }

  // ============================================================
  // LOAD REQUESTS
  // ============================================================

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // --------------------------------------------------------
      // LOAD ACTIVE HELP REQUESTS ONLY
      // --------------------------------------------------------

      final requestData = await _supabase
          .from('help_requests')
          .select()
          .eq('status', 'open')
          .order(
            'created_at',
            ascending: false,
          );

      final requests =
          List<Map<String, dynamic>>.from(
        requestData,
      );

      // --------------------------------------------------------
      // LOAD POSTER PROFILES
      // --------------------------------------------------------

      final userIds = requests
          .map(
            (request) =>
                _safeText(request['user_id']),
          )
          .where(
            (id) => id.isNotEmpty,
          )
          .toSet()
          .toList();

      final profilesById =
          <String, Map<String, dynamic>>{};

      if (userIds.isNotEmpty) {
        final profileData = await _supabase
            .from('profiles')
            .select(
              'id, full_name, avatar_url',
            )
            .inFilter(
              'id',
              userIds,
            );

        for (final item in profileData) {
          final profile =
              Map<String, dynamic>.from(item);

          final profileId =
              _safeText(profile['id']);

          if (profileId.isNotEmpty) {
            profilesById[profileId] = profile;
          }
        }
      }

      // --------------------------------------------------------
      // ATTACH PROFILE INFORMATION
      // --------------------------------------------------------

      for (final request in requests) {
        final userId =
            _safeText(request['user_id']);

        final profile =
            profilesById[userId];

        request['poster_name'] =
            _safeText(
          profile?['full_name'],
          'Sisonke Member',
        );

        request['poster_avatar_url'] =
            _safeText(
          profile?['avatar_url'],
        );
      }

      if (!mounted) return;

      setState(() {
        _allRequests = requests;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading Help Exchange: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _listenForRequests() {
    _requestsChannel = _supabase
        .channel('help-exchange-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'help_requests',
          callback: (payload) {
            _loadRequests();
          },
        )
        .subscribe();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshRequests() async {
    await _loadRequests();
  }

  // ============================================================
  // SAFE TEXT
  // ============================================================

  String _safeText(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) {
      return fallback;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // SAFE BOOLEAN
  // ============================================================

  bool _safeBool(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    final text =
        value.toString().trim().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  // ============================================================
  // AVAILABLE CATEGORIES
  // ============================================================

  List<String> _categories() {
    final categories = _allRequests
        .map(
          (request) =>
              _safeText(request['category']),
        )
        .where(
          (category) => category.isNotEmpty,
        )
        .toSet()
        .toList();

    categories.sort();

    return [
      'All',
      ...categories,
    ];
  }

  // ============================================================
  // AVAILABLE LOCATIONS
  // ============================================================

  List<String> _locations() {
    final locations = _allRequests
        .map(
          (request) =>
              _safeText(request['location']),
        )
        .where(
          (location) => location.isNotEmpty,
        )
        .toSet()
        .toList();

    locations.sort();

    return [
      'All Locations',
      ...locations,
    ];
  }

  // ============================================================
  // FILTER REQUESTS
  // ============================================================

  List<Map<String, dynamic>>
      _filteredRequests() {
    final query =
        _searchQuery.trim().toLowerCase();

    return _allRequests.where((request) {
      final status =
          _safeText(
        request['status'],
      ).toLowerCase();

      // --------------------------------------------------------
      // ONLY ACTIVE OPEN REQUESTS
      // --------------------------------------------------------

      if (status != 'open') {
        return false;
      }

      // --------------------------------------------------------
      // CATEGORY FILTER
      // --------------------------------------------------------

      final category =
          _safeText(
        request['category'],
      );

      if (_selectedCategory != 'All' &&
          category.toLowerCase() !=
              _selectedCategory.toLowerCase()) {
        return false;
      }

      // --------------------------------------------------------
      // LOCATION FILTER
      // --------------------------------------------------------

      final location =
          _safeText(
        request['location'],
      );

      if (_selectedLocation !=
              'All Locations' &&
          location.toLowerCase() !=
              _selectedLocation.toLowerCase()) {
        return false;
      }

      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      if (query.isNotEmpty) {
        final title =
            _safeText(
          request['title'],
        ).toLowerCase();

        final description =
            _safeText(
          request['description'],
        ).toLowerCase();

        final posterName =
            _safeText(
          request['poster_name'],
        ).toLowerCase();

        final searchableText =
            '$title $description $category '
            '$location $posterName';

        if (!searchableText.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Recently';
    }

    try {
      final date = value is DateTime
          ? value
          : DateTime.parse(
              value.toString(),
            );

      final now = DateTime.now();

      final difference =
          now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
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
    } catch (_) {
      return 'Recently';
    }
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================

  Future<void> _openRequest(
    Map<String, dynamic> request,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HelpRequestDetailScreen(
          request: request,
        ),
      ),
    );

    _loadRequests();
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & essentials':
        return Icons.restaurant_outlined;

      case 'transport':
        return Icons.directions_car_outlined;

      case 'jobs':
      case 'employment':
        return Icons.work_outline;

      case 'education':
        return Icons.school_outlined;

      case 'health':
      case 'health & wellness':
        return Icons.favorite_outline;

      case 'emergency':
        return Icons.warning_amber_outlined;

      case 'housing':
        return Icons.home_outlined;

      case 'business':
      case 'business support':
        return Icons.business_outlined;

      default:
        return Icons.volunteer_activism_outlined;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    if (_requestsChannel != null) {
      _supabase.removeChannel(
        _requestsChannel!,
      );
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredRequests =
        _filteredRequests();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            const Color(0xFF1F2937),

        title: const Text(
          'Help Exchange',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshRequests,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildSearchArea(),

            _buildCategoryFilters(),

            _buildLocationFilter(),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : filteredRequests.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh:
                                  _refreshRequests,
                              child:
                                  ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),

                                padding:
                                    const EdgeInsets.all(
                                  16,
                                ),

                                itemCount:
                                    filteredRequests
                                        .length,

                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  return _buildRequestCard(
                                    filteredRequests[
                                        index],
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH AREA
  // ============================================================

  Widget _buildSearchArea() {
    return Container(
      color: Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        10,
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
              'What can you help with?',

          prefixIcon:
              const Icon(Icons.search),

          suffixIcon:
              _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.clear,
                      ),
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),

          filled: true,

          fillColor:
              const Color(0xFFF3F4F6),

          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),

            borderSide:
                BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),

            borderSide:
                BorderSide.none,
          ),

          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),

            borderSide:
                const BorderSide(
              color:
                  Color(0xFFFFB300),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY FILTERS
  // ============================================================

  Widget _buildCategoryFilters() {
    final categories =
        _categories();

    return Container(
      width: double.infinity,
      color: Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),

      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,

        child: Row(
          children:
              categories.map((category) {
            final selected =
                category ==
                    _selectedCategory;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),

              child: ChoiceChip(
                label: Text(category),

                selected: selected,

                selectedColor:
                    const Color(
                  0xFFFFB300,
                ),

                backgroundColor:
                    const Color(
                  0xFFF3F4F6,
                ),

                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF374151,
                        ),

                  fontWeight:
                      FontWeight.w600,
                ),

                onSelected: (value) {
                  if (!value) return;

                  setState(() {
                    _selectedCategory =
                        category;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION FILTER
  // ============================================================

  Widget _buildLocationFilter() {
    final locations =
        _locations();

    if (locations.length <= 1) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,

      color:
          const Color(0xFFF6F7FB),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),

      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color:
                Color(0xFF6B7280),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: DropdownButtonHideUnderline(
              child:
                  DropdownButton<String>(
                value:
                    _selectedLocation,

                isExpanded: true,

                items:
                    locations.map(
                  (location) {
                    return DropdownMenuItem<
                        String>(
                      value: location,

                      child: Text(
                        location,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    );
                  },
                ).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedLocation =
                        value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final title =
        _safeText(
      request['title'],
      'Help Request',
    );

    final description =
        _safeText(
      request['description'],
      'No description provided.',
    );

    final category =
        _safeText(
      request['category'],
      'General',
    );

    final location =
        _safeText(
      request['location'],
    );

    final urgent =
        _safeBool(
      request['urgent'],
    );

    final posterName =
        _safeText(
      request['poster_name'],
      'Sisonke Member',
    );

    final avatarUrl =
        _safeText(
      request['poster_avatar_url'],
    );

    final createdAt =
        _formatDate(
      request['created_at'],
    );

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          20,
        ),

        onTap: () =>
            _openRequest(request),

        child: Container(
          padding:
              const EdgeInsets.all(
            18,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              20,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withAlpha(
                  10,
                ),

                blurRadius: 12,

                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // PROFILE
              // ------------------------------------------------

              Row(
                children: [
                  _buildPosterAvatar(
                    avatarUrl,
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
                          posterName,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,

                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Row(
                          children: [
                            if (location
                                .isNotEmpty) ...[
                              const Icon(
                                Icons
                                    .location_on_outlined,

                                size: 14,

                                color: Color(
                                  0xFF6B7280,
                                ),
                              ),

                              const SizedBox(
                                width: 3,
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
                                        12,

                                    color:
                                        Color(
                                      0xFF6B7280,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),
                            ],

                            Text(
                              createdAt,

                              style:
                                  const TextStyle(
                                fontSize: 12,

                                color: Color(
                                  0xFF6B7280,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Text(
                      title,

                      style:
                          const TextStyle(
                        fontSize: 18,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Color(
                          0xFF1F2937,
                        ),
                      ),
                    ),
                  ),

                  if (urgent)
                    Container(
                      margin:
                          const EdgeInsets.only(
                        left: 10,
                      ),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.red
                            .withAlpha(25),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child:
                          const Text(
                        'URGENT',

                        style:
                            TextStyle(
                          color:
                              Colors.red,

                          fontSize: 10,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              // ------------------------------------------------
              // DESCRIPTION
              // ------------------------------------------------

              Text(
                description,

                maxLines: 3,

                overflow:
                    TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 14,

                  height: 1.4,

                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ------------------------------------------------
              // CATEGORY
              // ------------------------------------------------

              Wrap(
                spacing: 8,

                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF3F4F6,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [
                        Icon(
                          _categoryIcon(
                            category,
                          ),

                          size: 15,

                          color:
                              const Color(
                            0xFF374151,
                          ),
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          category,

                          style:
                              const TextStyle(
                            fontSize: 12,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.green
                          .withAlpha(25),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),

                    child:
                        const Text(
                      'OPEN',

                      style: TextStyle(
                        color:
                            Colors.green,

                        fontSize: 11,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ------------------------------------------------
              // VIEW REQUEST
              // ------------------------------------------------

              Row(
                children: [
                  const Text(
                    'View request',

                    style: TextStyle(
                      color:
                          Color(0xFFFFB300),

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons.arrow_forward_ios,

                    size: 16,

                    color:
                        Color(0xFFFFB300),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildPosterAvatar(
    String avatarUrl,
  ) {
    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 24,

        backgroundColor:
            Color(0xFFE5E7EB),

        child: Icon(
          Icons.person,

          color:
              Color(0xFF6B7280),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,

      backgroundColor:
          const Color(0xFFE5E7EB),

      backgroundImage:
          NetworkImage(avatarUrl),

      onBackgroundImageError:
          (_, __) {},
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearchOrFilters =
        _searchQuery.isNotEmpty ||
            _selectedCategory != 'All' ||
            _selectedLocation !=
                'All Locations';

    return RefreshIndicator(
      onRefresh: _refreshRequests,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: [
          const SizedBox(
            height: 100,
          ),

          const Icon(
            Icons.volunteer_activism_outlined,

            size: 75,

            color:
                Color(0xFF9CA3AF),
          ),

          const SizedBox(
            height: 20,
          ),

          Text(
            hasSearchOrFilters
                ? 'No matching requests'
                : 'No active Help Requests',

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 20,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 40,
            ),

            child: Text(
              hasSearchOrFilters
                  ? 'Try changing your search or filters.'
                  : 'When a fellow South African requests help, it will appear here.',

              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                color:
                    Color(0xFF6B7280),
              ),
            ),
          ),

          if (hasSearchOrFilters) ...[
            const SizedBox(
              height: 20,
            ),

            Center(
              child: OutlinedButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                    _selectedCategory =
                        'All';
                    _selectedLocation =
                        'All Locations';
                  });
                },

                child:
                    const Text(
                  'Clear Filters',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,

              size: 60,

              color: Colors.red,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Unable to load Help Requests',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 18,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              _errorMessage ??
                  'An unexpected error occurred.',

              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                color:
                    Color(0xFF6B7280),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
                  _loadRequests,

              icon:
                  const Icon(Icons.refresh),

              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
