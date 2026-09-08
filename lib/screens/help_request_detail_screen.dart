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

  final TextEditingController _messageController =
      TextEditingController();

  bool _isLoadingOffers = true;
  bool _isSubmittingOffer = false;
  bool _hasOfferedHelp = false;

  List<Map<String, dynamic>> _offers = [];

  // ============================================================
  // SAFE VALUE HELPERS
  // ============================================================

  String _text(
    dynamic value, [
    String fallback = '',
  ]) {
    if (value == null) return fallback;

    final valueText = value.toString().trim();

    if (valueText.isEmpty || valueText == 'null') {
      return fallback;
    }

    return valueText;
  }

  bool _bool(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;

    final text = value.toString().trim().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  String get _requestId =>
      _text(widget.request['id']);

  String get _requesterId =>
      _text(widget.request['requester_id']);

  String get _title =>
      _text(
        widget.request['title'],
        'Community Help Request',
      );

  String get _description =>
      _text(
        widget.request['description'],
        'No description provided.',
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
      );

  bool get _urgent =>
      _bool(widget.request['urgent']);

  String get _posterName =>
      _text(
        widget.request['poster_name'],
        'Sisonke Member',
      );

  String get _posterAvatarUrl =>
      _text(
        widget.request['poster_avatar_url'],
      );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadOffers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD OFFERS
  // ============================================================

  Future<void> _loadOffers() async {
    if (_requestId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingOffers = false;
        });
      }

      return;
    }

    try {
      final response = await _supabase
          .from('help_offers')
          .select()
          .eq('help_request_id', _requestId)
          .order(
            'created_at',
            ascending: false,
          );

      final offers = List<Map<String, dynamic>>.from(
        response,
      );

      final currentUser =
          _supabase.auth.currentUser;

      if (currentUser != null) {
        _hasOfferedHelp = offers.any(
          (offer) =>
              _text(offer['helper_id']) ==
              currentUser.id &&
              _text(offer['status']).toLowerCase() !=
                  'declined',
        );
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _isLoadingOffers = false;
      });
    } catch (error) {
      debugPrint(
        'SISONKE LOAD HELP OFFERS ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  // ============================================================
  // OFFER HELP
  // ============================================================

  Future<void> _offerHelp() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before offering help.',
        isError: true,
      );

      return;
    }

    if (_requestId.isEmpty) {
      _showMessage(
        'This help request could not be identified.',
        isError: true,
      );

      return;
    }

    if (_requesterId == user.id) {
      _showMessage(
        'You cannot offer help to your own request.',
        isError: true,
      );

      return;
    }

    if (_hasOfferedHelp) {
      _showMessage(
        'You have already offered to help with this request.',
      );

      return;
    }

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      await _supabase
          .from('help_offers')
          .insert({
        'help_request_id': _requestId,
        'helper_id': user.id,
        'message':
            _messageController.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _hasOfferedHelp = true;
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Your offer to help has been sent.',
      );

      await _loadOffers();
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE OFFER HELP DATABASE ERROR: '
        '${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Unable to send your offer:\n${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'SISONKE OFFER HELP ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Unable to send your offer.',
        isError: true,
      );
    }
  }

  // ============================================================
  // ACCEPT OFFER
  // ============================================================

  Future<void> _acceptOffer(
    Map<String, dynamic> offer,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in again.',
        isError: true,
      );

      return;
    }

    if (_requesterId != user.id) {
      _showMessage(
        'Only the person who requested help can accept an offer.',
        isError: true,
      );

      return;
    }

    final offerId = _text(offer['id']);

    if (offerId.isEmpty) {
      _showMessage(
        'This offer could not be identified.',
        isError: true,
      );

      return;
    }

    final confirmed = await _confirmAcceptOffer();

    if (!confirmed) return;

    if (!mounted) return;

    setState(() {
      _isSubmittingOffer = true;
    });

    try {
      final result = await _supabase.rpc(
        'accept_help_offer',
        params: {
          'p_offer_id': offerId,
        },
      );

      debugPrint(
        'SISONKE ACCEPT OFFER RESULT: $result',
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Offer accepted. Your help connection has been created.',
      );

      await _loadOffers();
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE ACCEPT OFFER DATABASE ERROR: '
        '${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Unable to accept this offer:\n${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'SISONKE ACCEPT OFFER ERROR: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingOffer = false;
      });

      _showMessage(
        'Unable to accept this offer.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONFIRM ACCEPTANCE
  // ============================================================

  Future<bool> _confirmAcceptOffer() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Accept this offer?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Accepting this offer will connect you with this community member so you can work together to resolve the request.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF007749),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Accept Offer'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  // ============================================================
  // ERROR / SUCCESS MESSAGE
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF007749),
        ),
      );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Recently posted';
    }

    final date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return 'Recently posted';
    }

    final local = date.toLocal();

    final difference =
        DateTime.now().difference(local);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon() {
    switch (_category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;

      case 'employment':
      case 'jobs':
        return Icons.work_outline;

      case 'education':
        return Icons.school_outlined;

      case 'healthcare':
      case 'health':
        return Icons.health_and_safety_outlined;

      case 'housing':
        return Icons.home_work_outlined;

      case 'transport':
        return Icons.directions_car_outlined;

      case 'business':
        return Icons.business_outlined;

      case 'emergency':
        return Icons.warning_amber_rounded;

      default:
        return Icons.volunteer_activism_outlined;
    }
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(
    String url,
    String name,
  ) {
    if (url.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError:
            (_, __) {},
      );
    }

    final firstLetter = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'S';

    return CircleAvatar(
      radius: 25,
      backgroundColor:
          const Color(0xFF007749),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // OFFER CARD
  // ============================================================

  Widget _buildOfferCard(
    Map<String, dynamic> offer,
  ) {
    final currentUser =
        _supabase.auth.currentUser;

    final helperId =
        _text(offer['helper_id']);

    final isOwnOffer =
        currentUser != null &&
        helperId == currentUser.id;

    final status =
        _text(
          offer['status'],
          'pending',
        ).toLowerCase();

    final message =
        _text(
          offer['message'],
          'This community member has offered to help.',
        );

    String statusLabel;

    switch (status) {
      case 'accepted':
        statusLabel = 'ACCEPTED';

        break;

      case 'declined':
        statusLabel = 'DECLINED';

        break;

      default:
        statusLabel = 'OFFER TO HELP';
    }

    Color statusColor;

    switch (status) {
      case 'accepted':
        statusColor =
            const Color(0xFF007749);

        break;

      case 'declined':
        statusColor =
            Colors.grey.shade600;

        break;

      default:
        statusColor =
            const Color(0xFF004B87);
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE6E7E8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(
                '',
                isOwnOffer
                    ? 'You'
                    : 'S',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwnOffer
                          ? 'You offered to help'
                          : 'Sisonke Community Member',
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(
                        offer['created_at'],
                      ),
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
                  color: statusColor
                      .withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF374151),
            ),
          ),

          if (_requesterId ==
                  currentUser?.id &&
              status == 'pending') ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF007749),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
                onPressed:
                    _isSubmittingOffer
                        ? null
                        : () =>
                            _acceptOffer(
                              offer,
                            ),
                icon: const Icon(
                  Icons.handshake_outlined,
                ),
                label: const Text(
                  'ACCEPT OFFER',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],

          if (status == 'accepted') ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF007749)
                        .withAlpha(14),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color:
                        Color(0xFF007749),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Help connection created. You can now work together on this request.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF005A38),
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST HEADER
  // ============================================================

  Widget _buildRequestHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE6E7E8),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(
                _posterAvatarUrl,
                _posterName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _posterName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(
                        widget.request[
                            'created_at'],
                      ),
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
              if (_urgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color:
                          Colors.red.shade700,
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF007749)
                          .withAlpha(18),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _categoryIcon(),
                  color:
                      const Color(0xFF007749),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _category,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF007749),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF3F4F6,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _title,
            style: const TextStyle(
              fontSize: 25,
              height: 1.18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4B5563),
            ),
          ),

          if (_location.isNotEmpty) ...[
            const SizedBox(height: 18),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color:
                      Color(0xFF69707A),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _location,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Color(0xFF69707A),
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OFFER FORM
  // ============================================================

  Widget _buildOfferSection() {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    if (_requesterId == user.id) {
      return const SizedBox.shrink();
    }

    if (_status.toLowerCase() != 'open' &&
        _status.toLowerCase() != 'pending' &&
        _status.toLowerCase() != 'active') {
      return const SizedBox.shrink();
    }

    if (_hasOfferedHelp) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF007749)
              .withAlpha(12),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF007749)
                .withAlpha(45),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF007749),
              size: 26,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your offer to help has been sent. The requester can now review your offer.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF005A38),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE6E7E8),
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
                size: 25,
              ),
              SizedBox(width: 10),
              Text(
                'Can you help?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Let the requester know how you can assist.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF69707A),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 500,
            decoration:
                InputDecoration(
              hintText:
                  'Describe how you can help...',
              filled: true,
              fillColor:
                  const Color(0xFFF8F9FA),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide.none,
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
                      Color(0xFF007749),
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF007749),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              onPressed:
                  _isSubmittingOffer
                      ? null
                      : _offerHelp,
              icon:
                  _isSubmittingOffer
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
                          Icons.handshake,
                        ),
              label: Text(
                _isSubmittingOffer
                    ? 'SENDING...'
                    : 'OFFER TO HELP',
                style: const TextStyle(
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F4),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F7F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Help Request',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF111827),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF007749),
          onRefresh: _loadOffers,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              32,
            ),
            children: [
              _buildRequestHeader(),

              const SizedBox(height: 18),

              _buildOfferSection(),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'People Who Can Help',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (_offers.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFF007749,
                        ).withAlpha(18),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
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

              const SizedBox(height: 12),

              if (_isLoadingOffers)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 30,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          Color(0xFF007749),
                    ),
                  ),
                )
              else if (_offers.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(24),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color:
                          Color(0xFFE6E7E8),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 44,
                        color:
                            Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No offers yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Be the first person to offer help.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Color(0xFF69707A),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._offers.map(
                  _buildOfferCard,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility class for older navigation
/// references that may still use the plural name.
class HelpRequestDetailsScreen
    extends HelpRequestDetailScreen {
  const HelpRequestDetailsScreen({
    super.key,
    required super.request,
  });
}
