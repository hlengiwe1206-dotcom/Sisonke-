import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final dynamic request;

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

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _messageController =
      TextEditingController();

  String _selectedAvailability =
      'Available immediately';

  String _selectedContactMethod = 'Phone';

  bool _isSubmitting = false;
  bool _hasAlreadyResponded = false;
  bool _checkingResponse = true;

  @override
  void initState() {
    super.initState();
    _checkExistingResponse();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAFE REQUEST VALUE READER
  // ============================================================

  dynamic _getValue(String fieldName) {
    final request = widget.request;

    if (request is Map<String, dynamic>) {
      return request[fieldName];
    }

    try {
      switch (fieldName) {
        case 'id':
          return request.id;

        case 'user_id':
          return request.userId;

        case 'title':
          return request.title;

        case 'description':
          return request.description;

        case 'category':
          return request.category;

        case 'status':
          return request.status;

        case 'location':
          return request.location;

        case 'urgent':
          return request.urgent;

        case 'created_at':
        case 'createdAt':
          return request.createdAt;

        case 'poster_name':
          return request.posterName;

        case 'poster_avatar_url':
          return request.posterAvatarUrl;

        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String _safeText(
    String fieldName, [
    String fallback = 'Not provided',
  ]) {
    final value = _getValue(fieldName);

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  bool _safeBool(String fieldName) {
    final value = _getValue(fieldName);

    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    final text =
        value.toString().trim().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  // ============================================================
  // REQUEST DATA
  // ============================================================

  String get _requestId =>
      _safeText('id', '');

  String get _requestOwnerId =>
      _safeText('user_id', '');

  String get _posterName =>
      _safeText(
        'poster_name',
        'Sisonke Member',
      );

  String get _posterAvatarUrl =>
      _safeText(
        'poster_avatar_url',
        '',
      );

  // ============================================================
  // CHECK IF USER ALREADY RESPONDED
  // ============================================================

  Future<void> _checkExistingResponse() async {
    try {
      final user =
          _supabase.auth.currentUser;

      if (user == null || _requestId.isEmpty) {
        if (mounted) {
          setState(() {
            _checkingResponse = false;
          });
        }
        return;
      }

      final existingResponse =
          await _supabase
              .from('help_responses')
              .select('id')
              .eq(
                'request_id',
                _requestId,
              )
              .eq(
                'responder_id',
                user.id,
              )
              .maybeSingle();

      if (!mounted) return;

      setState(() {
        _hasAlreadyResponded =
            existingResponse != null;

        _checkingResponse = false;
      });
    } catch (error) {
      debugPrint(
        'Error checking existing response: $error',
      );

      if (mounted) {
        setState(() {
          _checkingResponse = false;
        });
      }
    }
  }

  // ============================================================
  // SUBMIT RESPONSE
  // ============================================================

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      _showError(
        'You must be logged in to respond to a request.',
      );
      return;
    }

    if (_requestId.isEmpty) {
      _showError(
        'This request is missing its ID.',
      );
      return;
    }

    // Prevent responding to your own request.
    if (_requestOwnerId == user.id) {
      _showError(
        'You cannot respond to your own help request.',
      );
      return;
    }

    if (_hasAlreadyResponded) {
      _showError(
        'You have already responded to this request.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ========================================================
      // SAVE RESPONSE
      // ========================================================

      await _supabase
          .from('help_responses')
          .insert({
        'request_id': _requestId,
        'responder_id': user.id,
        'message':
            _messageController.text.trim(),
        'availability':
            _selectedAvailability,
        'contact_method':
            _selectedContactMethod,
        'status': 'pending',
      });

      // ========================================================
      // CREATE NOTIFICATION FOR REQUEST OWNER
      //
      // If notification creation fails, the response is still
      // successful.
      // ========================================================

      try {
        await _supabase
            .from('notifications')
            .insert({
          'user_id': _requestOwnerId,
          'title': 'New response to your help request',
          'body':
              '$_posterName has received a response to the request.',
          'is_read': false,
        });
      } catch (notificationError) {
        debugPrint(
          'Notification error: $notificationError',
        );
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _hasAlreadyResponded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your response has been sent successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      debugPrint(
        'Error submitting response: $error',
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Unable to send response:\n$error',
      );
    }
  }

  // ============================================================
  // ERROR MESSAGE
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
  // FORMAT DATE
  // ============================================================

  String _formatDate() {
    final value =
        _getValue('created_at') ??
            _getValue('createdAt');

    if (value == null) {
      return 'Recently posted';
    }

    try {
      final DateTime date =
          value is DateTime
              ? value
              : DateTime.parse(
                  value.toString(),
                );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return 'Recently posted';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String title =
        _safeText(
      'title',
      'Help Request',
    );

    final String description =
        _safeText(
      'description',
      'No description provided.',
    );

    final String category =
        _safeText(
      'category',
      'General',
    );

    final String status =
        _safeText(
      'status',
      'Open',
    );

    final String location =
        _safeText(
      'location',
      'Location not specified',
    );

    final bool urgent =
        _safeBool('urgent');

    final currentUser =
        _supabase.auth.currentUser;

    final bool isOwnRequest =
        currentUser != null &&
            currentUser.id ==
                _requestOwnerId;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF1F2937),
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // REQUEST CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildPosterProfile(
                      posterName:
                          _posterName,
                      avatarUrl:
                          _posterAvatarUrl,
                      location: location,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style:
                                const TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(
                                0xFF1F2937,
                              ),
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
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.red
                                      .withAlpha(
                                25,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color:
                                    Colors.red,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          Icons.category_outlined,
                          category,
                        ),
                        _buildInfoChip(
                          Icons.info_outline,
                          status,
                        ),
                        _buildInfoChip(
                          Icons
                              .calendar_today_outlined,
                          _formatDate(),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // OWN REQUEST MESSAGE
              // ==================================================

              if (isOwnRequest)
                _buildOwnRequestMessage(),

              // ==================================================
              // CHECKING RESPONSE
              // ==================================================

              if (!isOwnRequest &&
                  _checkingResponse)
                const Center(
                  child:
                      CircularProgressIndicator(),
                ),

              // ==================================================
              // ALREADY RESPONDED
              // ==================================================

              if (!isOwnRequest &&
                  !_checkingResponse &&
                  _hasAlreadyResponded)
                _buildAlreadyRespondedMessage(),

              // ==================================================
              // RESPONSE FORM
              // ==================================================

              if (!isOwnRequest &&
                  !_checkingResponse &&
                  !_hasAlreadyResponded)
                _buildResponseForm(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSE FORM
  // ============================================================

  Widget _buildResponseForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Respond to this request',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tell $_posterName how you can assist.',
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 18),

          TextFormField(
            controller:
                _messageController,
            maxLines: 6,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter a message.';
              }

              if (value.trim().length < 10) {
                return 'Please provide more information.';
              }

              return null;
            },
            decoration:
                _inputDecoration(
              'How can you help?',
              'Explain how you can assist...',
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value:
                _selectedAvailability,
            decoration:
                _inputDecoration(
              'Availability',
              null,
            ),
            items: const [
              DropdownMenuItem(
                value:
                    'Available immediately',
                child: Text(
                  'Available immediately',
                ),
              ),
              DropdownMenuItem(
                value:
                    'Available today',
                child: Text(
                  'Available today',
                ),
              ),
              DropdownMenuItem(
                value:
                    'Available this week',
                child: Text(
                  'Available this week',
                ),
              ),
              DropdownMenuItem(
                value:
                    'Available by arrangement',
                child: Text(
                  'Available by arrangement',
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedAvailability =
                    value;
              });
            },
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value:
                _selectedContactMethod,
            decoration:
                _inputDecoration(
              'Preferred contact method',
              null,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Phone',
                child: Text('Phone'),
              ),
              DropdownMenuItem(
                value: 'WhatsApp',
                child: Text('WhatsApp'),
              ),
              DropdownMenuItem(
                value: 'Email',
                child: Text('Email'),
              ),
              DropdownMenuItem(
                value: 'In-app message',
                child:
                    Text('In-app message'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedContactMethod =
                    value;
              });
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed:
                  _isSubmitting
                      ? null
                      : _submitResponse,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFFFB300,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Response',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // OWN REQUEST MESSAGE
  // ============================================================

  Widget _buildOwnRequestMessage() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.blue.withAlpha(20),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is your help request. Other Sisonke members can respond to it.',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALREADY RESPONDED MESSAGE
  // ============================================================

  Widget _buildAlreadyRespondedMessage() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.green.withAlpha(20),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have already responded to this request.',
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

  // ============================================================
  // POSTER PROFILE
  // ============================================================

  Widget _buildPosterProfile({
    required String posterName,
    required String avatarUrl,
    required String location,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor:
              const Color(0xFFE5E7EB),
          backgroundImage:
              avatarUrl.isNotEmpty
                  ? NetworkImage(
                      avatarUrl,
                    )
                  : null,
          child: avatarUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 30,
                  color:
                      Color(0xFF6B7280),
                )
              : null,
        ),

        const SizedBox(width: 14),

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
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              if (location.isNotEmpty &&
                  location !=
                      'Location not specified')
                Row(
                  children: [
                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 15,
                      color:
                          Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Sisonke Community Member',
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
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _buildInfoChip(
    IconData icon,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF3F4F6),
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
                const Color(
              0xFF4B5563,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
    String? hint,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          const OutlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFFFFB300),
          width: 2,
        ),
      ),
    );
  }
}
