import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'help_request_detail_screen.dart';

class HelpExchangeScreen extends StatefulWidget {
  const HelpExchangeScreen({super.key});

  @override
  State<HelpExchangeScreen> createState() => _HelpExchangeScreenState();
}

class _HelpExchangeScreenState extends State<HelpExchangeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _requestsFuture;

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

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    try {
      final List<dynamic> data = await _supabase
          .from('help_requests')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      return data
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } catch (error) {
      throw Exception(
        'Unable to load help requests: $error',
      );
    }
  }

  // ============================================================
  // REFRESH REQUESTS
  // ============================================================

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = _loadRequests();
    });

    await _requestsFuture;
  }

  // ============================================================
  // FILTER REQUESTS
  // ============================================================

  List<Map<String, dynamic>> _filterRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_selectedFilter == 'All') {
      return requests;
    }

    return requests.where((request) {
      final String status =
          _safeText(request['status']).toLowerCase();

      final bool urgent =
          _safeBool(request['urgent']);

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
  // SAFE TEXT
  // ============================================================

  String _safeText(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty || text == 'null') {
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

    final String text =
        value.toString().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Recently';
    }

    try {
      final DateTime date =
          value is DateTime
              ? value
              : DateTime.parse(
                  value.toString(),
                );

      final DateTime now = DateTime.now();

      final Duration difference =
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
  // STATUS COLOUR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
      case 'resolved':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'open':
      case 'active':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // OPEN REQUEST DETAILS
  // ============================================================

  void _openRequest(
    Map<String, dynamic> request,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HelpRequestDetailScreen(
          request: request,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF1F2937),

        title: const Text(
          'Help Exchange',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshRequests,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // FILTERS
            // ==================================================

            Container(
              width: double.infinity,
              color: Colors.white,

              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),

              child: SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,

                child: Row(
                  children: _filters.map(
                    (filter) {
                      final bool selected =
                          filter ==
                              _selectedFilter;

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          right: 10,
                        ),

                        child: ChoiceChip(
                          label: Text(
                            filter,
                          ),

                          selected: selected,

                          selectedColor:
                              const Color(
                            0xFFFFB300,
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

                          onSelected:
                              (bool value) {
                            if (!value) {
                              return;
                            }

                            setState(() {
                              _selectedFilter =
                                  filter;
                            });
                          },
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),

            // ==================================================
            // REQUEST LIST
            // ==================================================

            Expanded(
              child: FutureBuilder<
                  List<Map<String, dynamic>>>(
                future: _requestsFuture,

                builder: (
                  context,
                  snapshot,
                ) {
                  // ============================================
                  // LOADING
                  // ============================================

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  // ============================================
                  // ERROR
                  // ============================================

                  if (snapshot.hasError) {
                    return _buildErrorState(
                      snapshot.error.toString(),
                    );
                  }

                  final List<
                          Map<String, dynamic>>
                      requests =
                      snapshot.data ?? [];

                  final List<
                          Map<String, dynamic>>
                      filteredRequests =
                      _filterRequests(
                    requests,
                  );

                  // ============================================
                  // EMPTY
                  // ============================================

                  if (filteredRequests.isEmpty) {
                    return _buildEmptyState();
                  }

                  // ============================================
                  // REQUEST LIST
                  // ============================================

                  return RefreshIndicator(
                    onRefresh:
                        _refreshRequests,

                    child: ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding:
                          const EdgeInsets.all(16),

                      itemCount:
                          filteredRequests.length,

                      itemBuilder:
                          (context, index) {
                        final request =
                            filteredRequests[index];

                        return _buildRequestCard(
                          request,
                        );
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

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final String title =
        _safeText(
      request['title'],
      'Help Request',
    );

    final String description =
        _safeText(
      request['description'],
      'No description provided.',
    );

    final String category =
        _safeText(
      request['category'],
      'General',
    );

    final String status =
        _safeText(
      request['status'],
      'Open',
    );

    final bool urgent =
        _safeBool(
      request['urgent'],
    );

    final String createdAt =
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
            BorderRadius.circular(20),

        // ==============================================
        // CORRECT NAVIGATION LOCATION
        // ==============================================

        onTap: () {
          _openRequest(request);
        },

        child: Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(20),

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
              // ==========================================
              // TITLE AND URGENT LABEL
              // ==========================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Text(
                      title,

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1F2937),
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
                        color:
                            Colors.red.withAlpha(
                          25,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),

                      child: const Text(
                        'URGENT',

                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // DESCRIPTION
              // ==========================================

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

              const SizedBox(height: 16),

              // ==========================================
              // CATEGORY / STATUS / DATE
              // ==========================================

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: [
                  _buildCategoryChip(
                    category,
                  ),

                  _buildStatusChip(
                    status,
                  ),

                  _buildDateChip(
                    createdAt,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // OPEN DETAILS
              // ==========================================

              Row(
                children: [
                  Text(
                    'View request',

                    style: TextStyle(
                      color:
                          const Color(
                        0xFFFFB300,
                      ),

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
  // CATEGORY CHIP
  // ============================================================

  Widget _buildCategoryChip(
    String category,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF3F4F6),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.category_outlined,
            size: 14,
            color: Color(0xFF6B7280),
          ),

          const SizedBox(width: 5),

          Text(
            category,

            style: const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF4B5563),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
  ) {
    final Color color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            color.withAlpha(20),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            status,

            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE CHIP
  // ============================================================

  Widget _buildDateChip(
    String date,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF9FAFB),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.access_time,
            size: 14,
            color: Color(0xFF6B7280),
          ),

          const SizedBox(width: 5),

          Text(
            date,

            style: const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh:
          _refreshRequests,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(height: 100),

          Icon(
            Icons.volunteer_activism_outlined,
            size: 70,
            color: Colors.grey,
          ),

          SizedBox(height: 20),

          Center(
            child: Text(
              'No help requests found.',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Text(
              'New requests will appear here.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _refreshRequests,

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
