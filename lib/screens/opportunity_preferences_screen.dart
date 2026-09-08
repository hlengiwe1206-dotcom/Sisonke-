import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunityPreferencesScreen extends StatefulWidget {
  const OpportunityPreferencesScreen({super.key});

  @override
  State<OpportunityPreferencesScreen> createState() =>
      _OpportunityPreferencesScreenState();
}

class _OpportunityPreferencesScreenState
    extends State<OpportunityPreferencesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;

  final Set<String> _selectedTypes = {};
  final Set<String> _selectedProvinces = {};
  final Set<String> _selectedIndustries = {};
  final Set<String> _selectedSkills = {};

  final TextEditingController _keywordsController =
      TextEditingController();

  final List<String> _opportunityTypes = [
    'Jobs',
    'Tenders',
    'Funding',
    'Training',
    'Learnerships',
    'Internships',
    'Bursaries',
    'Business Opportunities',
    'Other',
  ];

  final List<String> _provinces = [
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
    'North West',
    'Western Cape',
  ];

  final List<String> _industries = [
    'Agriculture',
    'Construction',
    'Electrical',
    'Engineering',
    'Energy',
    'Finance',
    'Government',
    'Healthcare',
    'Horticulture',
    'ICT',
    'Manufacturing',
    'Mining',
    'Property',
    'Retail',
    'Security',
    'Transport',
    'Water',
    'Other',
  ];

  final List<String> _skills = [
    'Administration',
    'Business Development',
    'Construction',
    'Electrical Work',
    'Engineering',
    'Finance',
    'Gardening',
    'Horticulture',
    'ICT',
    'Leadership',
    'Maintenance',
    'Management',
    'Marketing',
    'Project Management',
    'Procurement',
    'Sales',
    'Technical Skills',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final metadata = user.userMetadata ?? {};

      final opportunityTypes =
          List<String>.from(metadata['opportunity_types'] ?? []);

      final provinces =
          List<String>.from(metadata['opportunity_provinces'] ?? []);

      final industries =
          List<String>.from(metadata['opportunity_industries'] ?? []);

      final skills =
          List<String>.from(metadata['opportunity_skills'] ?? []);

      final keywords =
          metadata['opportunity_keywords']?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _selectedTypes
          ..clear()
          ..addAll(opportunityTypes);

        _selectedProvinces
          ..clear()
          ..addAll(provinces);

        _selectedIndustries
          ..clear()
          ..addAll(industries);

        _selectedSkills
          ..clear()
          ..addAll(skills);

        _keywordsController.text = keywords;

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_saving) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before saving your preferences.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final existingMetadata =
          Map<String, dynamic>.from(user.userMetadata ?? {});

      existingMetadata['opportunity_types'] =
          _selectedTypes.toList();

      existingMetadata['opportunity_provinces'] =
          _selectedProvinces.toList();

      existingMetadata['opportunity_industries'] =
          _selectedIndustries.toList();

      existingMetadata['opportunity_skills'] =
          _selectedSkills.toList();

      existingMetadata['opportunity_keywords'] =
          _keywordsController.text.trim();

      await _supabase.auth.updateUser(
        UserAttributes(
          data: existingMetadata,
        ),
      );

      if (!mounted) return;

      _showMessage(
        'Your opportunity preferences have been saved.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not save preferences: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Widget _buildSection(
    String title,
    String subtitle,
    List<String> options,
    Set<String> selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected =
                  selected.contains(option);

              return FilterChip(
                label: Text(option),
                selected: isSelected,
                showCheckmark: true,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selected.add(option);
                    } else {
                      selected.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Personalise Opportunities'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalise Opportunities'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            32,
          ),
          children: [
            const Text(
              'Find opportunities that fit you',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Select your interests and Sisonke will use them to calculate your personalised opportunity matches.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              'Opportunity types',
              'What opportunities are you interested in?',
              _opportunityTypes,
              _selectedTypes,
            ),

            _buildSection(
              'Provinces',
              'Where would you like opportunities?',
              _provinces,
              _selectedProvinces,
            ),

            _buildSection(
              'Industries',
              'Select industries relevant to you.',
              _industries,
              _selectedIndustries,
            ),

            _buildSection(
              'Skills',
              'Select your skills and areas of experience.',
              _skills,
              _selectedSkills,
            ),

            const Text(
              'Personal keywords',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add words that describe opportunities you want to find.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _keywordsController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Example: electrician, smart meters, horticulture, project manager',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _saving ? null : _savePreferences,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE PREFERENCES',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
