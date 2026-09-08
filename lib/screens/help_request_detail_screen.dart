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

  final TextEditingController _messageController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasOfferedHelp = false;

  List<Map<String, dynamic>> _offers = [];

  static const Color green = Color(0xFF007749);
  static const Color darkGreen = Color(0xFF005A38);
  static const Color red = Color(0xFFDE3831);
  static const Color gold = Color(0xFFFFB81C);
  static const Color ivory = Color(0xFFF8F7F2);

  String get _requestId =>
      (widget.request['id'] ?? '').toString();

  String get _requesterId =>
      (widget.request['requester_id'] ??
              widget.request['user_id'] ??
              '')
          .toString();

  String get _title =>
      _text(widget.request['title'], 'Help Request');

  String get _description =>
      _text(
        widget.request['description'] ??
            widget.request['content'],
        'No description provided.',
      );

  String get _category =>
      _text(widget.request['category'], 'General Assistance');

  String get _location =>
      _text(widget.request['location'], 'Location not specified');

  String get _status =>
      _text(widget.request['status'], 'open');

  bool get _urgent =>
      _bool(
        widget.request['urgent'] ??
            widget.request['is_urgent'],
      );

  String _text(dynamic value, String fallback) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  bool _bool(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  String _formatDate(dynamic value) {
    final date = _date(value);

    if (date == null) {
      return 'Recently posted';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

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

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

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
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final user = _supabase.auth.currentUser;

      final List<dynamic> data = await _supabase
          .from('help_offers')
          .select()
          .eq('help_request_id', _requestId)
          .order('created_at', ascending: false);

      final offers = data
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();

      bool alreadyOffered = false;

      if (user != null) {
        alreadyOffered = offers.any(
          (offer) =>
              offer['helper_id']?.toString() == user.id &&
              _text(
                    offer['status'],
                    '',
                  ).toLowerCase() !=
                  'withdrawn',
        );
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _hasOfferedHelp = alreadyOffered;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint(
        'Error loading help offers: $error',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load help offers.',
        isError: true,
      );
    }
  }

  // ============================================================
  // OFFER HELP
  // ============================================================

  Future<void> _offerHelp() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to offer help.',
        isError: true,
      );
      return;
    }

    if (_requesterId == user.id) {
      _showMessage(
        'You cannot offer help on your own request.',
        isError: true,
      );
      return;
    }

    if (_requestId.isEmpty) {
      _showMessage(
        'This help request is missing its ID.',
        isError: true,
      );
      return;
    }

    if (_status.toLowerCase() != 'open') {
      _showMessage(
        'This help request is no longer open.',
        isError: true,
      );
      return;
    }

    if (_hasOfferedHelp) {
      _showMessage(
        'You have already offered to help.',
      );
      return;
    }

    final message = await _showOfferDialog();

    if (message == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _supabase
          .from('help_offers')
          .insert({
        'help_request_id': _requestId,
        'helper_id': user.id,
        'message': message,
        'status': 'pending',
      });

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _hasOfferedHelp = true;
      });

      _showMessage(
        'Your offer to help has been sent.',
      );

      await _loadOffers();
    } on PostgrestException catch (error) {
      debugPrint(
        'Database error creating help offer: '
        '${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'Unable to send your offer:\n${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Error creating help offer: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'Unable to send your offer.',
        isError: true,
      );
    }
  }

  // ============================================================
  // OFFER DIALOG
  // ============================================================

  Future<String?> _showOfferDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Offer Help',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell the requester how you can assist.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                maxLength: 500,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Example: I can assist with your CV and job applications.',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: green,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final message =
                    controller.text.trim();

                if (message.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  message,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Offer Help'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
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
        'Please sign in.',
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

    final offerId =
        (offer['id'] ?? '').toString();

    if (offerId.isEmpty) {
      _showMessage(
        'This offer is missing its ID.',
        isError: true,
      );
      return;
    }

    final confirmed =
        await _showConfirmDialog(
      title: 'Accept this offer?',
      message:
          'Accept this member as the person who will help you? Other pending offers will be declined.',
    );

    if (!confirmed) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _supabase.rpc(
        'accept_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'Offer accepted. Your help connection has been created.',
      );

      await _loadOffers();
    } on PostgrestException catch (error) {
      debugPrint(
        'Error accepting help offer: ${error.message}',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'Unable to accept this offer:\n${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Error accepting help offer: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'Unable to accept this offer.',
        isError: true,
      );
    }
  }

  // ============================================================
  // WITHDRAW OFFER
  // ============================================================

  Future<void> _withdrawOffer(
    Map<String, dynamic> offer,
  ) async {
    final offerId =
        (offer['id'] ?? '').toString();

    if (offerId.isEmpty) {
      return;
    }

    final confirmed =
        await _showConfirmDialog(
      title: 'Withdraw offer?',
      message:
          'Your offer to help will be withdrawn.',
    );

    if (!confirmed) return;

    try {
      await _supabase.rpc(
        'withdraw_help_offer',
        params: {
          'p_help_offer_id': offerId,
        },
      );

      if (!mounted) return;

      _showMessage(
        'Your offer has been withdrawn.',
      );

      await _loadOffers();
    } catch (error) {
      debugPrint(
        'Error withdrawing offer: $error',
      );

      if (!mounted) return;

      _showMessage(
        'Unable to withdraw the offer.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return green;

      case 'matched':
        return Colors.blue;

      case 'completed':
        return Colors.green;

      case 'closed':
        return Colors.grey;

      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'OPEN';

      case 'matched':
        return 'MATCHED';

      case 'completed':
        return 'COMPLETED';

      case 'closed':
        return 'CLOSED';

      default:
        return status.toUpperCase();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        _supabase.auth.currentUser;

    final bool isOwner =
        user != null &&
        user.id == _requesterId;

    final bool canOffer =
        !isOwner &&
        _status.toLowerCase() == 'open';

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text(
          'Help Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: green,
              ),
            )
          : RefreshIndicator(
              color: green,
              onRefresh: _loadOffers,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _buildRequestCard(),
                  const SizedBox(height: 22),
                  _buildActionSection(
                    isOwner: isOwner,
                    canOffer: canOffer,
                  ),
                  const SizedBox(height: 22),
                  _buildOffersSection(
                    isOwner: isOwner,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard() {
    final statusColor =
        _statusColor(_status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                  _title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17202A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_urgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        red.withAlpha(20),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: red,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _buildInfoChip(
                Icons.category_outlined,
                _category,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildInfoChip(
                  Icons.location_on_outlined,
                  _location,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      statusColor.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(_status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time,
                size: 15,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(
                  widget.request['created_at'],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: green,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION SECTION
  // ============================================================

  Widget _buildActionSection({
    required bool isOwner,
    required bool canOffer,
  }) {
    if (isOwner) {
      return _buildOwnerBanner();
    }

    if (!canOffer) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This help request is no longer accepting offers.',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            green,
            darkGreen,
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Can you help?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _hasOfferedHelp
                ? 'Your offer has been sent to the requester.'
                : 'Offer your skills, time or resources to help another South African.',
            style: const TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isSubmitting ||
                          _hasOfferedHelp
                      ? null
                      : _offerHelp,
              icon: Icon(
                _hasOfferedHelp
                    ? Icons.check_circle
                    : Icons.volunteer_activism,
              ),
              label: Text(
                _hasOfferedHelp
                    ? 'Offer Sent'
                    : 'I CAN HELP',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor: green,
                disabledBackgroundColor:
                    Colors.white
                        .withAlpha(180),
                disabledForegroundColor:
                    green.withAlpha(180),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gold.withAlpha(30),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: gold.withAlpha(90),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: Color(0xFF9A7200),
            size: 27,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'This is your help request',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'People who can assist you will appear below. Review their offers and accept the person you would like to work with.',
                  style: TextStyle(
                    height: 1.4,
                    color:
                        Color(0xFF5F5500),
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

  Widget _buildOffersSection({
    required bool isOwner,
  }) {
    final visibleOffers =
        _offers.where((offer) {
      final status = _text(
        offer['status'],
        'pending',
      ).toLowerCase();

      return status != 'withdrawn' &&
          status != 'declined';
    }).toList();

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
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            if (visibleOffers.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      green.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '${visibleOffers.length}',
                  style: const TextStyle(
                    color: green,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (visibleOffers.isEmpty)
          _buildNoOffers()
        else
          ...visibleOffers.map(
            (offer) => _buildOfferCard(
              offer,
              isOwner: isOwner,
            ),
          ),
      ],
    );
  }

  Widget _buildNoOffers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 42,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            'No offers yet',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'When community members offer to help, their offers will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(
    Map<String, dynamic> offer, {
    required bool isOwner,
  }) {
    final user =
        _supabase.auth.currentUser;

    final helperId =
        (offer['helper_id'] ?? '')
            .toString();

    final bool isMyOffer =
        user != null &&
        helperId == user.id;

    final status = _text(
      offer['status'],
      'pending',
    ).toLowerCase();

    final statusColor =
        status == 'accepted'
            ? green
            : status == 'declined'
                ? red
                : Colors.orange;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isMyOffer
              ? green.withAlpha(70)
              : Colors.grey.shade200,
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
                    green.withAlpha(25),
                child: const Icon(
                  Icons.person,
                  color: green,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyOffer
                          ? 'You'
                          : 'Sisonke Member',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(
                        offer['created_at'],
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      statusColor.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            _text(
              offer['message'],
              'I can help with this request.',
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF374151),
            ),
          ),

          if (isOwner &&
              status == 'pending') ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () => _acceptOffer(
                              offer,
                            ),
                icon: const Icon(
                  Icons.check_circle_outline,
                ),
                label: const Text(
                  'ACCEPT THIS OFFER',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],

          if (isMyOffer &&
              status == 'pending') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : () => _withdrawOffer(
                              offer,
                            ),
                icon: const Icon(
                  Icons.undo,
                  size: 18,
                ),
                label: const Text(
                  'Withdraw Offer',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.grey.shade700,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
