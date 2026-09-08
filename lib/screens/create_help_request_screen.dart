import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({super.key});

  @override
  State<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState
    extends State<CreateHelpRequestScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  bool _isSubmitting = false;
  bool _urgent = false;

  String _selectedCategory =
      'General Assistance';

  final List<String> _categories = [
    'General Assistance',
    'Food',
    'Employment',
    'Education',
    'Healthcare',
    'Housing',
    'Transport',
    'Business',
    'Emergency',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitHelpRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'You must be signed in to create a help request.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? createdPostId;

    try {
      final title =
          _titleController.text.trim();

      final description =
          _descriptionController.text.trim();

      final location =
          _locationController.text.trim();

      // ========================================================
      // STEP 1 — CREATE THE PARENT POST
      //
      // IMPORTANT:
      // posts.type MUST be exactly "help_request".
      // ========================================================

      final postResponse = await _supabase
          .from('posts')
          .insert({
        'user_id': user.id,

        // REQUIRED BY THE DATABASE
        'type': 'help_request',

        'title': title,

        'content': description,

        // posts.status is required.
        // "active" is the content_status enum value.
        'status': 'active',
      })
          .select('id')
          .single();

      createdPostId =
          postResponse['id']?.toString();

      if (createdPostId == null ||
          createdPostId!.isEmpty) {
        throw Exception(
          'The help request post was created but no post ID was returned.',
        );
      }

      // ========================================================
      // STEP 2 — CREATE THE HELP REQUEST
      // ========================================================

      await _supabase
          .from('help_requests')
          .insert({
        'post_id': createdPostId,
        'requester_id': user.id,

        // help_status enum
        'status': 'open',

        'category': _selectedCategory,

        'location': location,

        'urgent': _urgent,
      });

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) return;

      _showMessage(
        'Your help request has been posted successfully.',
      );

      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      debugPrint(
        'SISONKE CREATE HELP REQUEST DATABASE ERROR',
      );

      debugPrint(
        'Code: ${error.code}',
      );

      debugPrint(
        'Message: ${error.message}',
      );

      debugPrint(
        'Details: ${error.details}',
      );

      // ========================================================
      // CLEAN UP ORPHAN POST
      //
      // If the posts row succeeded but help_requests failed,
      // remove the orphan post.
      // ========================================================

      if (createdPostId != null) {
        try {
          await _supabase
              .from('posts')
              .delete()
              .eq('id', createdPostId!);
        } catch (cleanupError) {
          debugPrint(
            'SISONKE ORPHAN POST CLEANUP ERROR: '
            '$cleanupError',
          );
        }
      }

      if (!mounted) return;

      _showMessage(
        _friendlyDatabaseMessage(error),
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'SISONKE CREATE HELP REQUEST ERROR: $error',
      );

      if (createdPostId != null) {
        try {
          await _supabase
              .from('posts')
              .delete()
              .eq('id', createdPostId!);
        } catch (cleanupError) {
          debugPrint(
            'SISONKE ORPHAN POST CLEANUP ERROR: '
            '$cleanupError',
          );
        }
      }

      if (!mounted) return;

      _showMessage(
        'Unable to create the help request: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // DATABASE ERROR MESSAGE
  // ============================================================

  String _friendlyDatabaseMessage(
    PostgrestException error,
  ) {
    final message =
        error.message.toLowerCase();

    if (message.contains('post type')) {
      return 'There is a problem with the help request post type. '
          'The database expects help_request.';
    }

    if (message.contains('not-null')) {
      return 'A required field is missing from the help request. '
          'Please try again.';
    }

    if (message.contains('row-level security')) {
      return 'You do not have permission to create this help request.';
    }

    return 'Database error: ${error.message}';
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF007749),
        ),
      );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF4F5753),
      ),
      filled: true,
      fillColor: Colors.white,
      floatingLabelStyle:
          const TextStyle(
        color: Color(0xFF007749),
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFFD4D7D5),
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFFD4D7D5),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFF007749),
          width: 2,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_outlined;

      case 'employment':
        return Icons.work_outline;

      case 'education':
        return Icons.school_outlined;

      case 'healthcare':
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F4),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFE9EEE9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Request Help',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF15191C),
          ),
        ),
        iconTheme:
            const IconThemeData(
          color: Color(0xFF15191C),
          size: 30,
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              22,
              24,
              35,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TITLE
                // ==================================================

                TextFormField(
                  controller:
                      _titleController,
                  maxLength: 120,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style:
                      const TextStyle(
                    fontSize: 19,
                    color:
                        Color(0xFF1D2225),
                  ),
                  decoration:
                      _inputDecoration(
                    label: 'What do you need help with?',
                    icon: Icons.title_outlined,
                    hint:
                        'e.g. I need help finding work',
                  ),
                  validator: (value) {
                    final text =
                        value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Please describe what you need help with.';
                    }

                    if (text.length < 5) {
                      return 'Please provide a little more detail.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // CATEGORY
                // ==================================================

                DropdownButtonFormField<
                    String>(
                  value:
                      _selectedCategory,
                  decoration:
                      _inputDecoration(
                    label: 'Category',
                    icon:
                        _categoryIcon(
                      _selectedCategory,
                    ),
                  ),
                  items: _categories
                      .map(
                        (category) {
                      return DropdownMenuItem<
                          String>(
                        value: category,
                        child: Text(
                          category,
                          style:
                              const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      );
                    }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            _selectedCategory =
                                value;
                          });
                        },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 7,
                  maxLength: 2000,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    color:
                        Color(0xFF1D2225),
                  ),
                  decoration:
                      _inputDecoration(
                    label:
                        'Describe your situation',
                    icon:
                        Icons.description_outlined,
                    hint:
                        'Tell the Sisonke community what you need and how someone could help.',
                  ),
                  validator: (value) {
                    final text =
                        value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Please describe your situation.';
                    }

                    if (text.length < 10) {
                      return 'Please provide more information.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // ==================================================
                // LOCATION
                // ==================================================

                TextFormField(
                  controller:
                      _locationController,
                  textCapitalization:
                      TextCapitalization.words,
                  style:
                      const TextStyle(
                    fontSize: 19,
                    color:
                        Color(0xFF1D2225),
                  ),
                  decoration:
                      _inputDecoration(
                    label: 'Location',
                    icon:
                        Icons.location_on_outlined,
                    hint:
                        'e.g. Dobsonville',
                  ),
                  validator: (value) {
                    final text =
                        value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Please provide your location.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // ==================================================
                // URGENT
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration:
                      BoxDecoration(
                    color: _urgent
                        ? const Color(
                            0xFFFCEBE8,
                          )
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    border: Border.all(
                      color: _urgent
                          ? const Color(
                              0xFFF3C8C2,
                            )
                          : const Color(
                              0xFFE1E4E2,
                            ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This request is urgent',
                              style:
                                  TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFF202428),
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              'Use this for requests that need quicker attention.',
                              style:
                                  TextStyle(
                                fontSize: 16,
                                height: 1.35,
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Switch(
                        value: _urgent,
                        activeThumbColor:
                            const Color(
                          0xFFDE3831,
                        ),
                        activeTrackColor:
                            const Color(
                          0xFFF4AAA4,
                        ),
                        onChanged:
                            _isSubmitting
                                ? null
                                : (value) {
                                    setState(
                                      () {
                                        _urgent =
                                            value;
                                      },
                                    );
                                  },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // SAFETY MESSAGE
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFE1E4E2,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color:
                            Color(0xFF007749),
                        size: 30,
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      const Expanded(
                        child: Text(
                          'For your safety, avoid sharing passwords, PINs, banking details or other sensitive personal information.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color:
                                Color(0xFF69707A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // POST BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF007749,
                      ),
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          const Color(
                        0xFF78A992,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                      elevation: 2,
                    ),
                    onPressed:
                        _isSubmitting
                            ? null
                            : _submitHelpRequest,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.volunteer_activism,
                            size: 28,
                          ),
                    label: Text(
                      _isSubmitting
                          ? 'POSTING...'
                          : 'Post Help Request',
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Your request will be visible to Sisonke community members who may be able to help.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color:
                          Color(0xFF69707A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
