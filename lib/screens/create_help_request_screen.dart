import 'package:flutter/material.dart';

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({super.key});

  @override
  State<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends State<CreateHelpRequestScreen> {
  static const Color _primary = Color(0xFF1E4F7F);
  static const Color _accent = Color(0xFFFFB41F);
  static const Color _background = Color(0xFFF5F3EE);
  static const Color _text = Color(0xFF1F232B);
  static const Color _muted = Color(0xFF6B7280);

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  String _selectedCategory = 'General Support';
  String _selectedUrgency = 'Normal';
  String _selectedContactMethod = 'In-app message';

  bool _privacyAccepted = false;
  bool _isSubmitting = false;

  final List<String> _categories = const [
    'General Support',
    'Employment',
    'Food & Essentials',
    'Education',
    'Health Support',
    'Housing',
    'Transport',
    'Business Support',
    'Emergency Assistance',
    'Other',
  ];

  final List<String> _contactMethods = const [
    'In-app message',
    'Phone call',
    'WhatsApp',
    'Email',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.trim().length >= 5 &&
        _descriptionController.text.trim().length >= 10 &&
        _privacyAccepted;
  }

  void _showPreview() {
    FocusScope.of(context).unfocus();

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the required information before continuing.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preview your request',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This is how your request will appear.',
                    style: TextStyle(
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        24,
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _selectedCategory.toUpperCase(),
                                      style: const TextStyle(
                                        color: _primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  _urgencyBadge(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _titleController.text.trim(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: _text,
                                  height: 1.15,
                                ),
                              ),
                              if (_locationController
                                  .text
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        _locationController.text
                                            .trim(),
                                        style: const TextStyle(
                                          color: _muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              Text(
                                _descriptionController.text.trim(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.55,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.contact_phone_outlined,
                                    color: _primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Preferred contact: '
                                      '$_selectedContactMethod',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : _submitRequest,
                            icon: const Icon(
                              Icons.send_rounded,
                            ),
                            label: Text(
                              _isSubmitting
                                  ? 'SUBMITTING...'
                                  : 'SUBMIT REQUEST',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize:
                                  const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
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
          },
        );
      },
    );
  }

  Widget _urgencyBadge() {
    Color color;

    switch (_selectedUrgency) {
      case 'Urgent':
        color = Colors.red;
        break;
      case 'High':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _selectedUrgency.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) return;

    Navigator.pop(context);

    setState(() {
      _isSubmitting = false;
    });

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF5EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1B7A4A),
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Request submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your information has been successfully captured in test mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(this.context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size.fromHeight(50),
                  ),
                  child: const Text('DONE'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _text,
        title: const Text(
          'Ask for Help',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),
          children: [
            const Text(
              'Tell the community what you need.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _text,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Provide enough information for someone to understand how they may be able to help you.',
              style: TextStyle(
                fontSize: 16,
                color: _muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'What kind of help do you need?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((String category) {
                final bool selected =
                    _selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  selectedColor:
                      _primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? _primary
                        : _text,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected
                        ? _primary
                        : Colors.grey.shade300,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            const Text(
              'How urgent is your request?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedUrgency,
              decoration: _inputDecoration(
                label: 'Select urgency',
                icon: Icons.priority_high_rounded,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Normal',
                  child: Text('Normal'),
                ),
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'Urgent',
                  child: Text('Urgent'),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) return;

                setState(() {
                  _selectedUrgency = value;
                });
              },
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              maxLength: 90,
              textCapitalization:
                  TextCapitalization.sentences,
              onChanged: (_) {
                setState(() {});
              },
              decoration: _inputDecoration(
                label: 'Short title',
                hint: 'Example: I need help improving my CV',
                icon: Icons.title_rounded,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _locationController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: _inputDecoration(
                label: 'Location (optional)',
                hint: 'Example: Soweto, Johannesburg',
                icon: Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _descriptionController,
              minLines: 6,
              maxLines: 10,
              maxLength: 1000,
              textCapitalization:
                  TextCapitalization.sentences,
              onChanged: (_) {
                setState(() {});
              },
              decoration: _inputDecoration(
                label: 'Explain what help you need',
                hint:
                    'Describe the situation and explain the kind of support that would make a difference.',
                icon: Icons.notes_rounded,
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'How would you prefer to be contacted?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            ..._contactMethods.map(
              (String method) {
                return RadioListTile<String>(
                  value: method,
                  groupValue: _selectedContactMethod,
                  activeColor: _primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(method),
                  onChanged: (String? value) {
                    if (value == null) return;

                    setState(() {
                      _selectedContactMethod = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: CheckboxListTile(
                value: _privacyAccepted,
                activeColor: _primary,
                controlAffinity:
                    ListTileControlAffinity.leading,
                title: const Text(
                  'I understand that I should not share sensitive personal information publicly.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    _privacyAccepted = value ?? false;
                  });
                },
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isFormValid ? _showPreview : null,
                icon: const Icon(
                  Icons.visibility_outlined,
                ),
                label: const Text(
                  'PREVIEW REQUEST',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade300,
                  disabledForegroundColor:
                      Colors.grey.shade600,
                  minimumSize:
                      const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: _primary,
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _primary,
          width: 1.8,
        ),
      ),
    );
  }
}
