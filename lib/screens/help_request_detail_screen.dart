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
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final TextEditingController _offerController =
      TextEditingController();

  final TextEditingController _messageController =
      TextEditingController();

  bool _loading = true;
  bool _submittingOffer = false;
  bool _acceptingOffer = false;
  bool _sendingMessage = false;
  bool _completingConnection = false;

  Map<String, dynamic> _post = {};
  Map<String, dynamic> _requester = {};

  List<Map<String, dynamic>> _offers = [];

  Map<String, dynamic>? _connection;
  String? _conversationId;

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BASIC HELPERS
  // ============================================================

  String _text(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) return fallback;

    final String valueText =
        value.toString().trim();

    if (valueText.isEmpty ||
        valueText == 'null') {
      return fallback;
    }

    return valueText;
  }

  bool _bool(dynamic value) {
    if (value is bool) return value;

    final String valueText =
        value?.toString().toLowerCase() ?? '';

    return valueText == 'true' ||
        valueText == '1' ||
        valueText == 'yes';
  }

  String get _requestId =>
      _text(widget.request['id']);

  String get _requesterId =>
      _text(widget.request['requester_id']);

  String get _currentUserId =>
      _supabase.auth.currentUser?.id ?? '';

  bool get _isRequester =>
      _currentUserId.isNotEmpty &&
      _currentUserId == _requesterId;

  String get _title =>
      _text(
        _post['title'] ??
            widget.request['title'],
        'Community Help Request',
      );

  String get _description =>
      _text(
        _post['content'] ??
            widget.request['description'],
        'No additional information has been provided.',
      );

  String get _category =>
      _text(
        widget.request['category'],
        'General Assistance',
      );

  String get _location =>
      _text(
        widget.request['location'],
        'Location not specified',
      );

  String get _status =>
      _text(
        widget.request['status'],
        'open',
      ).toLowerCase();

  bool get _urgent =>
      _bool(widget.request['urgent']);

  bool get _isOpen =>
      _status == 'open' ||
      _status == 'active' ||
      _status == 'pending';

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> _loadDetails() async {
    try {
      if (_requestId.isEmpty) {
        throw Exception(
          'This help request has no ID.',
        );
      }

      // ----------------------------------------------------------
      // LOAD PARENT POST
      // ----------------------------------------------------------

      final postId =
          _text(widget.request['post_id']);

      if (postId.isNotEmpty) {
        try {
          final post =
              await _supabase
                  .from('posts')
                  .select(
                    'id, user_id, type, title, content, status, created_at',
                  )
                  .eq('id', postId)
                  .maybeSingle();

          if (post != null) {
            _post =
                Map<String, dynamic>.from(post);
          }
        } catch (error) {
          debugPrint(
            'SISONKE POST LOAD ERROR: $error',
          );
        }
      }

      // ----------------------------------------------------------
      // LOAD REQUESTER PROFILE
      // ----------------------------------------------------------

      if (_requesterId.isNotEmpty) {
        try {
          final profile =
              await _supabase
                  .from('profiles')
                  .select(
                    'id, first_name, full_name, avatar_url',
                  )
                  .eq('id', _requesterId)
                  .maybeSingle();

          if (profile != null) {
            _requester =
                Map<String, dynamic>.from(profile);
          }
        } catch (error) {
          debugPrint(
            'SISONKE REQUESTER LOAD ERROR: $error',
          );
        }
      }

      await _loadOffers();

      await _loadConnection();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (error) {
      debugPrint(
        'SISONKE HELP DETAIL ERROR: $error',
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });

        _showMessage(
          'Unable to load this help request.',
          isError: true,
        );
      }
    }
  }

  // ============================================================
  // LOAD OFFERS
  // ============================================================

  Future<void> _loadOffers() async {
    try {
      final data =
          await _supabase
              .from('help_offers')
              .select()
              .eq(
                'help_request_id',
                _requestId,
              )
              .order(
                'created_at',
                ascending: false,
              );

      final List<Map<String, dynamic>>
          offers = data
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      // ----------------------------------------------------------
      // LOAD HELPER PROFILES
      // ----------------------------------------------------------

      final helperIds = offers
          .map(
            (offer) =>
                _text(offer['helper_id']),
          )
          .where(
            (id) => id.isNotEmpty,
          )
          .toSet()
          .toList();

      if (helperIds.isNotEmpty) {
        try {
          final profiles =
              await _supabase
                  .from('profiles')
                  .select(
                    'id, first_name, full_name, avatar_url',
                  )
                  .inFilter(
                    'id',
                    helperIds,
                  );

          final Map<String,
                  Map<String, dynamic>>
              profileMap = {};

          for (final profile in profiles) {
            final map =
                Map<String, dynamic>.from(
              profile,
            );

            profileMap[
                    _text(map['id'])] =
                map;
          }

          for (final offer in offers) {
            final helperId =
                _text(offer['helper_id']);

            final profile =
                profileMap[helperId];

            if (profile != null) {
              offer['_helper'] = profile;
            }
          }
        } catch (error) {
          debugPrint(
            'SISONKE HELPER PROFILE ERROR: $error',
          );
        }
      }

      if (mounted) {
        setState(() {
          _offers = offers;
        });
      }
    } catch (error) {
      debugPrint(
        'SISONKE OFFERS LOAD ERROR: $error',
      );
    }
  }

  // ============================================================
  // LOAD CONNECTION
  // ============================================================

  Future<void> _loadConnection() async {
    try {
      final data =
          await _supabase
              .from('help_connections')
              .select()
              .eq(
                'help_request_id',
                _requestId,
              )
              .order(
                'created_at',
                ascending: false,
              )
              .limit(1);

      if (data.isEmpty) {
        if (mounted) {
          setState(() {
            _connection = null;
            _conversationId = null;
          });
        }

        return;
      }

      final connection =
          Map<String, dynamic>.from(
        data.first,
      );

      _connection = connection;

      // ----------------------------------------------------------
      // FIND CONVERSATION
      // ----------------------------------------------------------

      final connectionId =
          _text(connection['id']);

      if (connectionId.isNotEmpty) {
        final conversation =
            await _supabase
                .from('conversations')
                .select(
                  'id, connection_id, created_at',
                )
                .eq(
                  'connection_id',
                  connectionId,
                )
                .maybeSingle();

        if (conversation != null) {
          _conversationId =
              _text(conversation['id']);

          await _loadMessages();
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'SISONKE CONNECTION LOAD ERROR: $error',
      );
    }
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages() async {
    if (_conversationId == null ||
        _conversationId!.isEmpty) {
      return;
    }

    try {
      final data =
          await _supabase
              .from('messages')
              .select()
              .eq(
                'conversation_id',
                _conversationId!,
              )
              .order(
                'created_at',
                ascending: true,
              );

      if (mounted) {
        setState(() {
          _messages = data
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();
        });
      }
    } catch (error) {
      debugPrint(
        'SISONKE MESSAGES LOAD ERROR: $error',
      );
    }
  }

  // ============================================================
  // OFFER HELP
  // ============================================================

  Future<void> _offerHelp() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before offering help.',
        isError: true,
      );
      return;
    }

    if (_isRequester) {
      _showMessage(
        'You cannot offer help on your own request.',
        isError: true,
      );
      return;
    }

    final message =
        _offerController.text.trim();

    if (message.length < 3) {
      _showMessage(
        'Please tell the requester how you can help.',
        isError: true,
      );
      return;
    }

    setState(() {
      _submittingOffer = true;
    });

    try {
      // ----------------------------------------------------------
      // CHECK EXISTING OFFER
      // ----------------------------------------------------------

      final existing =
          await _supabase
              .from('help_offers')
              .select('id, status')
              .eq(
                'help_request_id',
                _requestId,
              )
              .eq(
                'helper_id',
                user.id,
              )
              .maybeSingle();

      if (existing != null) {
        if (!mounted) return;

        _showMessage(
          'You have already offered to help with this request.',
          isError: true,
        );

        return;
      }

      // ----------------------------------------------------------
      // CREATE OFFER
      // ----------------------------------------------------------

      await _supabase
          .from('help_offers')
          .insert({
        'help_request_id': _requestId,
        'helper_id': user.id,
        'message': message,
        'status': 'pending',
      });

      _offerController.clear();

      await _loadOffers();

      if (!mounted) return;

      _showMessage(
        'Your offer to help has been sent.',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE OFFER DATABASE ERROR: ${error.message}',
      );

      if (mounted) {
        _showMessage(
          'Unable to send your offer: ${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      debugPrint(
        'SISONKE OFFER ERROR: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to send your offer.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingOffer = false;
        });
      }
    }
  }

  // ============================================================
  // ACCEPT OFFER
  // ============================================================

  Future<void> _acceptOffer(
    Map<String, dynamic> offer,
  ) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    if (!_isRequester) {
      _showMessage(
        'Only the person who requested help can accept an offer.',
        isError: true,
      );
      return;
    }

    final offerId =
        _text(offer['id']);

    if (offerId.isEmpty) {
      return;
    }

    setState(() {
      _acceptingOffer = true;
    });

    try {
      // ----------------------------------------------------------
      // SECURE DATABASE WORKFLOW
      //
      // accept_help_offer:
      // - verifies requester
      // - accepts selected offer
      // - declines other offers
      // - creates connection
      // - creates conversation
      // - creates notification
      // - marks request matched
      // ----------------------------------------------------------

      await _supabase.rpc(
        'accept_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      await _loadOffers();
      await _loadConnection();

      if (!mounted) return;

      _showMessage(
        'Offer accepted. You are now connected.',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE ACCEPT OFFER DATABASE ERROR: '
        '${error.message}',
      );

      if (mounted) {
        _showMessage(
          'Unable to accept this offer: ${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      debugPrint(
        'SISONKE ACCEPT OFFER ERROR: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to accept this offer.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _acceptingOffer = false;
        });
      }
    }
  }

  // ============================================================
  // WITHDRAW OFFER
  // ============================================================

  Future<void> _withdrawOffer(
    Map<String, dynamic> offer,
  ) async {
    final offerId =
        _text(offer['id']);

    if (offerId.isEmpty) return;

    try {
      await _supabase.rpc(
        'withdraw_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      await _loadOffers();

      if (!mounted) return;

      _showMessage(
        'Your offer has been withdrawn.',
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to withdraw offer: ${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to withdraw your offer.',
          isError: true,
        );
      }
    }
  }

  // ============================================================
  // COMPLETE CONNECTION
  // ============================================================

  Future<void> _completeConnection() async {
    if (_connection == null) return;

    final connectionId =
        _text(_connection!['id']);

    if (connectionId.isEmpty) return;

    setState(() {
      _completingConnection = true;
    });

    try {
      await _supabase.rpc(
        'complete_help_connection',
        params: {
          'p_connection_id': connectionId,
        },
      );

      await _loadConnection();

      if (!mounted) return;

      _showMessage(
        'Help connection marked as completed.',
      );
    } on PostgrestException catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to complete connection: ${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to complete the connection.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingConnection = false;
        });
      }
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final conversationId =
        _conversationId;

    final user =
        _supabase.auth.currentUser;

    if (conversationId == null ||
        conversationId.isEmpty ||
        user == null) {
      return;
    }

    final content =
        _messageController.text.trim();

    if (content.isEmpty) return;

    setState(() {
      _sendingMessage = true;
    });

    try {
      await _supabase
          .from('messages')
          .insert({
        'conversation_id': conversationId,
        'sender_id': user.id,
        'content': content,
      });

      _messageController.clear();

      await _loadMessages();
    } on PostgrestException catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to send message: ${error.message}',
          isError: true,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to send message.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingMessage = false;
        });
      }
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  String _requesterName() {
    return _text(
      _requester['full_name'] ??
          _requester['first_name'],
      'Community Member',
    );
  }

  String _helperName(
    Map<String, dynamic> offer,
  ) {
    final helper =
        offer['_helper'];

    if (helper is Map<String, dynamic>) {
      return _text(
        helper['full_name'] ??
            helper['first_name'],
        'Community Member',
      );
    }

    return 'Community Member';
  }

  Color _statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF007749);

      case 'pending':
        return const Color(0xFFFFB81C);

      case 'declined':
        return const Color(0xFFDE3831);

      case 'withdrawn':
        return Colors.grey;

      case 'completed':
        return const Color(0xFF007749);

      default:
        return const Color(0xFF004B87);
    }
  }

  IconData _categoryIcon(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('food')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('employment') ||
        value.contains('job')) {
      return Icons.work_outline;
    }

    if (value.contains('education')) {
      return Icons.school_outlined;
    }

    if (value.contains('health')) {
      return Icons.health_and_safety_outlined;
    }

    if (value.contains('housing')) {
      return Icons.home_outlined;
    }

    if (value.contains('transport')) {
      return Icons.directions_car_outlined;
    }

    if (value.contains('business')) {
      return Icons.business_outlined;
    }

    return Icons.volunteer_activism_outlined;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF007749),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildRequestHeader() {
    final requesterName =
        _requesterName();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE5E7E5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE7F2EC),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  _categoryIcon(_category),
                  color:
                      const Color(0xFF007749),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _category,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF007749),
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _location,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF69707A),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_urgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFDE9E7),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color:
                          Color(0xFFDE3831),
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            _title,
            style: const TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF15191C),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _description,
            style: const TextStyle(
              fontSize: 17,
              height: 1.55,
              color: Color(0xFF4F5753),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    const Color(0xFFE8ECEA),
                backgroundImage:
                    _text(
                              _requester[
                                  'avatar_url'],
                            )
                            .isNotEmpty
                        ? NetworkImage(
                            _text(
                              _requester[
                                  'avatar_url'],
                            ),
                          )
                        : null,
                child: _text(
                          _requester[
                              'avatar_url'],
                        )
                        .isEmpty
                    ? Text(
                        requesterName
                            .substring(
                              0,
                              1,
                            )
                            .toUpperCase(),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF007749),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requested by',
                      style: TextStyle(
                        color:
                            Color(0xFF69707A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      requesterName,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFER FORM
  // ============================================================

  Widget _buildOfferForm() {
    if (!_isOpen || _isRequester) {
      return const SizedBox.shrink();
    }

    final alreadyOffered =
        _offers.any(
      (offer) =>
          _text(
            offer['helper_id'],
          ) ==
          _currentUserId,
    );

    if (alreadyOffered) {
      return _buildInfoCard(
        icon: Icons.check_circle_outline,
        title: 'You offered to help',
        message:
            'Your offer has been sent to the person who requested help.',
        color: const Color(0xFF007749),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC7E4D3),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: Color(0xFF007749),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'I Can Help',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF005A38),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Tell the requester how you can help.',
            style: TextStyle(
              color: Color(0xFF53605A),
              fontSize: 15,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller:
                _offerController,
            maxLines: 4,
            maxLength: 500,
            textCapitalization:
                TextCapitalization.sentences,
            decoration:
                InputDecoration(
              hintText:
                  'Example: I live nearby and can help with transport...',
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  _submittingOffer
                      ? null
                      : _offerHelp,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF007749),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),
              icon: _submittingOffer
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.handshake_outlined,
                    ),
              label: Text(
                _submittingOffer
                    ? 'Sending...'
                    : 'Offer Help',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color:
                        Color(0xFF5B625E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OFFERS
  // ============================================================

  Widget _buildOffers() {
    if (_offers.isEmpty) {
      if (!_isRequester) {
        return const SizedBox.shrink();
      }

      return _buildInfoCard(
        icon: Icons.people_outline,
        title: 'People Who Can Help',
        message:
            'No one has offered to help yet. Your request is now visible to the Sisonke community.',
        color: const Color(0xFF004B87),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'People Who Can Help',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF15191C),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEAF5EF),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '${_offers.length}',
                style: const TextStyle(
                  color:
                      Color(0xFF007749),
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._offers.map(
          _buildOfferCard,
        ),
      ],
    );
  }

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
  ) {
    final status =
        _text(
      offer['status'],
      'pending',
    ).toLowerCase();

    final helperName =
        _helperName(offer);

    final message =
        _text(
      offer['message'],
      'No message provided.',
    );

    final isMyOffer =
        _text(
          offer['helper_id'],
        ) ==
        _currentUserId;

    final canAccept =
        _isRequester &&
        status == 'pending' &&
        _connection == null;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE3E6E4),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    const Color(0xFFEAF1ED),
                backgroundImage:
                    (() {
                  final helper =
                      offer['_helper'];

                  if (helper
                      is Map<String, dynamic>) {
                    final avatar =
                        _text(
                      helper[
                          'avatar_url'],
                    );

                    if (avatar
                        .isNotEmpty) {
                      return NetworkImage(
                        avatar,
                      );
                    }
                  }

                  return null;
                })(),
                child:
                    (() {
                  final helper =
                      offer['_helper'];

                  String name =
                      'Community Member';

                  if (helper
                      is Map<String, dynamic>) {
                    name = _text(
                      helper['full_name'] ??
                          helper[
                              'first_name'],
                      'Community Member',
                    );
                  }

                  final avatar =
                      helper
                          is Map<String, dynamic>
                      ? _text(
                          helper[
                              'avatar_url'],
                        )
                      : '';

                  if (avatar.isNotEmpty) {
                    return null;
                  }

                  return Text(
                    name
                        .substring(0, 1)
                        .toUpperCase(),
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF007749),
                      fontWeight:
                          FontWeight.w800,
                    ),
                  );
                })(),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      helperName,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isMyOffer
                          ? 'Your offer'
                          : 'Community helper',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF69707A),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color: _statusColor(
                    status,
                  ).withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        _statusColor(
                      status,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF4F5753),
            ),
          ),

          if (canAccept) ...[
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    _acceptingOffer
                        ? null
                        : () =>
                            _acceptOffer(
                              offer,
                            ),
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF007749),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                icon: _acceptingOffer
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline,
                      ),
                label: Text(
                  _acceptingOffer
                      ? 'Accepting...'
                      : 'Accept This Offer',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],

          if (isMyOffer &&
              status == 'pending') ...[
            const SizedBox(height: 10),

            TextButton.icon(
              onPressed:
                  _withdrawOffer,
              icon: const Icon(
                Icons.undo_outlined,
                size: 18,
              ),
              label:
                  const Text(
                'Withdraw Offer',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTION
  // ============================================================

  Widget _buildConnection() {
    if (_connection == null) {
      return const SizedBox.shrink();
    }

    final status =
        _text(
      _connection!['status'],
      'active',
    ).toLowerCase();

    final helperId =
        _text(
      _connection!['helper_id'],
    );

    final otherPersonId =
        _isRequester
            ? helperId
            : _requesterId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFC7E4D3),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: Color(0xFF007749),
                size: 29,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Help Connection Active',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF005A38),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF007749),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Text(
            _isRequester
                ? 'You have accepted a community member who can help you.'
                : 'Your offer has been accepted. You are now connected with the requester.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF53605A),
            ),
          ),

          const SizedBox(height: 16),

          if (_conversationId != null &&
              _conversationId!.isNotEmpty)
            _buildMessages(),

          if (status != 'completed') ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed:
                    _completingConnection
                        ? null
                        : _completeConnection,
                icon:
                    _completingConnection
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                          ),
                label: Text(
                  _completingConnection
                      ? 'Completing...'
                      : 'Mark Help Completed',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF007749),
                  side:
                      const BorderSide(
                    color:
                        Color(0xFF007749),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E5E2),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color:
                      Color(0xFF007749),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          if (_messages.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.all(16),
              child: Text(
                'Start the conversation and coordinate the help.',
                style: TextStyle(
                  color:
                      Color(0xFF69707A),
                ),
              ),
            )
          else
            ..._messages.map(
              _buildMessageBubble,
            ),

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _messageController,
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization:
                        TextCapitalization.sentences,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Write a message...',
                      filled: true,
                      fillColor:
                          const Color(
                        0xFFF5F7F5,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 15,
                        vertical: 12,
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
                    16,
                  ),
                  child: InkWell(
                    onTap:
                        _sendingMessage
                            ? null
                            : _sendMessage,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: _sendingMessage
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(
                                15,
                              ),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color:
                                  Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
  ) {
    final isMine =
        _text(
              message['sender_id'],
            ) ==
            _currentUserId;

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 290,
        ),
        margin:
            const EdgeInsets.fromLTRB(
          12,
          4,
          12,
          4,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? const Color(0xFF007749)
              : const Color(0xFFF0F3F1),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Text(
          _text(
            message['content'],
            '',
          ),
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: isMine
                ? Colors.white
                : const Color(0xFF303633),
          ),
        ),
      ),
    );
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
          const Color(0xFFF7F7F4),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFE9EEE9),
        foregroundColor:
            const Color(0xFF15191C),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Help Request',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loadDetails,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF007749),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetails,
              color:
                  const Color(0xFF007749),
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  35,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildRequestHeader(),

                    const SizedBox(
                      height: 18,
                    ),

                    if (_connection !=
                        null)
                      _buildConnection(),

                    if (_connection ==
                        null)
                      _buildOfferForm(),

                    if (_connection ==
                        null &&
                        _isRequester) ...[
                      const SizedBox(
                        height: 24,
                      ),
                      _buildOffers(),
                    ],

                    if (_connection ==
                            null &&
                        !_isRequester &&
                        _offers.isNotEmpty) ...[
                      const SizedBox(
                        height: 20,
                      ),
                      _buildOffers(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
