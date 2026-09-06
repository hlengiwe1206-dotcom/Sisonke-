import 'package:flutter/material.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = <String>[
    'All',
    'Jobs',
    'Tenders',
    'Business',
    'Training',
    'Community',
  ];

  final List<Map<String, dynamic>> _opportunities =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'title': 'Community Garden Coordinator',
      'organisation': 'Johannesburg Community Initiative',
      'category': 'Jobs',
      'location': 'Johannesburg, Gauteng',
      'type': 'Part-time',
      'date': 'Closing soon',
      'description':
          'Coordinate local community garden activities, volunteers and neighbourhood participation.',
      'requirements': <String>[
        'Good communication skills',
        'Experience working with communities',
        'Interest in environmental projects',
      ],
      'icon': Icons.eco_outlined,
      'featured': true,
    },
    <String, dynamic>{
      'title': 'Small Business Support Programme',
      'organisation': 'Enterprise Development Hub',
      'category': 'Business',
      'location': 'South Africa',
      'type': 'Business Support',
      'date': 'Open applications',
      'description':
          'A support programme designed to help emerging businesses access training, mentorship and business development opportunities.',
      'requirements': <String>[
        'Registered or emerging business',
        'Valid contact information',
        'Commitment to participate in the programme',
      ],
      'icon': Icons.business_center_outlined,
      'featured': true,
    },
    <String, dynamic>{
      'title': 'Digital Skills Training',
      'organisation': 'Future Skills Academy',
      'category': 'Training',
      'location': 'Online',
      'type': 'Training',
      'date': 'Applications open',
      'description':
          'Develop practical digital skills including communication, online tools and workplace readiness.',
      'requirements': <String>[
        'Access to a smartphone or computer',
        'Willingness to complete training',
      ],
      'icon': Icons.school_outlined,
      'featured': false,
    },
    <String, dynamic>{
      'title': 'Local Maintenance Tender',
      'organisation': 'Municipal Opportunities Portal',
      'category': 'Tenders',
      'location': 'Gauteng',
      'type': 'Tender',
      'date': 'Closing in 14 days',
      'description':
          'Opportunity for qualifying service providers to participate in local maintenance and infrastructure support services.',
      'requirements': <String>[
        'Registered business',
        'Relevant experience',
        'Required compliance documentation',
      ],
      'icon': Icons.description_outlined,
      'featured': true,
    },
    <String, dynamic>{
      'title': 'Youth Employment Opportunity',
      'organisation': 'Community Employment Network',
      'category': 'Jobs',
      'location': 'Soweto, Gauteng',
      'type': 'Full-time',
      'date': 'Closing in 7 days',
      'description':
          'Employment opportunity supporting local service delivery and community development initiatives.',
      'requirements': <String>[
        'South African identification document',
        'Reliable contact number',
        'Availability for interviews',
      ],
      'icon': Icons.work_outline,
      'featured': false,
    },
    <String, dynamic>{
      'title': 'Volunteer Community Project',
      'organisation': 'Sisoke Community Network',
      'category': 'Community',
      'location': 'Johannesburg',
      'type': 'Volunteer',
      'date': 'Ongoing',
      'description':
          'Join a local community initiative and connect with people working to improve neighbourhoods and support residents.',
      'requirements': <String>[
        'Interest in community development',
        'Willingness to participate',
      ],
      'icon': Icons.people_outline,
      'featured': false,
    },
  ];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOpportunities {
    return _opportunities.where((Map<String, dynamic> opportunity) {
      final String category =
          (opportunity['category'] ?? '').toString().toLowerCase();

      final String title =
          (opportunity['title'] ?? '').toString().toLowerCase();

      final String organisation =
          (opportunity['organisation'] ?? '').toString().toLowerCase();

      final String location =
          (opportunity['location'] ?? '').toString().toLowerCase();

      final bool categoryMatches =
          _selectedCategory == 'All' ||
          category == _selectedCategory.toLowerCase();

      final bool searchMatches =
          _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          organisation.contains(_searchQuery) ||
          location.contains(_searchQuery);

      return categoryMatches && searchMatches;
    }).toList();
  }

  void _openOpportunity(Map<String, dynamic> opportunity) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return OpportunityDetailScreen(opportunity: opportunity);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> opportunities =
        _filteredOpportunities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search opportunities',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 48,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder:
                    (BuildContext context, int index) {
                  return const SizedBox(width: 8);
                },
                itemBuilder:
                    (BuildContext context, int index) {
                  final String category = _categories[index];

                  return ChoiceChip(
                    label: Text(category),
                    selected:
                        _selectedCategory == category,
                    onSelected: (bool selected) {
                      if (!selected) {
                        return;
                      }

                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: opportunities.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 500),
                        );

                        if (!mounted) {
                          return;
                        }

                        setState(() {});
                      },
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          24,
                        ),
                        children: <Widget>[
                          Text(
                            '${opportunities.length} opportunities available',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),

                          const SizedBox(height: 12),

                          ...opportunities.map(
                            (Map<String, dynamic>
                                    opportunity) =>
                                Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child:
                                  _OpportunityCard(
                                opportunity:
                                    opportunity,
                                onTap: () {
                                  _openOpportunity(
                                    opportunity,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Text(
              'No opportunities found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try changing your search or selecting another category.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _searchController.clear();
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.opportunity,
    required this.onTap,
  });

  final Map<String, dynamic> opportunity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon =
        opportunity['icon'] as IconData? ??
            Icons.work_outline;

    final bool featured =
        opportunity['featured'] == true;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                opportunity['title']
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                            if (featured)
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          opportunity['organisation']
                              .toString(),
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                opportunity['description'].toString(),
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: opportunity['category']
                        .toString(),
                  ),
                  _InfoChip(
                    icon:
                        Icons.location_on_outlined,
                    label: opportunity['location']
                        .toString(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      opportunity['date'].toString(),
                      style: TextStyle(
                        color:
                            Theme.of(context)
                                .colorScheme
                                .primary,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style:
                const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class OpportunityDetailScreen extends StatefulWidget {
  const OpportunityDetailScreen({
    super.key,
    required this.opportunity,
  });

  final Map<String, dynamic> opportunity;

  @override
  State<OpportunityDetailScreen>
      createState() =>
          _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState
    extends State<OpportunityDetailScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _messageController =
      TextEditingController();

  bool _showInterestForm = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitInterest() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your interest has been submitted successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> opportunity =
        widget.opportunity;

    final IconData icon =
        opportunity['icon'] as IconData? ??
            Icons.work_outline;

    final List<dynamic> requirements =
        opportunity['requirements'] as List<dynamic>? ??
            <dynamic>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity Details'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 32,
                color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              opportunity['title'].toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              opportunity['organisation'].toString(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),

            const SizedBox(height: 20),

            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value:
                  opportunity['category'].toString(),
            ),

            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value:
                  opportunity['location'].toString(),
            ),

            _DetailRow(
              icon: Icons.work_outline,
              label: 'Type',
              value: opportunity['type'].toString(),
            ),

            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Status',
              value: opportunity['date'].toString(),
            ),

            const SizedBox(height: 24),

            Text(
              'About this opportunity',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),

            const SizedBox(height: 10),

            Text(
              opportunity['description'].toString(),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Requirements',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),

            const SizedBox(height: 10),

            ...requirements.map(
              (dynamic requirement) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color:
                            Theme.of(context)
                                .colorScheme
                                .primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          requirement.toString(),
                          style:
                              const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            if (_submitted)
              _buildSuccessCard()
            else if (_showInterestForm)
              _buildInterestForm()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _showInterestForm = true;
                    });
                  },
                  icon:
                      const Icon(Icons.send_outlined),
                  label:
                      const Text('I am interested'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tell us about yourself',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Complete the information below to test the opportunity interest and information input process.',
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon:
                  Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your name';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon:
                  Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your email';
              }

              if (!value.contains('@')) {
                return 'Enter a valid email address';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneController,
            keyboardType:
                TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon:
                  Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your phone number';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText:
                  'Why are you interested?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitInterest,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
              child:
                  const Text('Submit interest'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showInterestForm = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color:
          Theme.of(context)
              .colorScheme
              .primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.check_circle,
              size: 64,
              color:
                  Theme.of(context)
                      .colorScheme
                      .primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Interest submitted!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your information has been captured successfully for this test flow.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _submitted = false;
                  _showInterestForm = true;
                });
              },
              child:
                  const Text('Edit information'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 22,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
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
