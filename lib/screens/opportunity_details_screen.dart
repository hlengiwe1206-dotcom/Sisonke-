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

  bool _isLoadingSaveStatus = true;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSaveStatus();
  }

  // ============================================================
  // DATA HELPERS
  // ============================================================

  String _getString(
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = widget.opportunity[key];

      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return fallback;
  }

  bool _getBool(
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value = widget.opportunity[key];

      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      final text =
          value
              .toString()
              .trim()
              .toLowerCase();

      return text == 'true' ||
          text == '1' ||
          text == 'yes';
    }

    return fallback;
  }

  String _title() {
    return _getString(
      [
        'title',
        'name',
        'opportunity_title',
      ],
      fallback: 'Untitled Opportunity',
    );
  }

  String _description() {
    return _getString(
      [
        'description',
        'summary',
        'details',
        'content',
      ],
    );
  }

  String _category() {
    return _getString(
      [
        'category',
        'type',
        'opportunity_type',
      ],
      fallback: 'Opportunity',
    );
  }

  String _organisation() {
    return _getString(
      [
        'organisation',
        'organization',
        'company',
        'provider',
        'source',
      ],
    );
  }

  String _location() {
    return _getString(
      [
        'location',
        'province',
        'city',
      ],
    );
  }

  String _referenceNumber() {
    return _getString(
      [
        'reference_number',
        'tender_number',
        'tender_id',
        'opportunity_number',
        'reference',
      ],
    );
  }

  String _applicationUrl() {
    return _getString(
      [
        'application_url',
        'apply_url',
        'url',
        'link',
        'source_url',
      ],
    );
  }

  String _requirements() {
    return _getString(
      [
        'requirements',
        'eligibility',
        'criteria',
      ],
    );
  }

  String _contactInformation() {
    return _getString(
      [
        'contact_information',
        'contact',
        'contact_details',
        'email',
      ],
    );
  }

  DateTime? _getDate(
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = widget.opportunity[key];

      if (value == null) {
        continue;
      }

      final date =
          DateTime.tryParse(
        value.toString(),
      );

      if (date != null) {
        return date.toLocal();
      }
    }

    return null;
  }

  DateTime? _closingDate() {
    return _getDate(
      [
        'closing_date',
        'deadline',
        'application_deadline',
        'expiry_date',
      ],
    );
  }

  DateTime? _publishedDate() {
    return _getDate(
      [
        'published_at',
        'created_at',
        'advert_date',
      ],
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _daysRemaining(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    final closing =
        DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        closing.difference(today).inDays;

    if (difference < 0) {
      return 'Closed';
    }

    if (difference == 0) {
      return 'Closes today';
    }

    if (difference == 1) {
      return '1 day remaining';
    }

    return '$difference days remaining';
  }

  // ============================================================
  // CATEGORY UI
  // ============================================================

  IconData _categoryIcon(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('tender')) {
      return Icons.description_outlined;
    }

    if (value.contains('job') ||
        value.contains('employment')) {
      return Icons.work_outline;
    }

    if (value.contains('fund') ||
        value.contains('grant')) {
      return Icons.account_balance_outlined;
    }

    if (value.contains('learnership') ||
        value.contains('internship') ||
        value.contains('apprenticeship')) {
      return Icons.school_outlined;
    }

    if (value.contains('training')) {
      return Icons.menu_book_outlined;
    }

    if (value.contains('business')) {
      return Icons.business_center_outlined;
    }

    if (value.contains('education') ||
        value.contains('bursary')) {
      return Icons.auto_stories_outlined;
    }

    return Icons.campaign_outlined;
  }

  Color _categoryColor(
    String category,
  ) {
    final value =
        category.toLowerCase();

    if (value.contains('tender')) {
      return const Color(0xFF7B1FA2);
    }

    if (value.contains('job') ||
        value.contains('employment')) {
      return const Color(0xFF1565C0);
    }

    if (value.contains('fund') ||
        value.contains('grant')) {
      return const Color(0xFF2E7D32);
    }

    if (value.contains('learnership') ||
        value.contains('internship') ||
        value.contains('apprenticeship')) {
      return const Color(0xFFF57C00);
    }

    if (value.contains('training')) {
      return const Color(0xFF00838F);
    }

    if (value.contains('business')) {
      return const Color(0xFF5D4037);
    }

    if (value.contains('education') ||
        value.contains('bursary')) {
      return const Color(0xFFC62828);
    }

    return const Color(0xFF37474F);
  }

  // ============================================================
  // SAVE STATUS
  // ============================================================

  Future<void> _loadSaveStatus() async {
    final user =
        _supabase.auth.currentUser;

    final opportunityId =
        widget.opportunity['id']?.toString();

    if (user == null ||
        opportunityId == null ||
        opportunityId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isSaved = false;
        _isLoadingSaveStatus = false;
      });

      return;
    }

    try {
      final response =
          await _supabase
              .from('opportunity_saves')
              .select('id')
              .eq(
                'user_id',
                user.id,
              )
              .eq(
                'opportunity_id',
                opportunityId,
              )
              .maybeSingle();

      if (!mounted) return;

      setState(() {
        _isSaved =
            response != null;

        _isLoadingSaveStatus = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaved = false;
        _isLoadingSaveStatus = false;
      });
    }
  }

  // ============================================================
  // SAVE / REMOVE
  // ============================================================

  Future<void> _toggleSave() async {
    if (_isSaving) {
      return;
    }

    final user =
        _supabase.auth.currentUser;

    final opportunityId =
        widget.opportunity['id']?.toString();

    if (user == null) {
      _showMessage(
        'Please sign in to save opportunities.',
        isError: true,
      );

      return;
    }

    if (opportunityId == null ||
        opportunityId.isEmpty) {
      _showMessage(
        'This opportunity cannot be saved because its ID is missing.',
        isError: true,
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
            .eq(
              'user_id',
              user.id,
            )
            .eq(
              'opportunity_id',
              opportunityId,
            );

        if (!mounted) return;

        setState(() {
          _isSaved = false;
        });

        _showMessage(
          'Removed from saved opportunities.',
        );
      } else {
        final existingSave =
            await _supabase
                .from('opportunity_saves')
                .select('id')
                .eq(
                  'user_id',
                  user.id,
                )
                .eq(
                  'opportunity_id',
                  opportunityId,
                )
                .maybeSingle();

        if (existingSave == null) {
          await _supabase
              .from('opportunity_saves')
              .insert(
            {
              'user_id': user.id,
              'opportunity_id':
                  opportunityId,
            },
          );
        }

        if (!mounted) return;

        setState(() {
          _isSaved = true;
        });

        _showMessage(
          'Opportunity saved successfully.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to update saved opportunity: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              isError
                  ? const Color(
                      0xFFE9322A,
                    )
                  : const Color(
                      0xFF198754,
                    ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final title =
        _title();

    final category =
        _category();

    final organisation =
        _organisation();

    final description =
        _description();

    final location =
        _location();

    final reference =
        _referenceNumber();

    final requirements =
        _requirements();

    final contact =
        _contactInformation();

    final applicationUrl =
        _applicationUrl();

    final closingDate =
        _closingDate();

    final publishedDate =
        _publishedDate();

    final verified =
        _getBool(
      [
        'is_verified',
        'verified',
      ],
    );

    final categoryColor =
        _categoryColor(
      category,
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F7F4),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F7F4),

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        title: const Text(
          'Opportunity Details',
        ),

        actions: [
          if (_isLoadingSaveStatus)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child:
                  SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              tooltip:
                  _isSaved
                      ? 'Remove from saved'
                      : 'Save opportunity',
              onPressed:
                  _isSaving
                      ? null
                      : _toggleSave,
              icon:
                  _isSaving
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
                          color:
                              _isSaved
                                  ? const Color(
                                      0xFFE9322A,
                                    )
                                  : null,
                        ),
            ),
        ],
      ),

      body: SafeArea(
        top: false,

        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HERO CARD
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  22,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFEAEAEA,
                    ),
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,

                          decoration:
                              BoxDecoration(
                            color:
                                categoryColor
                                    .withOpacity(
                              0.12,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: Icon(
                            _categoryIcon(
                              category,
                            ),

                            size: 30,

                            color:
                                categoryColor,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                category
                                    .toUpperCase(),

                                style:
                                    TextStyle(
                                  fontSize: 12,

                                  letterSpacing:
                                      1,

                                  fontWeight:
                                      FontWeight
                                          .w800,

                                  color:
                                      categoryColor,
                                ),
                              ),

                              if (verified) ...[
                                const SizedBox(
                                  height: 5,
                                ),

                                const Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color:
                                          Color(
                                        0xFF198754,
                                      ),
                                    ),

                                    SizedBox(
                                      width: 5,
                                    ),

                                    Text(
                                      'VERIFIED OPPORTUNITY',
                                      style:
                                          TextStyle(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color:
                                            Color(
                                          0xFF198754,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontSize: 25,
                        height: 1.2,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF1F232B,
                        ),
                      ),
                    ),

                    if (organisation
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        organisation,

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],

                    if (closingDate !=
                        null) ...[
                      const SizedBox(
                        height: 20,
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFFFF1F0,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),

                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_today_outlined,
                              size: 18,
                              color:
                                  Color(
                                0xFFE9322A,
                              ),
                            ),

                            const SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child: Text(
                                'Closes ${_formatDate(closingDate)}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  color:
                                      Color(
                                    0xFFE9322A,
                                  ),
                                ),
                              ),
                            ),

                            Text(
                              _daysRemaining(
                                closingDate,
                              ),

                              style:
                                  const TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    Color(
                                  0xFFE9322A,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // DETAILS
              // ==================================================

              _buildSection(
                title:
                    'About this opportunity',
                child:
                    description.isNotEmpty
                        ? Text(
                            description,
                            style:
                                const TextStyle(
                              fontSize: 15,
                              height: 1.55,
                              color:
                                  Color(
                                0xFF374151,
                              ),
                            ),
                          )
                        : const Text(
                            'No additional description has been provided.',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF9CA3AF,
                              ),
                            ),
                          ),
              ),

              if (location.isNotEmpty ||
                  reference.isNotEmpty ||
                  publishedDate != null)
                ...[
                  const SizedBox(
                    height: 16,
                  ),

                  _buildSection(
                    title:
                        'Opportunity information',

                    child: Column(
                      children: [
                        if (location.isNotEmpty)
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Location',
                            location,
                          ),

                        if (reference.isNotEmpty)
                          _buildInfoRow(
                            Icons
                                .confirmation_number_outlined,
                            'Reference',
                            reference,
                          ),

                        if (publishedDate != null)
                          _buildInfoRow(
                            Icons
                                .publish_outlined,
                            'Published',
                            _formatDate(
                              publishedDate,
                            ),
                          ),

                        if (closingDate != null)
                          _buildInfoRow(
                            Icons
                                .event_busy_outlined,
                            'Closing date',
                            _formatDate(
                              closingDate,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

              if (requirements
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                _buildSection(
                  title:
                      'Requirements / Eligibility',

                  child: Text(
                    requirements,

                    style:
                        const TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color:
                          Color(
                        0xFF374151,
                      ),
                    ),
                  ),
                ),
              ],

              if (contact
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                _buildSection(
                  title:
                      'Contact information',

                  child: Text(
                    contact,

                    style:
                        const TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color:
                          Color(
                        0xFF374151,
                      ),
                    ),
                  ),
                ),
              ],

              if (applicationUrl
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),

                _buildSection(
                  title:
                      'Application / Source',

                  child: SelectableText(
                    applicationUrl,

                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          Color(
                        0xFF1565C0,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 54,

                child: ElevatedButton.icon(
                  onPressed:
                      _isLoadingSaveStatus ||
                              _isSaving
                          ? null
                          : _toggleSave,

                  icon:
                      _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
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
                            ? 'Saved Opportunity'
                            : 'Save Opportunity',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSaved
                            ? const Color(
                                0xFFE9322A,
                              )
                            : const Color(
                                0xFF1F232B,
                              ),

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Center(
                child: Text(
                  _isSaved
                      ? 'This opportunity is saved to your account.'
                      : 'Save this opportunity to access it later.',

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(
                      0xFF9CA3AF,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REUSABLE UI
  // ============================================================

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFEAEAEA,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(
                0xFF1F232B,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 36,
            height: 36,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF3F4F6,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child: Icon(
              icon,

              size: 18,

              color:
                  const Color(
                0xFF4B5563,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  label,

                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(
                      0xFF9CA3AF,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xFF1F232B,
                    ),
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
