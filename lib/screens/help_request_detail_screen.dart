import 'package:flutter/material.dart';

import 'create_help_request_screen.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? request;

  const HelpRequestDetailScreen({
    super.key,
    this.request,
  });

  @override
  State<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
}

/// Compatibility class.
///
/// This allows older files that still use
/// HelpRequestDetailsScreen
/// to continue working while the app transitions
/// to the singular HelpRequestDetailScreen name.
class HelpRequestDetailsScreen extends HelpRequestDetailScreen {
  const HelpRequestDetailsScreen({
    super.key,
    super.request,
  });
}

class _HelpRequestDetailScreenState extends State<HelpRequestDetailScreen> {
  bool _wantToHelp = false;
  bool _contactRequested = false;

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String _getTitle() {
    final request = widget.request;

    if (request == null) {
      return 'Community Help Request';
    }

    return _safeText(
      request['title'],
      fallback: _safeText(
        request['name'],
        fallback: 'Community Help Request',
      ),
    );
  }

  String _getDescription() {
    final request = widget.request;

    if (request == null) {
      return 'No additional information has been provided yet.';
    }

    return _safeText(
      request['description'],
      fallback: _safeText(
        request['details'],
        fallback:
            'No additional information has been provided yet.',
      ),
    );
  }

  String _getCategory() {
    final request = widget.request;

    if (request == null) {
      return 'Community Support';
    }

    return _safeText(
      request['category'],
      fallback: 'Community Support',
    );
  }

  String _getLocation() {
    final request = widget.request;

    if (request == null) {
      return 'Location not specified';
    }

    return _safeText(
      request['location'],
      fallback: _safeText(
        request['city'],
        fallback: 'Location not specified',
      ),
    );
  }

  String _getUrgency() {
    final request = widget.request;

    if (request == null) {
      return 'Normal';
    }

    return _safeText(
      request['urgency'],
      fallback: 'Normal',
    );
  }

  String _getRequesterName() {
    final request = widget.request;

    if (request == null) {
      return 'Community Member';
    }

    return _safeText(
      request['requester_name'],
      fallback: _safeText(
        request['name'],
        fallback: 'Community Member',
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food & essentials':
      case 'food':
        return Icons.restaurant_outlined;

      case 'transport':
        return Icons.directions_car_outlined;

      case 'education':
        return Icons.school_outlined;

      case 'employment':
      case 'jobs':
        return Icons.work_outline;

      case 'business support':
      case 'business':
        return Icons.business_outlined;

      case 'health & wellness':
      case 'health':
        return Icons.favorite_outline;

      default:
        return Icons.volunteer_activism_outlined;
    }
  }

  void _toggleHelp() {
    setState(() {
      _wantToHelp = !_wantToHelp;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _wantToHelp
              ? 'Thank you! You have indicated that you want to help.'
              : 'You are no longer marked as helping.',
        ),
      ),
    );
  }

  void _requestContact() {
    setState(() {
      _contactRequested = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Contact request captured successfully.',
        ),
      ),
    );
  }

  void _createNewRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateHelpRequestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle();
    final description = _getDescription();
    final category = _getCategory();
    final location = _getLocation();
    final urgency = _getUrgency();
    final requesterName = _getRequesterName();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text('Help Request'),
        centerTitle: false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// CATEGORY AND URGENCY
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcon(category),
                          size: 18,
                          color: Colors.blue.shade700,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _urgencyColor(urgency)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      urgency.toUpperCase(),
                      style: TextStyle(
                        color: _urgencyColor(urgency),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// TITLE
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 20),

              /// REQUESTER
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      requesterName.isNotEmpty
                          ? requesterName.substring(0, 1).toUpperCase()
                          : 'C',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requested by',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      Text(
                        requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// LOCATION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.red.shade400,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// DESCRIPTION HEADING
              const Text(
                'About this request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// DESCRIPTION
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              /// COMMUNITY SUPPORT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism_outlined,
                          size: 28,
                        ),

                        SizedBox(width: 10),

                        Text(
                          'Community Action',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'You can indicate that you want to assist '
                      'with this request or request contact '
                      'information.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton.icon(
                        onPressed: _toggleHelp,

                        icon: Icon(
                          _wantToHelp
                              ? Icons.check_circle
                              : Icons.volunteer_activism,
                        ),

                        label: Text(
                          _wantToHelp
                              ? 'You Offered to Help'
                              : 'I Want to Help',
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: _wantToHelp
                              ? Colors.green
                              : null,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: OutlinedButton.icon(
                        onPressed: _contactRequested
                            ? null
                            : _requestContact,

                        icon: Icon(
                          _contactRequested
                              ? Icons.check_circle_outline
                              : Icons.contact_phone_outlined,
                        ),

                        label: Text(
                          _contactRequested
                              ? 'Contact Request Sent'
                              : 'Request Contact',
                        ),

                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// CREATE REQUEST
              const Text(
                'Need help yourself?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Create your own help request and share it '
                'with the Sisonke community.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: OutlinedButton.icon(
                  onPressed: _createNewRequest,

                  icon: const Icon(Icons.add_circle_outline),

                  label: const Text(
                    'Create Help Request',
                  ),

                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 
