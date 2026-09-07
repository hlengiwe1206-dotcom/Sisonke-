import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'opportunity_details_screen.dart';

class SavedOpportunitiesScreen extends StatefulWidget {
  const SavedOpportunitiesScreen({super.key});

  @override
  State<SavedOpportunitiesScreen> createState() =>
      _SavedOpportunitiesScreenState();
}

class _SavedOpportunitiesScreenState
    extends State<SavedOpportunitiesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _savedOpportunities = [];

  @override
  void initState() {
    super.initState();
    _loadSavedOpportunities();
  }

  Future<void> _loadSavedOpportunities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('You must be signed in to view saved opportunities.');
      }

      final response = await _supabase
          .from('opportunity_saves')
          .select('''
            id,
            opportunity_id,
            opportunities (*)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> opportunities = [];

      for (final item in response) {
        final opportunity =
            item['opportunities'];

        if (opportunity is Map<String, dynamic>) {
          opportunities.add(opportunity);
        }
      }

      if (!mounted) return;

      setState(() {
        _savedOpportunities = opportunities;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeSavedOpportunity(
    String opportunityId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      await _supabase
          .from('opportunity_saves')
          .delete()
          .eq('user_id', user.id)
          .eq('opportunity_id', opportunityId);

      if (!mounted) return;

      setState(() {
        _savedOpportunities.removeWhere(
          (opportunity) =>
              opportunity['id'].toString() == opportunityId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opportunity removed from saved opportunities.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove opportunity: $error',
          ),
        ),
      );
    }
  }

  Future<void> _openOpportunity(
    Map<String, dynamic> opportunity,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OpportunityDetailsScreen(
          opportunity: opportunity,
        ),
      ),
    );

    await _loadSavedOpportunities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Opportunities',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedOpportunities,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),

          Icon(
            Icons.error_outline,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Unable to load saved opportunities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: _loadSavedOpportunities,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_savedOpportunities.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 100),

          Icon(
            Icons.bookmark_border,
            size: 64,
          ),

          SizedBox(height: 20),

          Center(
            child: Text(
              'No Saved Opportunities Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 10),

          Center(
            child: Text(
              'Opportunities you save will appear here.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _savedOpportunities.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final opportunity =
            _savedOpportunities[index];

        return _OpportunityCard(
          opportunity: opportunity,
          onTap: () => _openOpportunity(opportunity),
          onRemove: () {
            _removeSavedOpportunity(
              opportunity['id'].toString(),
            );
          },
        );
      },
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> opportunity;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _OpportunityCard({
    required this.opportunity,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        opportunity['title']?.toString() ??
            'Untitled Opportunity';

    final organisation =
        opportunity['organisation']?.toString() ??
            '';

    final location =
        opportunity['location']?.toString() ??
            '';

    final opportunityType =
        opportunity['opportunity_type']?.toString() ??
            '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (opportunityType.isNotEmpty)
                      Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          opportunityType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (organisation.isNotEmpty) ...[
                      const SizedBox(height: 8),

                      Text(
                        organisation,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],

                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                          ),

                          const SizedBox(width: 4),

                          Expanded(
                            child: Text(
                              location,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                tooltip:
                    'Remove from saved opportunities',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.bookmark_remove_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
