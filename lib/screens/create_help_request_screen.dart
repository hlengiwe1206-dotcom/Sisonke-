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
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isSubmitting = false;
  bool _urgent = false;

  String _selectedCategory = 'General Assistance';

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

  Future<void> _submitHelpRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = supabase.auth.currentUser;

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

    try {
      /*
       * The Sisonke help_requests table is built around:
       * requester_id
       * post_id
       * status
       * category
       * location
       * urgent
       *
       * We therefore create the underlying post first,
       * then connect the help request to that post.
       */

      final postResponse = await supabase
          .from('posts')
          .insert({
            'user_id': user.id,
            'content': _descriptionController.text.trim(),
          })
          .select('id')
          .single();

      final String postId = postResponse['id'].toString();

      await supabase.from('help_requests').insert({
        'post_id': postId,
        'requester_id': user.id,
        'status': 'open',
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'urgent': _urgent,
      });

      if (!mounted) return;

      _showMessage(
        'Your help request has been posted successfully.',
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      debugPrint(
        'Database error creating help request: '
        '${error.message}',
      );

      if (!mounted) return;

      _showMessage(
        'Database error: ${error.message}',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Error creating help request: $error',
      );

      if (!mounted) return;

      _showMessage(
        'Unable to create help request: $error',
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

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF007749),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const southAfricaGreen = Color(0xFF007749);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Help',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.volunteer_activism,
                size: 64,
                color: southAfricaGreen,
              ),

              const SizedBox(height: 16),

              const Text(
                'How can the Sisonke community help?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tell the community what assistance you need. '
                'Your request will be linked to your Sisonke profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              TextFormField(
                controller: _titleController,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _inputDecoration(
                  label: 'What do you need help with?',
                  hint:
                      'Example: I need assistance finding work',
                  icon: Icons.title,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter a title for your request.';
                  }

                  if (value.trim().length < 5) {
                    return 'Please provide a more descriptive title.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration(
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedCategory = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 8,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: _inputDecoration(
                  label: 'Describe your situation',
                  hint:
                      'Provide enough information for people to understand how they can assist you.',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please describe the help you need.';
                  }

                  if (value.trim().length < 20) {
                    return 'Please provide a little more detail.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _locationController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Location',
                  hint: 'Example: Soweto, Johannesburg',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter your location.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.18),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'This request is urgent',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Use this for requests that need quicker attention.',
                  ),
                  value: _urgent,
                  activeColor: Colors.red,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _urgent = value;
                          });
                        },
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _submitHelpRequest,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
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
                    _isSubmitting
                        ? 'Posting Request...'
                        : 'Post Help Request',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: southAfricaGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'By posting, you allow other Sisonke community '
                'members to see your request and connect with '
                'you through the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
} 
