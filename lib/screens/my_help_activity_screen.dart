import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHelpActivityScreen extends StatefulWidget {
  const MyHelpActivityScreen({super.key});

  @override
  State<MyHelpActivityScreen> createState() =>
      _MyHelpActivityScreenState();
}

class _MyHelpActivityScreenState
    extends State<MyHelpActivityScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _responsesToMyRequests = [];
  List<Map<String, dynamic>> _myResponses = [];

  RealtimeChannel? _responsesChannel;
  RealtimeChannel? _requestsChannel;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadAllActivity();
    _listenForChanges();
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> _loadAllActivity() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await Future.wait([
        _loadResponsesToMyRequests(),
        _loadMyResponses(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading help activity: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // TAB 1
  //
  // RESPONSES TO MY HELP REQUESTS
  // ============================================================

  Future<void> _loadResponsesToMyRequests() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _responsesToMyRequests = [];
      return;
    }

    // ----------------------------------------------------------
    // LOAD MY HELP REQUESTS
    // ----------------------------------------------------------

    final List<dynamic> requestData =
        await _supabase
            .from('help_requests')
            .select()
            .eq('user_id', user.id)
            .order(
              'created_at',
              ascending: false,
            );

    final List<Map<String, dynamic>> myRequests =
        requestData
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();

    if (myRequests.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final List<String> requestIds = myRequests
        .map(
          (request) =>
              _safeText(request['id']),
        )
        .where(
          (id) => id.isNotEmpty,
        )
        .toList();

    if (requestIds.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    // ----------------------------------------------------------
    // CREATE REQUEST LOOKUP
    // ----------------------------------------------------------

    final Map<String, Map<String, dynamic>>
        requestsById = {};

    for (final request in myRequests) {
      final String requestId =
          _safeText(request['id']);

      if (requestId.isNotEmpty) {
        requestsById[requestId] = request;
      }
    }

    // ----------------------------------------------------------
    // LOAD RESPONSES TO MY REQUESTS
    // ----------------------------------------------------------

    final List<dynamic> responseData =
        await _supabase
            .from('help_responses')
            .select()
            .inFilter(
              'request_id',
              requestIds,
            )
            .order(
              'created_at',
              ascending: false,
            );

    final List<Map<String, dynamic>> responses =
        responseData
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();

    if (responses.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    // ----------------------------------------------------------
    // COLLECT RESPONDER IDS
    // ----------------------------------------------------------

    final List<String> responderIds =
        responses
            .map(
              (response) =>
                  _safeText(
                response['responder_id'],
              ),
            )
            .where(
              (id) => id.isNotEmpty,
            )
            .toSet()
            .toList();

    // ----------------------------------------------------------
    // LOAD RESPONDER PROFILES
    // ----------------------------------------------------------

    final Map<String, Map<String, dynamic>>
        profilesById = {};

    if (responderIds.isNotEmpty) {
      final List<dynamic> profileData =
          await _supabase
              .from('profiles')
              .select(
                'id, full_name, avatar_url',
              )
              .inFilter(
                'id',
                responderIds,
              );

      for (final profile in profileData) {
        final Map<String, dynamic> profileMap =
            Map<String, dynamic>.from(profile);

        final String profileId =
            _safeText(profileMap['id']);

        if (profileId.isNotEmpty) {
          profilesById[profileId] =
              profileMap;
        }
      }
    }

    // ----------------------------------------------------------
    // COMBINE RESPONSE + REQUEST + RESPONDER PROFILE
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> combined =
        [];

    for (final response in responses) {
      final String requestId =
          _safeText(
        response['request_id'],
      );

      final String responderId =
          _safeText(
        response['responder_id'],
      );

      final request =
          requestsById[requestId];

      final profile =
          profilesById[responderId];

      combined.add({
        ...response,

        'request_title':
            _safeText(
          request?['title'],
          'Help Request',
        ),

        'request_description':
            _safeText(
          request?['description'],
        ),

        'responder_name':
            _safeText(
          profile?['full_name'],
          'Sisonke Member',
        ),

        'responder_avatar_url':
            _safeText(
          profile?['avatar_url'],
        ),
      });
    }

    _responsesToMyRequests = combined;
  }

  // ============================================================
  // TAB 2
  //
  // MY RESPONSES TO OTHER PEOPLE'S REQUESTS
  // ============================================================

  Future<void> _loadMyResponses() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _myResponses = [];
      return;
    }

    // ----------------------------------------------------------
    // LOAD MY RESPONSES
    // ----------------------------------------------------------

    final List<dynamic> responseData =
        await _supabase
            .from('help_responses')
            .select()
            .eq(
              'responder_id',
              user.id,
            )
            .order(
              'created_at',
              ascending: false,
            );

    final List<Map<String, dynamic>> responses =
        responseData
            .map(
              (item) =>
                  Map<String, dynamic>.from(item),
            )
            .toList();

    if (responses.isEmpty) {
      _myResponses = [];
      return;
    }

    // ----------------------------------------------------------
    // COLLECT REQUEST IDS
    // ----------------------------------------------------------

    final List<String> requestIds =
        responses
            .map(
              (response) =>
                  _safeText(
                response['request_id'],
              ),
            )
            .where(
              (id) => id.isNotEmpty,
            )
            .toSet()
            .toList();

    if (requestIds.isEmpty) {
      _myResponses = [];
      return;
    }

    // ----------------------------------------------------------
    // LOAD HELP REQUESTS
    // ----------------------------------------------------------

    final List<dynamic> requestData =
        await _supabase
            .from('help_requests')
            .select()
            .inFilter(
              'id',
              requestIds,
            );

    final Map<String, Map<String, dynamic>>
        requestsById = {};

    final Set<String> requestOwnerIds = {};

    for (final item in requestData) {
      final Map<String, dynamic> request =
          Map<String, dynamic>.from(item);

      final String requestId =
          _safeText(request['id']);

      final String ownerId =
          _safeText(request['user_id']);

      if (requestId.isNotEmpty) {
        requestsById[requestId] = request;
      }

      if (ownerId.isNotEmpty) {
        requestOwnerIds.add(ownerId);
      }
    }

    // ----------------------------------------------------------
    // LOAD REQUEST OWNER PROFILES
    // ----------------------------------------------------------

    final Map<String, Map<String, dynamic>>
        profilesById = {};

    if (requestOwnerIds.isNotEmpty) {
      final List<dynamic> profileData =
          await _supabase
              .from('profiles')
              .select(
                'id, full_name, avatar_url',
              )
              .inFilter(
                'id',
                requestOwnerIds.toList(),
              );

      for (final profile in profileData) {
        final Map<String, dynamic> profileMap =
            Map<String, dynamic>.from(profile);

        final String profileId =
            _safeText(profileMap['id']);

        if (profileId.isNotEmpty) {
          profilesById[profileId] =
              profileMap;
        }
      }
    }

    // ----------------------------------------------------------
    // COMBINE RESPONSE + REQUEST + REQUEST OWNER PROFILE
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> combined =
        [];

    for (final response in responses) {
      final String requestId =
          _safeText(
        response['request_id'],
      );

      final request =
          requestsById[requestId];

      final String ownerId =
          _safeText(
        request?['user_id'],
      );

      final profile =
          profilesById[ownerId];

      combined.add({
        ...response,

        'request_title':
            _safeText(
          request?['title'],
          'Help Request',
        ),

        'request_description':
            _safeText(
          request?['description'],
        ),

        'request_owner_name':
            _safeText(
          profile?['full_name'],
          'Sisonke Member',
        ),

        'request_owner_avatar_url':
            _safeText(
          profile?['avatar_url'],
        ),
      });
    }

    _myResponses = combined;
  }

  // ============================================================
  // REALTIME LISTENERS
  // ============================================================

  void _listenForChanges() {
    final user =
        _supabase.auth.currentUser;

    if (user == null) return;

    _responsesChannel = _supabase
        .channel(
          'my-help-responses-${user.id}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'help_responses',
          callback: (payload) {
            _loadAllActivity();
          },
        )
        .subscribe();

    _requestsChannel = _supabase
        .channel(
          'my-help-requests-${user.id}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'help_requests',
          callback: (payload) {
            _loadAllActivity();
          },
        )
        .subscribe();
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

    if (text.isEmpty ||
        text == 'null') {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
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

      final Duration difference =
          DateTime.now()
              .difference(date);

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
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;

      case 'completed':
        return Colors.green;

      case 'declined':
        return Colors.red;

      case 'cancelled':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.blue;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadAllActivity();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();

    if (_responsesChannel != null) {
      _supabase.removeChannel(
        _responsesChannel!,
      );
    }

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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF1F2937),

        title: const Text(
          'My Help Activity',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon:
                const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],

        bottom: TabBar(
          controller: _tabController,

          labelColor:
              const Color(0xFFFFB300),

          unselectedLabelColor:
              const Color(0xFF6B7280),

          indicatorColor:
              const Color(0xFFFFB300),

          tabs: const [
            Tab(
              icon: Icon(
                Icons.inbox_outlined,
              ),
              text: 'Received',
            ),
            Tab(
              icon: Icon(
                Icons.volunteer_activism,
              ),
              text: 'My Responses',
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller:
                      _tabController,

                  children: [
                    _buildReceivedTab(),
                    _buildMyResponsesTab(),
                  ],
                ),
    );
  }

  // ============================================================
  // RECEIVED TAB
  // ============================================================

  Widget _buildReceivedTab() {
    if (_responsesToMyRequests.isEmpty) {
      return _buildEmptyState(
        icon:
            Icons.inbox_outlined,
        title:
            'No responses yet',
        message:
            'When someone offers to help with one of your requests, their response will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(16),

        itemCount:
            _responsesToMyRequests.length,

        itemBuilder:
            (context, index) {
          final response =
              _responsesToMyRequests[
                  index];

          return _buildReceivedResponseCard(
            response,
          );
        },
      ),
    );
  }

  // ============================================================
  // MY RESPONSES TAB
  // ============================================================

  Widget _buildMyResponsesTab() {
    if (_myResponses.isEmpty) {
      return _buildEmptyState(
        icon:
            Icons.volunteer_activism_outlined,
        title:
            'No responses yet',
        message:
            'When you respond to a Help Request, it will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(16),

        itemCount:
            _myResponses.length,

        itemBuilder:
            (context, index) {
          final response =
              _myResponses[index];

          return _buildMyResponseCard(
            response,
          );
        },
      ),
    );
  }

  // ============================================================
  // RECEIVED RESPONSE CARD
  // ============================================================

  Widget _buildReceivedResponseCard(
    Map<String, dynamic> response,
  ) {
    final String responderName =
        _safeText(
      response['responder_name'],
      'Sisonke Member',
    );

    final String avatarUrl =
        _safeText(
      response[
          'responder_avatar_url'],
    );

    final String requestTitle =
        _safeText(
      response['request_title'],
      'Help Request',
    );

    final String message =
        _safeText(
      response['message'],
      'No message provided.',
    );

    final String availability =
        _safeText(
      response['availability'],
      'Not specified',
    );

    final String contactMethod =
        _safeText(
      response['contact_method'],
      'Not specified',
    );

    final String status =
        _safeText(
      response['status'],
      'pending',
    );

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(18),

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
            Text(
              requestTitle,

              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildAvatar(
                  avatarUrl,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        responderName,

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        _formatDate(
                          response[
                              'created_at'],
                        ),

                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildStatusChip(
                  status,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              message,

              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color:
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 12),

            _buildDetailRow(
              Icons.access_time,
              'Availability',
              availability,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              Icons.contact_phone_outlined,
              'Contact',
              contactMethod,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MY RESPONSE CARD
  // ============================================================

  Widget _buildMyResponseCard(
    Map<String, dynamic> response,
  ) {
    final String ownerName =
        _safeText(
      response[
          'request_owner_name'],
      'Sisonke Member',
    );

    final String avatarUrl =
        _safeText(
      response[
          'request_owner_avatar_url'],
    );

    final String requestTitle =
        _safeText(
      response['request_title'],
      'Help Request',
    );

    final String message =
        _safeText(
      response['message'],
      'No message provided.',
    );

    final String availability =
        _safeText(
      response['availability'],
      'Not specified',
    );

    final String contactMethod =
        _safeText(
      response['contact_method'],
      'Not specified',
    );

    final String status =
        _safeText(
      response['status'],
      'pending',
    );

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(18),

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    requestTitle,

                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                _buildStatusChip(
                  status,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildAvatar(
                  avatarUrl,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        ownerName,

                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        'Request owner',

                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              'Your response',

              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              message,

              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color:
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 12),

            _buildDetailRow(
              Icons.access_time,
              'Availability',
              availability,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              Icons.contact_phone_outlined,
              'Contact',
              contactMethod,
            ),

            const SizedBox(height: 8),

            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Responded',
              _formatDate(
                response['created_at'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(
    String avatarUrl,
  ) {
    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 25,

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
      radius: 25,

      backgroundColor:
          const Color(0xFFE5E7EB),

      backgroundImage:
          NetworkImage(
        avatarUrl,
      ),

      onBackgroundImageError:
          (exception, stackTrace) {},
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
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            color.withAlpha(20),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              const Color(
            0xFF6B7280,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          '$label: ',

          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF4B5563),
          ),
        ),

        Expanded(
          child: Text(
            value,

            style: const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(24),

        children: [
          const SizedBox(height: 100),

          Icon(
            icon,
            size: 70,
            color: Colors.grey,
          ),

          const SizedBox(height: 20),

          Text(
            title,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            message,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
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
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 65,
              color: Colors.red,
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load your activity',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              _errorMessage ??
                  'An unknown error occurred.',

              textAlign:
                  TextAlign.center,

              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _loadAllActivity,

              icon:
                  const Icon(
                Icons.refresh,
              ),

              label:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
