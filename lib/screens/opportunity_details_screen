import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> opportunity;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunity,
  });

  @override
  State<OpportunityDetailsScreen> createState() =>
      _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState
    extends State<OpportunityDetailsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isSaving = false;
  bool _isSaved = false;

  Map<String, dynamic> get opportunity => widget.opportunity;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) return;

      final opportunityId = opportunity['id'];

      if (opportunityId == null) return;

      final result = await _supabase
          .from('opportunity_saves')
          .select('id')
          .eq('user_id', user.id)
          .eq('opportunity_id', opportunityId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isSaved = result != null;
      });
    } catch (_) {
      // Do not interrupt the screen if the saved-status check fails.
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save opportunities.'),
        ),
      );

      return;
    }

    final opportunityId = opportunity['id'];

    if (opportunityId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This opportunity could not be saved.'),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isSaved) {
        await _supabase
            .from('opportunity_saves')
            .delete()
            .eq('user_id', user.id)
            .eq('opportunity_id', opportunityId);

        if (!mounted) return;

        setState(() {
          _isSaved = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity removed from saved opportunities.'),
          ),
        );
      } else {
        await _supabase.from('opportunity_saves').insert({
          'user_id': user.id,
          'opportunity_id': opportunityId,
        });

        if (!mounted) return;

        setState(() {
          _isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opportunity saved successfully.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update saved opportunity: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _value(String key, {String fallback = ''}) {
    final value = opportunity[key];

    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not specified';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'tender':
      case 'procurement':
        return const Color(0xFFFF7A00);

      case 'employment':
      case 'job':
      case 'jobs':
        return const Color(0xFF2563EB);

      case 'funding':
      case 'grant':
        return const Color(0xFF7C3AED);

      case 'learnership':
      case 'learnerships':
      case 'training':
      case 'education':
        return const Color(0xFF059669);

      default:
        return const Color(0xFF1F4F7C);
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'tender':
      case 'procurement':
        return Icons.description_outlined;

      case 'employment':
      case 'job':
      case 'jobs':
        return Icons.work_outline;

      case 'funding':
      case 'grant':
        return Icons.account_balance_outlined;

      case 'learnership':
      case 'learnerships':
      case 'training':
      case 'education':
        return Icons.school_outlined;

      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _value(
      'title',
      fallback: 'Untitled Opportunity',
    );

    final description = _value(
      'description',
      fallback: 'No description available for this opportunity.',
    );

    final organisation = _value(
      'organisation',
      fallback: 'Organisation not specified',
    );

    final location = _value(
      'location',
      fallback: 'Location not specified',
    );

    final opportunityType = _value(
      'opportunity_type',
      fallback: _value(
        'type',
        fallback: 'Opportunity',
      ),
    );

    final deadline =
        opportunity['closing_date'] ??
        opportunity['deadline'] ??
        opportunity['application_deadline'];

    final color = _typeColor(opportunityType);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F232B),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: const Text(
          'Opportunity Details',
          style: TextStyle(
            color: Color(0xFF1F232B),
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _isSaving ? null : _toggleSave,

            icon: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: const Color(0xFF1F232B),
                  ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TYPE CARD

            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
              ),

              child: Row(
                children: [

                  Container(
                    width: 58,
                    height: 58,

                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      _typeIcon(opportunityType),
                      color: color,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          opportunityType.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          organisation,
                          style: const TextStyle(
                            color: Color(0xFF1F232B),
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TITLE

            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1F232B),
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 24),

            // INFORMATION

            _InfoCard(
              icon: Icons.business_outlined,
              label: 'Organisation',
              value: organisation,
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location,
            ),

            const SizedBox(height: 12),

            if (deadline != null)
              _InfoCard(
                icon: Icons.calendar_today_outlined,
                label: 'Closing date',
                value: _formatDate(deadline),
              ),

            if (deadline != null)
              const SizedBox(height: 28),

            if (deadline == null)
              const SizedBox(height: 16),

            // DESCRIPTION

            const Text(
              'About this opportunity',
              style: TextStyle(
                color: Color(0xFF1F232B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // SAVE BUTTON

            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : _toggleSave,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaved
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF1F4F7C),

                  foregroundColor:
                      _isSaved
                          ? const Color(0xFF1F232B)
                          : Colors.white,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),

                icon: Icon(
                  _isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),

                label: Text(
                  _isSaved
                      ? 'Saved Opportunity'
                      : 'Save Opportunity',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 44,
            height: 44,

            decoration: const BoxDecoration(
              color: Color(0xFFEAF0F5),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: Color(0xFF1F4F7C),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1F232B),
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
