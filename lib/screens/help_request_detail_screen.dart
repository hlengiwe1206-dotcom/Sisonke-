import 'package:flutter/material.dart';

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({super.key});

  @override
  State<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends State<CreateHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Community Support';
  String _selectedUrgency = 'Normal';

  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'Community Support',
    'Food & Essentials',
    'Transport',
    'Education',
    'Employment',
    'Business Support',
    'Health & Wellness',
    'Other',
  ];

  final List<String> _urgencyLevels = [
    'Low',
    'Normal',
    'Urgent',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitted = false;
    });

    // Temporary delay so you can test the submission experience.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your help request has been captured successfully.',
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();

    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();

      _selectedCategory = 'Community Support';
      _selectedUrgency = 'Normal';
      _submitted = false;
    });
  }

  Color _urgencyColor() {
    switch (_selectedUrgency) {
      case 'Urgent':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Request Help'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you need help with?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Tell the Sisonke community what support you need.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Help Category',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Urgency',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _urgencyLevels.map((urgency) {
                    final isSelected = _selectedUrgency == urgency;

                    return ChoiceChip(
                      label: Text(urgency),
                      selected: isSelected,
                      selectedColor: _urgencyColor().withOpacity(0.20),
                      onSelected: (_) {
                        setState(() {
                          _selectedUrgency = urgency;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Request Title',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Example: I need transport assistance',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title for your request.';
                    }

                    if (value.trim().length < 5) {
                      return 'Please provide a little more detail.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Describe Your Situation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        'Explain what assistance you need and how the community may be able to help.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe your request.';
                    }

                    if (value.trim().length < 15) {
                      return 'Please provide more information.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Example: Johannesburg, Gauteng',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your location.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Submit Help Request',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                if (_submitted) ...[
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Information Captured!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Category: $_selectedCategory\n'
                          'Urgency: $_selectedUrgency\n'
                          'Location: ${_locationController.text}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 18),

                        OutlinedButton(
                          onPressed: _resetForm,
                          child: const Text(
                            'Create Another Request',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
