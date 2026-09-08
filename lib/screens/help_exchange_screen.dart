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

  late Future<List<Map<String, dynamic>>>
      _requestsFuture;

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Open',
    'Urgent',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  // ============================================================
  // LOAD HELP REQUESTS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      _loadRequests() async {
    try {
      final List<dynamic> requestData =
          await _supabase
              .from('help_requests')
              .select(
                'id, post_id, requester_id, status, '
                'category, location, urgent, created_at',
              )
              .order(
                'created_at',
                ascending: false,
              );

      final requests = requestData
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();

      if (requests.isEmpty) {
        return requests;
      }

      // ----------------------------------------------------------
      // LOAD PARENT POSTS
      // ----------------------------------------------------------

      final postIds = requests
          .map(
            (request) =>
                _safeText(request['post_id']),
          )
          .where(
            (id) => id.isNotEmpty,
          )
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>>
          postsById = {};

      if (postIds.isNotEmpty) {
        final List<dynamic> postData =
            await _supabase
                .from('posts')
                .select(
                  'id, user_id, type, title, content, '
                  'status, created_at',
                )
                .inFilter(
                  'id',
                  postIds,
                );

        for (final item in postData) {
          final post =
              Map<String, dynamic>.from(item);

          final id =
              _safeText(post['id']);

          if (id.isNotEmpty) {
            postsById[id] = post;
          }
        }
      }

      // ----------------------------------------------------------
      // LOAD REQUESTER PROFILES
      // ----------------------------------------------------------

      final requesterIds = requests
          .map(
            (request) =>
                _safeText(request['requester_id']),
          )
          .where(
            (id) => id.isNotEmpty,
          )
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>>
          profilesById = {};

      if (requesterIds.isNotEmpty) {
        final List<dynamic> profileData =
            await _supabase
                .from('profiles')
                .select(
                  'id, first_name, full_name, avatar_url',
                )
                .inFilter(
                  'id',
                  requesterIds,
                );

        for (final item in profileData) {
          final profile =
              Map<String, dynamic>.from(item);

          final id =
              _safeText(profile['id']);

          if (id.isNotEmpty) {
            profilesById[id] = profile;
          }
        }
      }

      // ----------------------------------------------------------
      // COMBINE DATA
      // ----------------------------------------------------------

      for (final request in requests) {
        final post =
            postsById[
              _safeText(request['post_id'])
            ];

        if (post != null) {
          request['title'] =
              _safeText(
            post['title'],
            'Help Request',
          );

          request['description'] =
              _safeText(
            post['content'],
            'No description provided.',
          );

          request['post_status'] =
              _safeText(post['status']);

          request['post_user_id'] =
              _safeText(post['user_id']);
        } else {
          request['title'] =
              'Help Request';

          request['description'] =
              'No description provided.';
        }

        final profile =
            profilesById[
              _safeText(
                request['requester_id'],
              )
            ];

        if (profile != null) {
          request['poster_name'] =
              _profileName(profile);

          request['poster_avatar_url'] =
              _safeText(
            profile['avatar_url'],
          );
        } else {
          request['poster_name'] =
              'Sisonke Member';

          request['poster_avatar_url'] =
              '';
        }
      }

      return requests;
    } on PostgrestException catch (error) {
      throw Exception(
        'Unable to load help requests: ${error.message}',
      );
    } catch (error) {
      throw Exception(
        'Unable to load help requests: $error',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = _loadRequests();
    });

    await _requestsFuture;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> _filterRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_selectedFilter == 'All') {
      return requests;
    }

    return requests.where((request) {
      final status =
          _safeText(
            request['status'],
          ).toLowerCase();

      final urgent =
          _safeBool(
            request['urgent'],
          );

      switch (_selectedFilter) {
        case 'Open':
          return status.isEmpty ||
              status == 'open' ||
              status == 'pending' ||
              status == 'active';

        case 'Urgent':
          return urgent;

        case 'Completed':
          return status == 'completed' ||
              status == 'closed' ||
              status == 'resolved';

        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  Future<void> _openRequest(
    Map<String, dynamic> request,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HelpRequestDetailScreen(
          request: request,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _requestsFuture = _loadRequests();
    });
  }

  // ============================================================
  // HELPERS
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
        text == 'null') {
      return fallback;
    }

    return text;
  }

  bool _safeBool(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    final text =
        value.toString().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  String _profileName(
    Map<String, dynamic> profile,
  ) {
    final firstName =
        _safeText(
      profile['first_name'],
    );

    final fullName =
        _safeText(
      profile['full_name'],
    );

    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (firstName.isNotEmpty) {
      return firstName;
    }

    return 'Sisonke Member';
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return 'Recently';
    }

    try {
      final date =
          value is DateTime
              ? value
              : DateTime.parse(
                  value.toString(),
                );

      final now =
          DateTime.now();

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

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
      case 'resolved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'open':
      case 'active':
        return const Color(0xFF007749);

      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;

      case 'employment':
        return Icons.work_outline;

      case 'education':
        return Icons.school_outlined;

      case 'healthcare':
      case 'health':
        return Icons.health_and_safety_outlined;

      case 'housing':
        return Icons.home_outlined;

      case 'transport':
        return Icons.directions_car_outlined;

      case 'business':
        return Icons.business_outlined;

      case 'emergency':
        return Icons.warning_amber_outlined;

      default:
        return Icons.volunteer_activism_outlined;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text(
          'Help Exchange',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _refreshRequests,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xFF007749),
        foregroundColor:
            Colors.white,
        onPressed: () async {
          await Navigator.of(context)
              .pushNamed('/create-help-request');

          if (!mounted) return;

          setState(() {
            _requestsFuture =
                _loadRequests();
          });
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Ask for Help',
        ),
      ),

      body: Column(
        children: [
          _buildIntro(),
          _buildFilters(),

          Expanded(
            child: FutureBuilder<
                List<Map<String, dynamic>>>(
              future: _requestsFuture,
              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF007749),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(
                    snapshot.error
                        .toString(),
                  );
                }

                final requests =
                    _filterRequests(
                  snapshot.data ?? [],
                );

                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color:
                      const Color(0xFF007749),
                  onRefresh:
                      _refreshRequests,
                  child:
                      ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      100,
                    ),
                    itemCount:
                        requests.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(
                      height: 12,
                    ),
                    itemBuilder:
                        (context, index) {
                      return _buildRequestCard(
                        requests[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'People helping people.',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find someone who needs help, or offer '
            'your skills, time or resources to someone '
            'in the Sisonke community.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color:
                  Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        child: Row(
          children:
              _filters.map((filter) {
            final selected =
                _selectedFilter ==
                    filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter =
                        filter;
                  });
                },
                selectedColor:
                    const Color(
                  0xFF007749,
                ),
                backgroundColor:
                    const Color(
                  0xFFF1F3F4,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF333333,
                        ),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
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
      'General Assistance',
    );

    final location =
        _safeText(
      request['location'],
    );

    final status =
        _safeText(
      request['status'],
      'Open',
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

    final urgent =
        _safeBool(
      request['urgent'],
    );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () =>
            _openRequest(request),
        child: Container(
          padding:
              const EdgeInsets.all(18),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  const Color(0xFFE6E7E8),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        const Color(
                      0xFFE8F3EE,
                    ),
                    backgroundImage:
                        avatarUrl.isNotEmpty
                            ? NetworkImage(
                                avatarUrl,
                              )
                            : null,
                    child:
                        avatarUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color:
                                    Color(
                                  0xFF007749,
                                ),
                              )
                            : null,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          posterName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          _formatDate(
                            request[
                                'created_at'],
                          ),
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (urgent)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFFFFE8E7,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child:
                          const Text(
                        'URGENT',
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFFDE3831,
                          ),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                description,
                maxLines: 3,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    _categoryIcon(category),
                    category,
                  ),

                  if (location.isNotEmpty)
                    _buildInfoChip(
                      Icons
                          .location_on_outlined,
                      location,
                    ),

                  _buildStatusChip(
                    status,
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  Text(
                    'View request',
                    style:
                        TextStyle(
                      color:
                          Color(0xFF007749),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Icons
                        .arrow_forward,
                    size: 18,
                    color:
                        Color(0xFF007749),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF4F5F6),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color:
                const Color(0xFF59636E),
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withAlpha(20),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        status.isEmpty
            ? 'Open'
            : status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 32,
      ),
      children: const [
        SizedBox(
          height: 90,
        ),
        Icon(
          Icons
              .volunteer_activism_outlined,
          size: 64,
          color:
              Color(0xFF9CA3AF),
        ),
        SizedBox(
          height: 18,
        ),
        Center(
          child: Text(
            'No help requests found',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Center(
          child: Text(
            'When Sisonke members ask for help, '
            'their requests will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      children: [
        const SizedBox(
          height: 90,
        ),
        const Icon(
          Icons.cloud_off_outlined,
          size: 62,
          color:
              Color(0xFF9CA3AF),
        ),
        const SizedBox(
          height: 18,
        ),
        const Center(
          child: Text(
            'Unable to load Help Exchange',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
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
          style: const TextStyle(
            fontSize: 12,
            color:
                Color(0xFF6B7280),
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        Center(
          child:
              ElevatedButton.icon(
            onPressed:
                _refreshRequests,
            icon:
                const Icon(
              Icons.refresh,
            ),
            label:
                const Text(
              'Try again',
            ),
          ),
        ),
      ],
    );
  }
}
