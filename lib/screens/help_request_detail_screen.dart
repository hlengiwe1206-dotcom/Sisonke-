import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const HelpRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState
    extends State<HelpRequestDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _submitting = false;

  Map<String, dynamic>? _post;
  Map<String, dynamic>? _requester;
  List<Map<String, dynamic>> _offers = [];
  Map<String, dynamic>? _connection;
  Map<String, dynamic>? _conversation;
  List<Map<String, dynamic>> _messages = [];

  final TextEditingController _offerController =
      TextEditingController();

  final TextEditingController _messageController =
      TextEditingController();

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _offersChannel;
  RealtimeChannel? _connectionsChannel;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();

    if (_messagesChannel != null) {
      _supabase.removeChannel(_messagesChannel!);
    }

    if (_offersChannel != null) {
      _supabase.removeChannel(_offersChannel!);
    }

    if (_connectionsChannel != null) {
      _supabase.removeChannel(_connectionsChannel!);
    }

    super.dispose();
  }

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    return value.toString();
  }

  bool _boolValue(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return fallback;
  }

  DateTime? _dateValue(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic value) {
    final date = _dateValue(value);

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatDateTime(dynamic value) {
    final date = _dateValue(value);

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} $hour:$minute $period';
  }

  String _displayName(Map<String, dynamic>? profile) {
    if (profile == null) {
      return 'Community Member';
    }

    final firstName =
        _stringValue(profile['first_name']).trim();

    final fullName =
        _stringValue(profile['full_name']).trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (firstName.isNotEmpty) {
      return firstName;
    }

    return 'Community Member';
  }

  String _initials(Map<String, dynamic>? profile) {
    final name = _displayName(profile);

    final parts = name
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'C';
    }

    if (parts.length == 1) {
      return parts.first.substring(
        0,
        parts.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  Widget _avatar(
    Map<String, dynamic>? profile, {
    double size = 46,
  }) {
    final avatarUrl =
        _stringValue(profile?['avatar_url']).trim();

    if (avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _avatarFallback(
              profile,
              size,
            );
          },
        ),
      );
    }

    return _avatarFallback(
      profile,
      size,
    );
  }

  Widget _avatarFallback(
    Map<String, dynamic>? profile,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F3EE),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(profile),
        style: TextStyle(
          fontSize: size * .30,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF007749),
        ),
      ),
    );
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final requestId = widget.request['id'];

      if (requestId == null) {
        throw Exception(
          'This help request does not have a valid ID.',
        );
      }

      final postId = widget.request['post_id'];
      final requesterId =
          widget.request['requester_id'];

      Map<String, dynamic>? post;

      if (postId != null) {
        final postResponse = await _supabase
            .from('posts')
            .select(
              'id,user_id,type,title,content,status,created_at',
            )
            .eq('id', postId)
            .maybeSingle();

        if (postResponse != null) {
          post = Map<String, dynamic>.from(
            postResponse,
          );
        }
      }

      final effectiveRequesterId =
          requesterId ??
          post?['user_id'] ??
          widget.request['user_id'];

      Map<String, dynamic>? requester;

      if (effectiveRequesterId != null) {
        final profileResponse = await _supabase
            .from('profiles')
            .select(
              'id,first_name,full_name,avatar_url',
            )
            .eq('id', effectiveRequesterId)
            .maybeSingle();

        if (profileResponse != null) {
          requester = Map<String, dynamic>.from(
            profileResponse,
          );
        }
      }

      final offersResponse = await _supabase
          .from('help_offers')
          .select()
          .eq(
            'help_request_id',
            requestId,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final offers = <Map<String, dynamic>>[];

      for (final item in offersResponse) {
        offers.add(
          Map<String, dynamic>.from(item),
        );
      }

      Map<String, dynamic>? connection;

      final connectionResponse = await _supabase
          .from('help_connections')
          .select()
          .eq(
            'help_request_id',
            requestId,
          )
          .maybeSingle();

      if (connectionResponse != null) {
        connection = Map<String, dynamic>.from(
          connectionResponse,
        );
      }

      Map<String, dynamic>? conversation;

      if (connection != null &&
          connection['id'] != null) {
        final conversationResponse =
            await _supabase
                .from('conversations')
                .select()
                .eq(
                  'connection_id',
                  connection['id'],
                )
                .maybeSingle();

        if (conversationResponse != null) {
          conversation =
              Map<String, dynamic>.from(
            conversationResponse,
          );
        }
      }

      final messages = <Map<String, dynamic>>[];

      if (conversation != null &&
          conversation['id'] != null) {
        final messagesResponse = await _supabase
            .from('messages')
            .select()
            .eq(
              'conversation_id',
              conversation['id'],
            )
            .order(
              'created_at',
              ascending: true,
            );

        for (final item in messagesResponse) {
          messages.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _post = post;
        _requester = requester;
        _offers = offers;
        _connection = connection;
        _conversation = conversation;
        _messages = messages;
        _loading = false;
      });

      _subscribeToRealtime(
        requestId,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnackBar(
        'Could not load this help request: $error',
        isError: true,
      );
    }
  }

  void _subscribeToRealtime(dynamic requestId) {
    try {
      _offersChannel = _supabase
          .channel(
            'help-offers-$requestId',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'help_offers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'help_request_id',
              value: requestId.toString(),
            ),
            callback: (_) {
              _reloadOffers();
            },
          )
          .subscribe();

      _connectionsChannel = _supabase
          .channel(
            'help-connections-$requestId',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'help_connections',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'help_request_id',
              value: requestId.toString(),
            ),
            callback: (_) {
              _loadDetails();
            },
          )
          .subscribe();

      if (_conversation?['id'] != null) {
        _messagesChannel = _supabase
            .channel(
              'messages-${_conversation!['id']}',
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'conversation_id',
                value:
                    _conversation!['id'].toString(),
              ),
              callback: (_) {
                _reloadMessages();
              },
            )
            .subscribe();
      }
    } catch (_) {
      // Realtime is helpful but should never prevent
      // the screen from functioning normally.
    }
  }

  Future<void> _reloadOffers() async {
    try {
      final requestId = widget.request['id'];

      if (requestId == null) return;

      final response = await _supabase
          .from('help_offers')
          .select()
          .eq(
            'help_request_id',
            requestId,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final offers = <Map<String, dynamic>>[];

      for (final item in response) {
        offers.add(
          Map<String, dynamic>.from(item),
        );
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
      });
    } catch (_) {}
  }

  Future<void> _reloadMessages() async {
    try {
      final conversationId =
          _conversation?['id'];

      if (conversationId == null) return;

      final response = await _supabase
          .from('messages')
          .select()
          .eq(
            'conversation_id',
            conversationId,
          )
          .order(
            'created_at',
            ascending: true,
          );

      final messages = <Map<String, dynamic>>[];

      for (final item in response) {
        messages.add(
          Map<String, dynamic>.from(item),
        );
      }

      if (!mounted) return;

      setState(() {
        _messages = messages;
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadProfile(
    dynamic userId,
  ) async {
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select(
            'id,first_name,full_name,avatar_url',
          )
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(
        response,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _createOffer() async {
    if (_submitting) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showSnackBar(
        'Please sign in to offer help.',
        isError: true,
      );
      return;
    }

    final requestId = widget.request['id'];

    if (requestId == null) {
      _showSnackBar(
        'This help request is missing its ID.',
        isError: true,
      );
      return;
    }

    final message = _offerController.text.trim();

    if (message.isEmpty) {
      _showSnackBar(
        'Please tell the requester how you can help.',
        isError: true,
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final existing = await _supabase
          .from('help_offers')
          .select('id,status')
          .eq(
            'help_request_id',
            requestId,
          )
          .eq(
            'helper_id',
            user.id,
          )
          .maybeSingle();

      if (existing != null) {
        throw Exception(
          'You have already offered to help with this request.',
        );
      }

      await _supabase.from('help_offers').insert({
        'help_request_id': requestId,
        'helper_id': user.id,
        'message': message,
        'status': 'pending',
      });

      _offerController.clear();

      await _reloadOffers();

      if (!mounted) return;

      _showSnackBar(
        'Your offer to help has been sent.',
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _acceptOffer(
    Map<String, dynamic> offer,
  ) async {
    if (_submitting) return;

    final offerId = offer['id'];

    if (offerId == null) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _supabase.rpc(
        'accept_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      await _loadDetails();

      if (!mounted) return;

      _showSnackBar(
        'Help offer accepted. You can now connect.',
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _withdrawOffer(
    Map<String, dynamic> offer,
  ) async {
    if (_submitting) return;

    final offerId = offer['id'];

    if (offerId == null) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _supabase.rpc(
        'withdraw_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      await _reloadOffers();

      if (!mounted) return;

      _showSnackBar(
        'Your offer has been withdrawn.',
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _completeConnection() async {
    if (_submitting) return;

    final connectionId = _connection?['id'];

    if (connectionId == null) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _supabase.rpc(
        'complete_help_connection',
        params: {
          'p_connection_id': connectionId,
        },
      );

      await _loadDetails();

      if (!mounted) return;

      _showSnackBar(
        'Help connection marked as completed.',
      );
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final conversationId =
        _conversation?['id'];

    if (conversationId == null) {
      _showSnackBar(
        'Messaging becomes available after a help offer is accepted.',
        isError: true,
      );
      return;
    }

    final content =
        _messageController.text.trim();

    if (content.isEmpty) {
      return;
    }

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content,
      });

      await _reloadMessages();
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF007749),
      ),
    );
  }

  String _requestTitle() {
    final title =
        _stringValue(_post?['title']).trim();

    if (title.isNotEmpty) {
      return title;
    }

    final requestTitle =
        _stringValue(widget.request['title']).trim();

    if (requestTitle.isNotEmpty) {
      return requestTitle;
    }

    return 'Help Request';
  }

  String _requestDescription() {
    final content =
        _stringValue(_post?['content']).trim();

    if (content.isNotEmpty) {
      return content;
    }

    return _stringValue(
      widget.request['description'],
    ).trim();
  }

  String _requestCategory() {
    final category =
        _stringValue(widget.request['category'])
            .trim();

    return category.isEmpty
        ? 'General Assistance'
        : category;
  }

  String _requestLocation() {
    return _stringValue(
      widget.request['location'],
    ).trim();
  }

  bool _isUrgent() {
    return _boolValue(
      widget.request['urgent'],
    );
  }

  String _requestStatus() {
    final status =
        _stringValue(widget.request['status'])
            .trim()
            .toLowerCase();

    if (status.isNotEmpty) {
      return status;
    }

    return _stringValue(
      _post?['status'],
    ).trim().toLowerCase();
  }

  bool _isRequester() {
    final user = _supabase.auth.currentUser;

    if (user == null) return false;

    final requesterId =
        widget.request['requester_id'] ??
            _post?['user_id'] ??
            widget.request['user_id'];

    return requesterId == user.id;
  }

  bool _hasMyOffer() {
    final user = _supabase.auth.currentUser;

    if (user == null) return false;

    return _offers.any(
      (offer) =>
          offer['helper_id'] == user.id,
    );
  }

  Map<String, dynamic>? _myOffer() {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    for (final offer in _offers) {
      if (offer['helper_id'] == user.id) {
        return offer;
      }
    }

    return null;
  }

  bool _connectionIncludesCurrentUser() {
    final user = _supabase.auth.currentUser;

    if (user == null || _connection == null) {
      return false;
    }

    return _connection!['requester_id'] == user.id ||
        _connection!['helper_id'] == user.id;
  }

  Map<String, dynamic>? _otherPersonProfile() {
    final user = _supabase.auth.currentUser;

    if (user == null || _connection == null) {
      return null;
    }

    final otherId =
        _connection!['requester_id'] == user.id
            ? _connection!['helper_id']
            : _connection!['requester_id'];

    for (final offer in _offers) {
      if (offer['helper_id'] == otherId) {
        final profile =
            offer['_profile'];

        if (profile is Map) {
          return Map<String, dynamic>.from(
            profile,
          );
        }
      }
    }

    return null;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF007749);

      case 'matched':
      case 'accepted':
      case 'active':
        return const Color(0xFF004B87);

      case 'completed':
        return Colors.grey.shade700;

      case 'withdrawn':
      case 'declined':
      case 'cancelled':
        return Colors.red.shade700;

      default:
        return const Color(0xFF69707A);
    }
  }

  String _prettyStatus(String status) {
    if (status.isEmpty) {
      return 'OPEN';
    }

    return status
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F2),
      appBar: AppBar(
        title: const Text(
          'Help Request',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading
                ? null
                : _loadDetails,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007749),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF007749),
              onRefresh: _loadDetails,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  40,
                ),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  _buildRequestCard(),
                  const SizedBox(height: 14),
                  _buildActionArea(),
                  const SizedBox(height: 14),
                  _buildOffersSection(),
                  const SizedBox(height: 14),
                  _buildConnection(),
                  const SizedBox(height: 14),
                  _buildMessages(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final status = _requestStatus();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _avatar(
                  _requester,
                  size: 54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName(_requester),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Community Help Request',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _requestTitle(),
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            if (_isUrgent()) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEA),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.priority_high_rounded,
                      size: 17,
                      color: Color(0xFFDE3831),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'URGENT REQUEST',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDE3831),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRequestCard() {
    final description =
        _requestDescription();

    final category =
        _requestCategory();

    final location =
        _requestLocation();

    final createdAt =
        widget.request['created_at'] ??
            _post?['created_at'];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 14),
            if (description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF3E454D),
                ),
              ),
            if (description.isNotEmpty)
              const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoPill(
                  Icons.category_outlined,
                  category,
                ),
                if (location.isNotEmpty)
                  _infoPill(
                    Icons.location_on_outlined,
                    location,
                  ),
                if (_formatDate(createdAt)
                    .isNotEmpty)
                  _infoPill(
                    Icons.calendar_today_outlined,
                    _formatDate(createdAt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF007749),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E454D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    final isRequester = _isRequester();
    final myOffer = _myOffer();
    final status = _requestStatus();

    if (status == 'completed') {
      return _informationCard(
        icon: Icons.check_circle_outline,
        title: 'Help Completed',
        message:
            'This community help request has been marked as completed.',
      );
    }

    if (isRequester) {
      return _requesterActionCard();
    }

    if (myOffer != null) {
      final offerStatus =
          _stringValue(myOffer['status'])
              .toLowerCase();

      if (offerStatus == 'pending') {
        return _myPendingOfferCard(
          myOffer,
        );
      }

      if (offerStatus == 'accepted') {
        return _informationCard(
          icon: Icons.handshake_outlined,
          title: 'You are helping',
          message:
              'Your offer has been accepted. You can now connect with the requester below.',
        );
      }

      if (offerStatus == 'declined') {
        return _informationCard(
          icon: Icons.info_outline,
          title: 'Offer Declined',
          message:
              'Your previous offer was not selected for this request.',
        );
      }

      if (offerStatus == 'withdrawn') {
        return _offerForm();
      }
    }

    if (status == 'open') {
      return _offerForm();
    }

    return _informationCard(
      icon: Icons.info_outline,
      title: 'Request Status',
      message:
          'This request is no longer accepting new offers.',
    );
  }

  Widget _requesterActionCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF5F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.person_outline,
              color: Color(0xFF007749),
              size: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Help Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF005A38),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _offers.isEmpty
                        ? 'No one has offered to help yet. We will show offers here as they arrive.'
                        : '${_offers.length} ${_offers.length == 1 ? 'person has' : 'people have'} offered to help.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF365047),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myPendingOfferCard(
    Map<String, dynamic> offer,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.volunteer_activism_outlined,
                  color: Color(0xFF007749),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Your offer has been sent',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB81C)
                        .withOpacity(.15),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A6400),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_stringValue(
              offer['message'],
            ).isNotEmpty)
              Text(
                _stringValue(
                  offer['message'],
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF3E454D),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Waiting for the requester to review your offer.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed:
                  _submitting
                      ? null
                      : () => _withdrawOffer(offer),
              icon: const Icon(
                Icons.undo_outlined,
                size: 18,
              ),
              label: const Text(
                'Withdraw Offer',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerForm() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  color: Color(0xFF007749),
                ),
                SizedBox(width: 10),
                Text(
                  'I Want to Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tell the requester how you can assist.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _offerController,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              decoration: InputDecoration(
                hintText:
                    'Example: I can help you with transport / food / job applications...',
                filled: true,
                fillColor:
                    const Color(0xFFF8F7F2),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                focusedBorder:
                    const OutlineInputBorder(
                  borderRadius:
                      BorderRadius.all(
                    Radius.circular(14),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFF007749),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _submitting
                        ? null
                        : _createOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF007749),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade300,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.volunteer_activism,
                      ),
                label: Text(
                  _submitting
                      ? 'Sending...'
                      : 'Offer Help',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 26,
              color: const Color(0xFF007749),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF3E454D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'People Who Can Help',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F0),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_offers.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF007749),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_offers.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No offers yet. Be the first person to help.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0;
                      i < _offers.length;
                      i++) ...[
                    _buildOfferCard(
                      _offers[i],
                    ),
                    if (i !=
                        _offers.length - 1)
                      const Divider(
                        height: 28,
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
  ) {
    final helperId =
        offer['helper_id'];

    final currentUserId =
        _supabase.auth.currentUser?.id;

    final isMyOffer =
        helperId == currentUserId;

    final status =
        _stringValue(
          offer['status'],
        ).toLowerCase();

    final message =
        _stringValue(
          offer['message'],
        ).trim();

    final createdAt =
        offer['created_at'];

    final profile =
        offer['_profile']
            is Map
        ? Map<String, dynamic>.from(
            offer['_profile'],
          )
        : null;

    return FutureBuilder<
        Map<String, dynamic>?>(
      future: profile == null
          ? _loadProfile(helperId)
          : Future.value(profile),
      builder: (
        context,
        snapshot,
      ) {
        final helperProfile =
            snapshot.data ?? profile;

        if (helperProfile != null) {
          offer['_profile'] =
              helperProfile;
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _avatar(
              helperProfile,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _displayName(
                            helperProfile,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF111111),
                          ),
                        ),
                      ),
                      _offerStatusChip(
                        status,
                      ),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            Color(0xFF3E454D),
                      ),
                    ),
                  ],
                  if (_formatDateTime(
                    createdAt,
                  ).isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      _formatDateTime(
                        createdAt,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],
                  if (_isRequester() &&
                      status == 'pending') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed:
                            _submitting
                                ? null
                                : () => _acceptOffer(
                                    offer,
                                  ),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF007749,
                          ),
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: const Text(
                          'Accept Offer',
                        ),
                      ),
                    ),
                  ],
                  if (isMyOffer &&
                      status == 'pending') ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed:
                          _submitting
                              ? null
                              : () => _withdrawOffer(
                                  offer,
                                ),
                      icon: const Icon(
                        Icons.undo_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Withdraw Offer',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _offerStatusChip(
    String status,
  ) {
    final color = _statusColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _prettyStatus(status),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConnection() {
    if (_connection == null) {
      return const SizedBox.shrink();
    }

    final status =
        _stringValue(
          _connection!['status'],
        ).toLowerCase();

    final connectionDate =
        _connection!['created_at'];

    final otherPersonId =
        _connection!['requester_id'] ==
                _supabase.auth.currentUser?.id
            ? _connection!['helper_id']
            : _connection!['requester_id'];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF5F0),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  color: Color(0xFF007749),
                  size: 27,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Help Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF005A38),
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'A connection has been created between the requester and helper.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF365047),
              ),
            ),
            if (_formatDateTime(
              connectionDate,
            ).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Connected ${_formatDateTime(connectionDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (status != 'completed' &&
                _connectionIncludesCurrentUser()) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed:
                      _submitting
                          ? null
                          : _completeConnection,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(
                      0xFF007749,
                    ),
                    side: const BorderSide(
                      color:
                          Color(0xFF007749),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        13,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'Mark Help as Completed',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_conversation == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE6E7E8),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF007749),
                ),
                SizedBox(width: 10),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_messages.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Text(
                  'Start the conversation.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              )
            else
              Column(
                children: _messages
                    .map(
                      _buildMessageBubble,
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction:
                        TextInputAction.newline,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Write a message...',
                      filled: true,
                      fillColor:
                          const Color(
                        0xFFF8F7F2,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey
                                  .shade200,
                        ),
                      ),
                      focusedBorder:
                          const OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .all(
                          Radius.circular(
                            14,
                          ),
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Color(
                            0xFF007749,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color:
                      const Color(0xFF007749),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  child: InkWell(
                    onTap: _sendMessage,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
  ) {
    final userId =
        _supabase.auth.currentUser?.id;

    final isMine =
        message['sender_id'] == userId;

    final content =
        _stringValue(
          message['content'],
        );

    final createdAt =
        message['created_at'];

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 310,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 9,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? const Color(0xFF007749)
              : const Color(0xFFF1F3F2),
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              15,
            ),
            topRight:
                const Radius.circular(
              15,
            ),
            bottomLeft:
                Radius.circular(
              isMine ? 15 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMine ? 4 : 15,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isMine
                    ? Colors.white
                    : const Color(
                        0xFF33383D,
                      ),
              ),
            ),
            if (_formatDateTime(
              createdAt,
            ).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatDateTime(
                  createdAt,
                ),
                style: TextStyle(
                  fontSize: 9,
                  color: isMine
                      ? Colors.white
                          .withOpacity(.75)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
