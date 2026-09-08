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
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _locationController =
      TextEditingController();

  final FocusNode _locationFocusNode = FocusNode();

  bool _urgent = false;
  bool _isPosting = false;

  String _selectedCategory = 'General Assistance';

  final List<String> _categories = const [
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
    _locationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _postHelpRequest() async {
    if (_isPosting) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showError('Please sign in before posting a help request.');
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      _showError('Please enter a title for your help request.');
      return;
    }

    if (description.isEmpty) {
      _showError('Please describe your situation.');
      return;
    }

    if (location.isEmpty) {
      _showError('Please enter your location.');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    String? createdPostId;

    try {
      // ------------------------------------------------------------
      // STEP 1: CREATE THE PARENT POST
      //
      // IMPORTANT:
      // posts.type is NOT NULL and is a post_type enum.
      // posts.status is also NOT NULL and is a content_status enum.
      // ------------------------------------------------------------

      final postResponse = await _supabase
          .from('posts')
          .insert({
            'user_id': user.id,
            'type': 'help_request',
            'title': title,
            'content': description,
            'status': 'active',
          })
          .select('id')
          .single();

      createdPostId = postResponse['id'] as String;

      // ------------------------------------------------------------
      // STEP 2: CREATE THE HELP REQUEST
      // ------------------------------------------------------------

      await _supabase.from('help_requests').insert({
        'post_id': createdPostId,
        'requester_id': user.id,
        'status': 'open',
        'category': _selectedCategory,
        'location': location,
        'urgent': _urgent,
      });

      if (!mounted) return;

      // Clear the form after successful submission.
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();

      setState(() {
        _urgent = false;
        _selectedCategory = 'General Assistance';
        _isPosting = false;
      });

      // Show success message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your help request has been posted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Return to the previous screen.
      Navigator.of(context).pop(true);
    } catch (error) {
      // ------------------------------------------------------------
      // CLEANUP
      //
      // If the posts row was created but help_requests failed,
      // remove the orphaned post.
      // ------------------------------------------------------------

      if (createdPostId != null) {
        try {
          await _supabase
              .from('posts')
              .delete()
              .eq('id', createdPostId);
        } catch (_) {
          // Ignore cleanup errors.
        }
      }

      if (!mounted) return;

      setState(() {
        _isPosting = false;
      });

      _showError(_friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('posts_type_check') ||
        message.contains('invalid input value for enum post_type')) {
      return 'There is a problem with the help request post type. '
          'The database expects help_request.';
    }

    if (message.contains('posts_status') ||
        message.contains('invalid input value for enum content_status')) {
      return 'There is a problem with the post status. '
          'The database expects active.';
    }

    if (message.contains('help_requests')) {
      return 'Database error while creating the help request: '
          '${_cleanDatabaseMessage(message)}';
    }

    if (message.contains('posts')) {
      return 'Database error while creating the post: '
          '${_cleanDatabaseMessage(message)}';
    }

    return 'Unable to post your help request: '
        '${_cleanDatabaseMessage(message)}';
  }

  String _cleanDatabaseMessage(String message) {
    if (message.startsWith('PostgrestException')) {
      final separator = message.indexOf(':');

      if (separator != -1 && separator + 1 < message.length) {
        return message.substring(separator + 1).trim();
      }
    }

    return message;
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDE3831),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF007749);
    const darkGreen = Color(0xFF005A38);
    const red = Color(0xFFDE3831);
    const ivory = Color(0xFFF8F7F2);
    const muted = Color(0xFF69707A);

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF1EC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Color(0xFF222222),
          ),
          onPressed: _isPosting
              ? null
              : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request Help',
          style: TextStyle(
            color: Color(0xFF17191C),
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------------
                // INTRODUCTION
                // ------------------------------------------------------

                const Text(
                  'Tell your community how they can help.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Be clear and specific so the right person can respond.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: muted,
                  ),
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------------
                // TITLE
                // ------------------------------------------------------

                _buildTextField(
                  controller: _titleController,
                  label: 'What do you need help with?',
                  hint: 'e.g. I need funding for my NGO',
                  icon: Icons.help_outline,
                  maxLines: 1,
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------------
                // CATEGORY
                // ------------------------------------------------------

                _buildCategoryField(
                  green: green,
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------------

                _buildDescriptionField(),

                const SizedBox(height: 22),

                // ------------------------------------------------------
                // LOCATION
                // ------------------------------------------------------

                _buildTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'e.g. Dobsonville',
                  icon: Icons.location_on_outlined,
                  focusNode: _locationFocusNode,
                  maxLines: 1,
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------------
                // URGENT
                // ------------------------------------------------------

                _buildUrgentCard(
                  red: red,
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------------
                // SAFETY NOTE
                // ------------------------------------------------------

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE6E7E8),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'For your safety, avoid sharing passwords, '
                          'PINs, banking details or other sensitive '
                          'personal information.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------------
                // POST BUTTON
                // ------------------------------------------------------

                SizedBox(
                  height: 66,
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _postHelpRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      disabledBackgroundColor:
                          green.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            height: 27,
                            width: 27,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Post Help Request',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    'Your request will be visible to people in the Sisonke community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: muted,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int maxLines,
    FocusNode? focusNode,
  }) {
    const green = Color(0xFF007749);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      textInputAction:
          maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
      style: const TextStyle(
        fontSize: 18,
        color: Color(0xFF202124),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF59605D),
          size: 27,
        ),
        floatingLabelStyle: const TextStyle(
          color: green,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: green,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField({
    required Color green,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        size: 30,
      ),
      style: const TextStyle(
        fontSize: 18,
        color: Color(0xFF202124),
      ),
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: Color(0xFF59605D),
          size: 27,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        floatingLabelStyle: TextStyle(
          color: green,
          fontSize: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: green,
            width: 2,
          ),
        ),
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: _isPosting
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _selectedCategory = value;
              });
            },
    );
  }

  Widget _buildDescriptionField() {
    const green = Color(0xFF007749);

    return TextField(
      controller: _descriptionController,
      maxLines: 6,
      maxLength: 2000,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        fontSize: 18,
        height: 1.45,
        color: Color(0xFF202124),
      ),
      decoration: InputDecoration(
        labelText: 'Describe your situation',
        hintText:
            'Explain what you need and how someone can help.',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 12,
            top: 18,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            widthFactor: 1,
            child: Icon(
              Icons.description_outlined,
              color: Color(0xFF59605D),
              size: 27,
            ),
          ),
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          16,
        ),
        floatingLabelStyle: const TextStyle(
          color: green,
          fontSize: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFBFC1C0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: green,
            width: 2,
          ),
        ),
        counterStyle: const TextStyle(
          color: Color(0xFF69707A),
        ),
      ),
    );
  }

  Widget _buildUrgentCard({
    required Color red,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: BoxDecoration(
        color: _urgent
            ? const Color(0xFFFFF0ED)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _urgent
              ? const Color(0xFFF3C7C2)
              : const Color(0xFFE6E7E8),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This request is urgent',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _urgent
                        ? const Color(0xFF252525)
                        : const Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Use this for requests that need quicker attention.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: Color(0xFF69707A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _urgent,
            onChanged: _isPosting
                ? null
                : (value) {
                    setState(() {
                      _urgent = value;
                    });
                  },
            activeTrackColor: const Color(0xFFF58B82),
            activeThumbColor: red,
          ),
        ],
      ),
    );
  }
}
