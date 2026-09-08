import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHelpActivityScreen extends StatefulWidget {
  const MyHelpActivityScreen({super.key});

  @override
  State<MyHelpActivityScreen> createState() =>
      _MyHelpActivityScreenState();
}

class _MyHelpActivityScreenState extends State<MyHelpActivityScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _responsesToMyRequests = [];
  List<Map<String, dynamic>> _myResponses = [];
  List<Map<String, dynamic>> _myRequests = [];

  final Set<String> _processingIds = {};

  RealtimeChannel? _responsesChannel;
  RealtimeChannel? _requestsChannel;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
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
        _loadMyRequests(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading activity: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // LOAD MY REQUESTS
  // ============================================================

  Future<void> _loadMyRequests() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _myRequests = [];
      return;
    }

    final data = await _supabase
        .from('help_requests')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    _myRequests = List<Map<String, dynamic>>.from(data);
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
        .order('created_at', ascending: false);

    final requests = List<Map<String, dynamic>>.from(requestData);

    if (requests.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final requestIds = requests
        .map((request) => _safeText(request['id']))
        .where((id) => id.isNotEmpty)
        .toList();

    if (requestIds.isEmpty) {
      _responsesToMyRequests = [];
      return;
    }

    final requestsById = <String, Map<String, dynamic>>{};

    for (final request in requests) {
      final id = _safeText(request['id']);

      if (id.isNotEmpty) {
        requestsById[id] = request;
      }
    }

    final responseData = await _supabase
        .from('help_responses')
        .select()
        .inFilter('request_id', requestIds)
        .order('created_at', ascending: false);

    final responses = List<Map<String, dynamic>>.from(responseData);

    final responderIds = responses
        .map((response) => _safeText(response['responder_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};

    if (responderIds.isNotEmpty) {
      final profileData = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', responderIds);

      for (final item in profileData) {
        final profile = Map<String, dynamic>.from(item);

        final id = _safeText(profile['id']);

        if (id.isNotEmpty) {
          profilesById[id] = profile;
        }
      }
    }

    final combined = <Map<String, dynamic>>[];

    for (final response in responses) {
      final request =
          requestsById[_safeText(response['request_id'])];

      final profile =
          profilesById[_safeText(response['responder_id'])];

      combined.add({
        ...response,
        'request_title': _safeText(
          request?['title'],
          'Help Request',
        ),
        'request_status': _safeText(
          request?['status'],
          'open',
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
        .eq('responder_id', user.id)
        .order('created_at', ascending: false);

    final responses = List<Map<String, dynamic>>.from(responseData);

    if (responses.isEmpty) {
      _myResponses = [];
      return;
    }

    final requestIds = responses
        .map((response) => _safeText(response['request_id']))
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
        .inFilter('id', requestIds);

    final requestsById = <String, Map<String, dynamic>>{};
    final ownerIds = <String>{};

    for (final item in requestData) {
      final request = Map<String, dynamic>.from(item);

      final requestId = _safeText(request['id']);

      if (requestId.isNotEmpty) {
        requestsById[requestId] = request;
      }

      final ownerId = _safeText(request['user_id']);

      if (ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }

    final profilesById = <String, Map<String, dynamic>>{};

    if (ownerIds.isNotEmpty) {
      final profileData = await _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', ownerIds.toList());

      for (final item in profileData) {
        final profile = Map<String, dynamic>.from(item);

        final profileId = _safeText(profile['id']);

        if (profileId.isNotEmpty) {
          profilesById[profileId] = profile;
        }
      }
    }

    final combined = <Map<String, dynamic>>[];

    for (final response in responses) {
      final request =
          requestsById[_safeText(response['request_id'])];

      final ownerId = _safeText(request?['user_id']);
      final owner = profilesById[ownerId];

      combined.add({
        ...response,
        'request_title': _safeText(
          request?['title'],
          'Help Request',
        ),
        'request_status': _safeText(
          request?['status'],
          'open',
        ),
        'request_owner_name': _safeText(
          owner?['full_name'],
          'Sisonke Member',
        ),
        'request_owner_avatar_url': _safeText(
          owner?['avatar_url'],
        ),
      });
    }

    _myResponses = combined;
  }

  // ============================================================
  // ACCEPT / DECLINE
  // ============================================================

  Future<void> _updateResponseStatus({
    required Map<String, dynamic> response,
    required String newStatus,
  }) async {
    final responseId = _safeText(response['id']);
    final responderId = _safeText(response['responder_id']);

    final requestTitle = _safeText(
      response['request_title'],
      'your help request',
    );

    if (responseId.isEmpty || responderId.isEmpty) {
      _showError('Unable to process this response.');
      return;
    }

    setState(() {
      _processingIds.add(responseId);
    });

    try {
      await _supabase
          .from('help_responses')
          .update({
            'status': newStatus,
          })
          .eq('id', responseId);

      final isAccepted = newStatus == 'accepted';

      await _createNotification(
        userId: responderId,
        title: isAccepted
            ? 'Your help response was accepted'
            : 'Your help response was declined',
        body: isAccepted
            ? 'Your offer to help with "$requestTitle" has been accepted.'
            : 'Your response to "$requestTitle" was declined.',
      );

      await _loadAllActivity();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              isAccepted ? Colors.green : Colors.red,
          content: Text(
            isAccepted
                ? 'Response accepted.'
                : 'Response declined.',
          ),
        ),
      );
    } catch (error) {
      _showError('Unable to update response: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(responseId);
        });
      }
    }
  }

  // ============================================================
  // COMPLETE HELP
  // ============================================================

  Future<void> _completeHelp(
    Map<String, dynamic> response,
  ) async {
    final responseId = _safeText(response['id']);
    final requestId = _safeText(response['request_id']);
    final responderId = _safeText(response['responder_id']);

    final requestTitle = _safeText(
      response['request_title'],
      'the help request',
    );

    if (responseId.isEmpty ||
        requestId.isEmpty ||
        responderId.isEmpty) {
      _showError('Unable to complete this help activity.');
      return;
    }

    setState(() {
      _processingIds.add(responseId);
    });

    try {
      await _supabase
          .from('help_responses')
          .update({
            'status': 'completed',
          })
          .eq('id', responseId);

      await _supabase
          .from('help_requests')
          .update({
            'status': 'completed',
          })
          .eq('id', requestId);

      await _createNotification(
        userId: responderId,
        title: 'Help completed successfully',
        body:
            'Your assistance with "$requestTitle" has been marked as completed. Thank you for helping a fellow South African!',
      );

      await _loadAllActivity();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.blue,
          content: Text('Help marked as completed.'),
        ),
      );
    } catch (error) {
      _showError('Unable to complete help: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(responseId);
        });
      }
    }
  }

  // ============================================================
  // CANCEL REQUEST
  // ============================================================

  Future<void> _cancelRequest(
    Map<String, dynamic> request,
  ) async {
    final requestId = _safeText(request['id']);

    final requestTitle = _safeText(
      request['title'],
      'this help request',
    );

    if (requestId.isEmpty) {
      _showError('Unable to cancel this request.');
      return;
    }

    setState(() {
      _processingIds.add(requestId);
    });

    try {
      // 1. Find all people who responded.
      final responseData = await _supabase
          .from('help_responses')
          .select('responder_id')
          .eq('request_id', requestId);

      final responses =
          List<Map<String, dynamic>>.from(responseData);

      // 2. Mark request as cancelled.
      await _supabase
          .from('help_requests')
          .update({
            'status': 'cancelled',
          })
          .eq('id', requestId);

      // 3. Notify everyone who responded.
      final responderIds = responses
          .map((response) => _safeText(response['responder_id']))
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final responderId in responderIds) {
        await _createNotification(
          userId: responderId,
          title: 'Help Request Cancelled',
          body:
              'The request "$requestTitle" is no longer active. Thank you for your willingness to help a fellow South African.',
        );
      }

      await _loadAllActivity();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Help request cancelled.'),
        ),
      );
    } catch (error) {
      _showError('Unable to cancel request: $error');
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(requestId);
        });
      }
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'is_read': false,
    });
  }

  // ============================================================
  // CONFIRM ACCEPT / DECLINE
  // ============================================================

  Future<void> _confirmResponseAction({
    required Map<String, dynamic> response,
    required String newStatus,
  }) async {
    final responderName = _safeText(
      response['responder_name'],
      'this member',
    );

    final isAccepted = newStatus == 'accepted';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isAccepted
                ? 'Accept Response?'
                : 'Decline Response?',
          ),
          content: Text(
            isAccepted
                ? 'Accept $responderName\'s offer to help?'
                : 'Decline $responderName\'s response?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAccepted ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: Text(
                isAccepted ? 'Accept' : 'Decline',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _updateResponseStatus(
        response: response,
        newStatus: newStatus,
      );
    }
  }

  // ============================================================
  // CONFIRM COMPLETE HELP
  // ============================================================

  Future<void> _confirmCompleteHelp(
    Map<String, dynamic> response,
  ) async {
    final responderName = _safeText(
      response['responder_name'],
      'this member',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Help?'),
          content: Text(
            'Has $responderName successfully completed the assistance?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Complete Help'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _completeHelp(response);
    }
  }

  // ============================================================
  // CONFIRM CANCEL REQUEST
  // ============================================================

  Future<void> _confirmCancelRequest(
    Map<String, dynamic> request,
  ) async {
    final requestTitle = _safeText(
      request['title'],
      'this help request',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Help Request?'),
          content: Text(
            'Are you sure you want to cancel "$requestTitle"? '
            'People who have already responded will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Keep Request'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cancelRequest(request);
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _listenForChanges() {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    _responsesChannel = _supabase
        .channel('my-help-responses-${user.id}')
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
        .channel('my-help-requests-${user.id}')
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
  // HELPERS
  // ============================================================

  String _safeText(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;

      case 'completed':
        return Colors.blue;

      case 'declined':
        return Colors.red;

      case 'cancelled':
        return Colors.grey;

      case 'pending':
        return Colors.orange;

      case 'open':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Future<void> _refresh() async {
    await _loadAllActivity();
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    if (_responsesChannel != null) {
      _supabase.removeChannel(_responsesChannel!);
    }

    if (_requestsChannel != null) {
      _supabase.removeChannel(_requestsChannel!);
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('My Help Activity'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.inbox_outlined),
              text: 'Received',
            ),
            Tab(
              icon: Icon(Icons.volunteer_activism),
              text: 'My Responses',
            ),
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'My Requests',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReceivedTab(),
                    _buildMyResponsesTab(),
                    _buildMyRequestsTab(),
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
        icon: Icons.inbox_outlined,
        title: 'No responses yet',
        message:
            'Responses to your Help Requests will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _responsesToMyRequests.length,
        itemBuilder: (context, index) {
          return _buildReceivedCard(
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
        icon: Icons.volunteer_activism,
        title: 'No responses yet',
        message:
            'Your offers to help will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myResponses.length,
        itemBuilder: (context, index) {
          return _buildMyResponseCard(
            _myResponses[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // MY REQUESTS TAB
  // ============================================================

  Widget _buildMyRequestsTab() {
    if (_myRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.list_alt,
        title: 'No Help Requests',
        message:
            'The Help Requests you create will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          return _buildMyRequestCard(
            _myRequests[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // RECEIVED RESPONSE CARD
  // ============================================================

  Widget _buildReceivedCard(
    Map<String, dynamic> response,
  ) {
    final responderName = _safeText(
      response['responder_name'],
      'Sisonke Member',
    );

    final requestTitle = _safeText(
      response['request_title'],
      'Help Request',
    );

    final message = _safeText(
      response['message'],
      'No message provided.',
    );

    final status = _safeText(
      response['status'],
      'pending',
    );

    final responseId = _safeText(response['id']);

    final isProcessing =
        _processingIds.contains(responseId);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    requestTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              responderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 18),

            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _confirmResponseAction(
                                response: response,
                                newStatus: 'declined',
                              );
                            },
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              _confirmResponseAction(
                                response: response,
                                newStatus: 'accepted',
                              );
                            },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),

            if (status == 'accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          _confirmCompleteHelp(response);
                        },
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Complete Help'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
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
    final requestTitle = _safeText(
      response['request_title'],
      'Help Request',
    );

    final ownerName = _safeText(
      response['request_owner_name'],
      'Sisonke Member',
    );

    final message = _safeText(
      response['message'],
      'No message provided.',
    );

    final status = _safeText(
      response['status'],
      'pending',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    requestTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Text('Request owner: $ownerName'),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MY REQUEST CARD
  // ============================================================

  Widget _buildMyRequestCard(
    Map<String, dynamic> request,
  ) {
    final title = _safeText(
      request['title'],
      'Help Request',
    );

    final description = _safeText(
      request['description'],
      '',
    );

    final status = _safeText(
      request['status'],
      'open',
    );

    final requestId = _safeText(
      request['id'],
    );

    final isProcessing =
        _processingIds.contains(
      requestId,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description),
            ],
            const SizedBox(height: 18),

            if (status == 'open')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          _confirmCancelRequest(
                            request,
                          );
                        },
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text(
                    'Cancel Request',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),

            if (status == 'completed')
              const Text(
                '✓ Help completed successfully',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (status == 'cancelled')
              const Text(
                'This request was cancelled.',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
  ) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ElevatedButton(
        onPressed: _loadAllActivity,
        child: const Text('Try Again'),
      ),
    );
  }
}
