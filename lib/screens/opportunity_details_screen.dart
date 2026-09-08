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
  final SupabaseClient _supabase =
      Supabase.instance.client;

  bool _isCheckingSaved = true;
  bool _isSaved = false;
  bool _isSaving = false;

  String? _savedOpportunityId;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  String _value(
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = widget.opportunity[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String get _opportunityId {
    return widget.opportunity['id']
            ?.toString() ??
        '';
  }

  String get _title {
    return _value(
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback: 'Untitled Opportunity',
    );
  }

  String get _description {
    return _value(
      [
        'description',
        'details',
        'summary',
      ],
      fallback: 'No description available.',
    );
  }

  String get _organisation {
    return _value(
      [
        'organisation',
        'organization',
        'company',
        'provider',
      ],
      fallback: 'Organisation not specified',
    );
  }

  String get _category {
    return _value(
      [
        'category',
        'type',
        'opportunity_type',
        'opportunity_category',
      ],
      fallback: 'Opportunity',
    );
  }

  String get _location {
    return _value(
      [
        'location',
        'province',
        'city',
      ],
    );
  }

  String get _closingDate {
    return _value(
      [
        'closing_date',
        'deadline',
        'closing',
      ],
    );
  }

  String get _url {
    return _value(
      [
        'url',
        'link',
        'application_url',
        'website',
      ],
    );
  }

  Future<void> _checkSavedStatus() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null ||
        _opportunityId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isCheckingSaved = false;
      });

      return;
    }

    try {
      final response = await _supabase
          .from('saved_opportunities')
          .select('id')
          .eq('user_id', user.id)
          .eq(
            'opportunity_id',
            _opportunityId,
          )
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        if (response != null) {
          _isSaved = true;
          _savedOpportunityId =
              response['id']?.toString();
        } else {
          _isSaved = false;
          _savedOpportunityId = null;
        }

        _isCheckingSaved = false;
      });
    } catch (error) {
      debugPrint(
        'Error checking saved opportunity: $error',
      );

      if (!mounted) return;

      setState(() {
        _isCheckingSaved = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in to save opportunities.',
          ),
        ),
      );

      return;
    }

    if (_opportunityId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This opportunity does not have a valid ID.',
          ),
        ),
      );

      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isSaved) {
        await _removeSavedOpportunity(
          user.id,
        );
      } else {
        await _saveOpportunity(
          user.id,
        );
      }
    } catch (error) {
      debugPrint(
        'Save opportunity error: $error',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update saved opportunities.\n$error',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveOpportunity(
    String userId,
  ) async {
    final response = await _supabase
        .from('saved_opportunities')
        .insert({
          'user_id': userId,
          'opportunity_id': _opportunityId,
        })
        .select('id')
        .single();

    if (!mounted) return;

    setState(() {
      _isSaved = true;
      _savedOpportunityId =
          response['id']?.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opportunity saved successfully.',
        ),
      ),
    );
  }

  Future<void> _removeSavedOpportunity(
    String userId,
  ) async {
    if (_savedOpportunityId != null) {
      await _supabase
          .from('saved_opportunities')
          .delete()
          .eq(
            'id',
            _savedOpportunityId!,
          );
    } else {
      await _supabase
          .from('saved_opportunities')
          .delete()
          .eq('user_id', userId)
          .eq(
            'opportunity_id',
            _opportunityId,
          );
    }

    if (!mounted) return;

    setState(() {
      _isSaved = false;
      _savedOpportunityId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Opportunity removed from saved opportunities.',
        ),
      ),
    );
  }

  IconData _categoryIcon() {
    final category =
        _category.toLowerCase();

    if (category.contains('job')) {
      return Icons.work_outline;
    }

    if (category.contains('tender')) {
      return Icons.description_outlined;
    }

    if (category.contains('fund')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (category.contains('train')) {
      return Icons.school_outlined;
    }

    if (category.contains('learn')) {
      return Icons.menu_book_outlined;
    }

    return Icons.campaign_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Opportunity',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isSaved
                ? 'Remove from saved'
                : 'Save opportunity',
            onPressed: _isCheckingSaved ||
                    _isSaving
                ? null
                : _toggleSave,
            icon: _isCheckingSaved
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(),

              const SizedBox(
                height: 28,
              ),

              Text(
                _title,
                style:
                    const TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w700,
                  height: 1.15,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _buildOrganisation(),

              if (_location.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                _buildInformationRow(
                  icon:
                      Icons.location_on_outlined,
                  label:
                      'Location',
                  value:
                      _location,
                ),
              ],

              if (_closingDate.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                _buildInformationRow(
                  icon:
                      Icons.calendar_today_outlined,
                  label:
                      'Closing date',
                  value:
                      _closingDate,
                ),
              ],

              const SizedBox(
                height: 32,
              ),

              const Text(
                'About this opportunity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                _description,
                style:
                    const TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
              ),

              if (_url.isNotEmpty) ...[
                const SizedBox(
                  height: 32,
                ),

                const Text(
                  'Application information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                SelectableText(
                  _url,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary,
                    fontSize: 16,
                  ),
                ),
              ],

              const SizedBox(
                height: 40,
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      _isCheckingSaved ||
                              _isSaving
                          ? null
                          : _toggleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Please wait...'
                        : _isSaved
                            ? 'SAVED'
                            : 'SAVE OPPORTUNITY',
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/saved-opportunities',
                    );
                  },
                  child: const Text(
                    'VIEW SAVED OPPORTUNITIES',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.10),
          ),
          child: Icon(
            _categoryIcon(),
            size: 30,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Text(
            _category,
            style: TextStyle(
              fontSize: 17,
              color:
                  Colors.grey.shade600,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganisation() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.business_outlined,
          size: 22,
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Text(
            _organisation,
            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color:
              Colors.grey.shade600,
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
