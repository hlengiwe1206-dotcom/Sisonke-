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
  final SupabaseClient _supabase = Supabase.instance.client;

  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _responsesToMyRequests = [];
  List<Map<String, dynamic>> _myResponses = [];

  final Set<String> _processingResponseIds = {};

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
  // LOAD ALL ACTIVITY
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
      debugPrint('Error loading help activity: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // LOAD RESPONSES TO MY REQUESTS
  // ============================================================

  Future<void> _loadResponsesToMyRequests() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _responsesToMyRequests = [];
      return;
    }

    final requestData = await _supabase
        .from('help_requests')
        .select()
        .eq('user_id', user.id)
        .order(
          'created_at',
          ascending: false,
        );

    final List<Map<String, dynamic>> myRequests =
        List<Map<String, dynamic>>.from(requestData);

    if (myRequests.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final requestIds = myRequests
        .map((request) => _safeText(request['id']))
        .where((id) => id.isNotEmpty)
        .toList();

    if (requestIds.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final Map<String, Map<String, dynamic>> requestsById = {};

    for (final request in myRequests) {
      final requestId = _safeText(request['id']);

      if (requestId.isNotEmpty) {
        requestsById[requestId] = request;
      }
    }

    final responseData = await _supabase
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
        List<Map<String, dynamic>>.from(responseData);

    if (responses.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final responderIds = responses
        .map(
          (response) =>
              _safeText(response['responder_id']),
        )
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profilesById = {};

    if (responderIds.isNotEmpty) {
      final profileData = await _supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url',
          )
          .inFilter(
            'id',
            responderIds,
          );

      for (final profile in profileData) {
        final profileMap =
            Map<String, dynamic>.from(profile);

        final profileId =
            _safeText(profileMap['id']);

        if (profileId.isNotEmpty) {
          profilesById[profileId] = profileMap;
        }
      }
    }

    final List<Map<String, dynamic>> combined = [];

    for (final response in responses) {
      final requestId =
          _safeText(response['request_id']);

      final responderId =
          _safeText(response['responder_id']);

      final request = requestsById[requestId];
      final profile = profilesById[responderId];

      combined.add({
        ...response,
        'request_title': _safeText(
          request?['title'],
          'Help Request',
        ),
        'request_description': _safeText(
          request?['description'],
        ),
        'responder_name': _safeText(
          profile?['full_name'],
          'Sisonke Member',
        ),
        'responder_avatar_url': _safeText(
          profile?['avatar_url'],
        ),
      });
    }

    _responsesToMyRequests = combined;
  }

  // ============================================================
  // LOAD MY RESPONSES
  // ============================================================

  Future<void> _loadMyResponses() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _myResponses = [];
      return;
    }

    final responseData = await _supabase
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
        List<Map<String, dynamic>>.from(responseData);

    if (responses.isEmpty) {
      _myResponses = [];
      return;
    }

    final requestIds = responses
        .map(
          (response) =>
              _safeText(response['request_id']),
        )
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (requestIds.isEmpty) {
      _myResponses = [];
      return;
    }

    final requestData = await _supabase
        .from('help_requests')
        .select()
        .inFilter(
          'id',
          requestIds,
        );

    final Map<String, Map<String, dynamic>> requestsById = {};
    final Set<String> requestOwnerIds = {};

    for (final item in requestData) {
      final request =
          Map<String, dynamic>.from(item);

      final requestId =
          _safeText(request['id']);

      final ownerId =
          _safeText(request['user_id']);

      if (requestId.isNotEmpty) {
        requestsById[requestId] = request;
      }

      if (ownerId.isNotEmpty) {
        requestOwnerIds.add(ownerId);
      }
    }

    final Map<String, Map<String, dynamic>> profilesById = {};

    if (requestOwnerIds.isNotEmpty) {
      final profileData = await _supabase
          .from('profiles')
          .select(
            'id, full_name, avatar_url',
          )
          .inFilter(
            'id',
            requestOwnerIds.toList(),
          );

      for (final profile in profileData) {
        final profileMap =
            Map<String, dynamic>.from(profile);

        final profileId =
            _safeText(profileMap['id']);

        if (profileId.isNotEmpty) {
          profilesById[profileId] = profileMap;
        }
      }
    }

    final List<Map<String, dynamic>> combined = [];

    for (final response in responses) {
      final requestId =
          _safeText(response['request_id']);

      final request =
          requestsById[requestId];

      final ownerId =
          _safeText(request?['user_id']);

      final profile =
          profilesById[ownerId];

      combined.add({
        ...response,
        'request_title': _safeText(
          request?['title'],
          'Help Request',
        ),
        'request_description': _safeText(
          request?['description'],
        ),
        'request_owner_name': _safeText(
          profile?['full_name'],
          'Sisonke Member',
        ),
        'request_owner_avatar_url': _safeText(
          profile?['avatar_url'],
        ),
      });
    }

    _myResponses = combined;
  }

  // ============================================================
  // UPDATE RESPONSE STATUS
  // ============================================================

  Future<void> _updateResponseStatus({
    required Map<String, dynamic> response,
    required String newStatus,
  }) async {
    final responseId =
        _safeText(response['id']);

    final responderId =
        _safeText(response['responder_id']);

    final requestTitle =
        _safeText(
      response['request_title'],
      'your help request',
    );

    if (responseId.isEmpty) {
      _showError('Unable to identify this response.');
      return;
    }

    if (responderId.isEmpty) {
      _showError('Unable to identify the responder.');
      return;
    }

    setState(() {
      _processingResponseIds.add(responseId);
    });

    try {
      // Update the response.
      await _supabase
          .from('help_responses')
          .update({
            'status': newStatus,
          })
          .eq('id', responseId);

      // Create notification for responder.
      try {
        final title = newStatus == 'accepted'
            ? 'Your help response was accepted'
            : 'Your help response was declined';

        final body = newStatus == 'accepted'
            ? 'Your offer to help with "$requestTitle" has been accepted.'
            : 'Your response to "$requestTitle" was declined.';

        await _supabase
            .from('notifications')
            .insert({
          'user_id': responderId,
          'title': title,
          'body': body,
          'is_read': false,
        });
      } catch (notificationError) {
        debugPrint(
          'Notification error: $notificationError',
        );
      }

      // Update local data immediately.
      if (mounted) {
        setState(() {
          final index =
              _responsesToMyRequests.indexWhere(
            (item) =>
                _safeText(item['id']) ==
                responseId,
          );

          if (index != -1) {
            _responsesToMyRequests[index]['status'] =
                newStatus;
          }

          _processingResponseIds.remove(responseId);
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newStatus == 'accepted'
              ? Colors.green
              : Colors.red,
          content: Text(
            newStatus == 'accepted'
                ? 'Response accepted successfully.'
                : 'Response declined.',
          ),
        ),
      );

      await _loadAllActivity();
    } catch (error) {
      debugPrint(
        'Error updating response: $error',
      );

      if (mounted) {
        setState(() {
          _processingResponseIds.remove(responseId);
        });
      }

      _showError(
        'Unable to update response:\n$error',
      );
    }
  }

  // ============================================================
  // CONFIRM STATUS CHANGE
  // ============================================================

  Future<void> _confirmStatusChange({
    required Map<String, dynamic> response,
    required String newStatus,
  }) async {
    final responderName =
        _safeText(
      response['responder_name'],
      'this responder',
    );

    final isAccept =
        newStatus == 'accepted';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isAccept
                ? 'Accept Response?'
                : 'Decline Response?',
          ),
          content: Text(
            isAccept
                ? 'Are you sure you want to accept $responderName\'s offer to help?'
                : 'Are you sure you want to decline $responderName\'s response?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: isAccept
                    ? Colors.green
                    : Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                isAccept
                    ? 'Accept'
                    : 'Decline',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _updateResponseStatus(
      response: response,
      newStatus: newStatus,
    );
  }

  // ============================================================
  // REALTIME
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

    final text =
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

      final difference =
          DateTime.now().difference(date);

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
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration:
            const Duration(seconds: 5),
      ),
    );
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
          return _buildReceivedResponseCard(
            _responsesToMyRequests[index],
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
          return _buildMyResponseCard(
            _myResponses[index],
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
    final responderName = _safeText(
      response['responder_name'],
      'Sisonke Member',
    );

    final avatarUrl = _safeText(
      response['responder_avatar_url'],
    );

    final requestTitle = _safeText(
      response['request_title'],
      'Help Request',
    );

    final message = _safeText(
      response['message'],
      'No message provided.',
    );

    final availability = _safeText(
      response['availability'],
      'Not specified',
    );

    final contactMethod = _safeText(
      response['contact_method'],
      'Not specified',
    );

    final status = _safeText(
      response['status'],
      'pending',
    );

    final responseId =
        _safeText(response['id']);

    final isProcessing =
        _processingResponseIds.contains(
      responseId,
    );

    final isPending =
        status.toLowerCase() == 'pending';

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
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withAlpha(10),
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
                _buildStatusChip(status),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildAvatar(avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(
                          response['created_at'],
                        ),
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
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

            // ================================================
            // ACCEPT / DECLINE BUTTONS
            // ================================================

            if (isPending) ...[
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _confirmStatusChange(
                                response:
                                    response,
                                newStatus:
                                    'declined',
                              );
                            },
                      icon:
                          const Icon(
                        Icons.close,
                      ),
                      label:
                          const Text(
                        'Decline',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.red,
                        side:
                            const BorderSide(
                          color:
                              Colors.red,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _confirmStatusChange(
                                response:
                                    response,
                                newStatus:
                                    'accepted',
                              );
                            },
                      icon: isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check,
                            ),
                      label:
                          Text(
                        isProcessing
                            ? 'Processing'
                            : 'Accept',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.green,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
    final ownerName = _safeText(
      response['request_owner_name'],
      'Sisonke Member',
    );

    final avatarUrl = _safeText(
      response[
          'request_owner_avatar_url'],
    );

    final requestTitle = _safeText(
      response['request_title'],
      'Help Request',
    );

    final message = _safeText(
      response['message'],
      'No message provided.',
    );

    final availability = _safeText(
      response['availability'],
      'Not specified',
    );

    final contactMethod = _safeText(
      response['contact_method'],
      'Not specified',
    );

    final status = _safeText(
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
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withAlpha(10),
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
                _buildStatusChip(status),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildAvatar(avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                      const SizedBox(height: 3),
                      const Text(
                        'Request owner',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              'Your response',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
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
          NetworkImage(avatarUrl),
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
    final color =
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
            BorderRadius.circular(20),
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
              const Color(0xFF6B7280),
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
            style: const TextStyle(
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
