import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _messageController =
      TextEditingController();

  String _selectedAvailability = 'Available immediately';
  String _selectedContactMethod = 'Phone';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SAFE REQUEST VALUE READER
  // Works with both Map data and object/model data.
  // ----------------------------------------------------------

  dynamic _getValue(String fieldName) {
    final request = widget.request;

    if (request is Map<String, dynamic>) {
      return request[fieldName];
    }

    try {
      switch (fieldName) {
        case 'id':
          return request.id;

        case 'title':
          return request.title;

        case 'description':
          return request.description;

        case 'category':
          return request.category;

        case 'status':
          return request.status;

        case 'urgent':
          return request.urgent;

        case 'created_at':
          return request.createdAt;

        case 'createdAt':
          return request.createdAt;

        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  String _safeText(String fieldName, [String fallback = 'Not provided']) {
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

    return value.toString().toLowerCase() == 'true';
  }

  String _formatDate() {
    final value =
        _getValue('created_at') ?? _getValue('createdAt');

    if (value == null) {
      return 'Recently posted';
    }

    try {
      DateTime date;

      if (value is DateTime) {
        date = value;
      } else {
        date = DateTime.parse(value.toString());
      }

      return
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return 'Recently posted';
    }
  }

  // ----------------------------------------------------------
  // SUBMIT TEST RESPONSE
  // ----------------------------------------------------------

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulates processing.
    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    // For testing purposes, show captured information.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your response has been captured successfully.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final String title = _safeText('title', 'Help Request');

    final String description =
        _safeText('description', 'No description provided.');

    final String category =
        _safeText('category', 'General');

    final String status =
        _safeText('status', 'Open');

    final bool urgent = _safeBool('urgent');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // REQUEST INFORMATION
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
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
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),

                        if (urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  Colors.red.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),

                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,

                      children: [
                        _buildInfoChip(
                          icon: Icons.category_outlined,
                          label: category,
                        ),

                        _buildInfoChip(
                          icon: Icons.info_outline,
                          label: status,
                        ),

                        _buildInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // RESPONSE FORM
              // ------------------------------------------------

              const Text(
                'Respond to this request',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tell the person how you can assist.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),

              Form(
                key: _formKey,

                child: Column(
                  children: [
                    // ----------------------------------------
                    // MESSAGE
                    // ----------------------------------------

                    TextFormField(
                      controller: _messageController,

                      maxLines: 6,

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return
                              'Please enter a message.';
                        }

                        if (value.trim().length < 10) {
                          return
                              'Please provide a little more information.';
                        }

                        return null;
                      },

                      decoration: InputDecoration(
                        labelText: 'How can you help?',
                        hintText:
                            'Explain how you can assist with this request...',

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
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),

                          borderSide: const BorderSide(
                            color: Color(0xFFFFB300),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ----------------------------------------
                    // AVAILABILITY
                    // ----------------------------------------

                    DropdownButtonFormField<String>(
                      value: _selectedAvailability,

                      decoration: InputDecoration(
                        labelText: 'Availability',

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
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

                          child:
                              Text('Available today'),
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
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedAvailability =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // ----------------------------------------
                    // CONTACT METHOD
                    // ----------------------------------------

                    DropdownButtonFormField<String>(
                      value:
                          _selectedContactMethod,

                      decoration: InputDecoration(
                        labelText:
                            'Preferred contact method',

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
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
                          child: Text(
                            'In-app message',
                          ),
                        ),
                      ],

                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedContactMethod =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    // ----------------------------------------
                    // SUBMIT BUTTON
                    // ----------------------------------------

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : _submitResponse,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFFFB300),

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),

                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,

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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // INFO CHIP
  // ----------------------------------------------------------

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF4B5563),
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
