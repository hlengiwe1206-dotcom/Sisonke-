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

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    try {
      final List<dynamic> data = await _supabase
          .from('help_requests')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      return List<Map<String, dynamic>>.from(data);
    } catch (error) {
      throw Exception(
        'Unable to load help requests: $error',
      );
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = _loadRequests();
    });

    await _requestsFuture;
  }

  List<Map<String, dynamic>> _filterRequests(
    List<Map<String, dynamic>> requests,
  ) {
    if (_selectedFilter == 'All') {
      return requests;
    }

    return requests.where((request) {
      final String status = _safeText(
        request['status'],
      ).toLowerCase();

      final bool urgent = _safeBool(
        request['is_urgent'] ??
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

    final String text = value
        .toString()
        .trim()
        .toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String year =
        date.year.toString();

    return '$day/$month/$year';
  }

  String _requestTitle(
    Map<String, dynamic> request,
  ) {
    return _safeText(
      request['title'] ??
          request['subject'] ??
          request['request_title'],
      fallback: 'Help request',
    );
  }

  String _requestDescription(
    Map<String, dynamic> request,
  ) {
    return _safeText(
      request['description'] ??
          request['details'] ??
          request['message'],
    );
  }

  String _requestCategory(
    Map<String, dynamic> request,
  ) {
    return _safeText(
      request['category'] ??
          request['type'],
      fallback: 'General help',
    );
  }

  String _requestLocation(
    Map<String, dynamic> request,
  ) {
    return _safeText(
      request['location'] ??
          request['area'] ??
          request['address'],
    );
  }

  String _requestStatus(
    Map<String, dynamic> request,
  ) {
    return _safeText(
      request['status'],
      fallback: 'Open',
    );
  }

  bool _isUrgent(
    Map<String, dynamic> request,
  ) {
    return _safeBool(
      request['is_urgent'] ??
          request['urgent'],
    );
  }

  IconData _categoryIcon(
    String category,
  ) {
    final String value =
        category.toLowerCase();

    if (value.contains('food')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('transport')) {
      return Icons.directions_car_outlined;
    }

    if (value.contains('medical') ||
        value.contains('health')) {
      return Icons.medical_services_outlined;
    }

    if (value.contains('education')) {
      return Icons.school_outlined;
    }

    if (value.contains('job') ||
        value.contains('work')) {
      return Icons.work_outline;
    }

    if (value.contains('housing') ||
        value.contains('home')) {
      return Icons.home_outlined;
    }

    if (value.contains('business')) {
      return Icons.business_center_outlined;
    }

    return Icons.volunteer_activism_outlined;
  }

  Color _categoryColor(
    String category,
  ) {
    final String value =
        category.toLowerCase();

    if (value.contains('food')) {
      return const Color(0xFFE67E22);
    }

    if (value.contains('transport')) {
      return const Color(0xFF1565C0);
    }

    if (value.contains('medical') ||
        value.contains('health')) {
      return const Color(0xFFC62828);
    }

    if (value.contains('education')) {
      return const Color(0xFF6A1B9A);
    }

    if (value.contains('job') ||
        value.contains('work')) {
      return const Color(0xFF2E7D32);
    }

    return const Color(0xFF34577C);
  }

  Future<void> _openRequest(
    Map<String, dynamic> request,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return HelpRequestDetailScreen(
            request: request,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    _refreshRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF1F2937),
        title: const Text(
          'Help Exchange',
          style: TextStyle(
            fontWeight: FontWeight.w800,
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
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: FutureBuilder<
                  List<Map<String, dynamic>>>(
                future: _requestsFuture,
                builder: (
                  context,
                  snapshot,
                ) {
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

                  final List<
                          Map<String, dynamic>>
                      requests =
                      _filterRequests(
                    snapshot.data ?? [],
                  );

                  if (requests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      30,
                    ),
                    itemCount:
                        requests.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return _buildRequestCard(
                        requests[index],
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
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Community helping community',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Browse requests, offer assistance and connect with people who need help.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 64,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        itemCount:
            _filters.length,
        separatorBuilder: (
          context,
          index,
        ) {
          return const SizedBox(
            width: 8,
          );
        },
        itemBuilder: (
          context,
          index,
        ) {
          final String filter =
              _filters[index];

          final bool selected =
              filter == _selectedFilter;

          return ChoiceChip(
            label: Text(
              filter,
            ),
            selected: selected,
            selectedColor:
                const Color(0xFF34577C),
            backgroundColor:
                const Color(0xFFF0F2F5),
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(
                      0xFF374151,
                    ),
              fontWeight:
                  FontWeight.w700,
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
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final String title =
        _requestTitle(request);

    final String description =
        _requestDescription(request);

    final String category =
        _requestCategory(request);

    final String location =
        _requestLocation(request);

    final String status =
        _requestStatus(request);

    final bool urgent =
        _isUrgent(request);

    final DateTime? createdAt =
        _parseDate(
      request['created_at'],
    );

    final Color categoryColor =
        _categoryColor(category);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        side: const BorderSide(
          color:
              Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        onTap: () {
          _openRequest(
            request,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(
            17,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: categoryColor
                          .withOpacity(
                        0.12,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      _categoryIcon(
                        category,
                      ),
                      color:
                          categoryColor,
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
                          category
                              .toUpperCase(),
                          style:
                              TextStyle(
                            fontSize: 11,
                            letterSpacing:
                                0.8,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                categoryColor,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          status
                              .toUpperCase(),
                          style:
                              const TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                Color(
                              0xFF6B7280,
                            ),
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
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFEBEE,
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
                            0xFFC62828,
                          ),
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w800,
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
                  height: 1.25,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF1F2937),
                ),
              ),
              if (description
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 9,
                ),
                Text(
                  description,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color:
                        Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(
                height: 15,
              ),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  if (location
                      .isNotEmpty)
                    _buildInfoItem(
                      Icons
                          .location_on_outlined,
                      location,
                    ),
                  if (createdAt !=
                      null)
                    _buildInfoItem(
                      Icons
                          .access_time_outlined,
                      _formatDate(
                        createdAt,
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              const Row(
                children: [
                  Text(
                    'View request',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(
                        0xFF34577C,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 18,
                    color:
                        Color(0xFF34577C),
                  ),
                ],
              ),
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
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color:
              const Color(0xFF6B7280),
        ),
        const SizedBox(
          width: 5,
        ),
        Flexible(
          child: Text(
            text,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 32,
      ),
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons
              .volunteer_activism_outlined,
          size: 64,
          color:
              Color(0xFF9CA3AF),
        ),
        SizedBox(height: 18),
        Center(
          child: Text(
            'No help requests found',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF1F2937),
            ),
          ),
        ),
        SizedBox(height: 9),
        Center(
          child: Text(
            'When members post requests for assistance, they will appear here.',
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
          height: 100,
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
            'Unable to load help requests',
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
          style:
              const TextStyle(
            fontSize: 12,
            color:
                Color(0xFF6B7280),
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        Center(
          child: ElevatedButton.icon(
            onPressed:
                _refreshRequests,
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
}
