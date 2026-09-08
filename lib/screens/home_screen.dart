import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_help_request_screen.dart';
import 'help_exchange_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'opportunities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  late Stream<List<Map<String, dynamic>>> _postsStream;

  String _userName = 'Sisonke Member';
  String? _avatarUrl;

  int _unreadNotifications = 0;

  bool _loadingProfile = true;

  RealtimeChannel? _notificationChannel;

  static const Color sisonkeGreen =
      Color(0xFF007749);

  static const Color sisonkeDarkGreen =
      Color(0xFF005A38);

  static const Color sisonkeRed =
      Color(0xFFDE3831);

  static const Color sisonkeBlue =
      Color(0xFF004B87);

  static const Color sisonkeGold =
      Color(0xFFFFB81C);

  static const Color background =
      Color(0xFFF8F7F2);

  static const Color textDark =
      Color(0xFF111111);

  @override
  void initState() {
    super.initState();

    _postsStream = _loadPosts();

    _loadProfile();

    _loadUnreadNotifications();

    _listenForNotifications();
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final user =
          _supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _loadingProfile = false;
          });
        }

        return;
      }

      final data = await _supabase
          .from('profiles')
          .select(
            'full_name, avatar_url',
          )
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      if (!mounted) return;

      final databaseName =
          data?['full_name']
              ?.toString()
              .trim();

      final emailName =
          user.email
                  ?.split('@')
                  .first
                  .trim() ??
              'Sisonke Member';

      setState(() {
        _userName =
            databaseName != null &&
                    databaseName.isNotEmpty
                ? databaseName
                : emailName;

        final avatar =
            data?['avatar_url']
                ?.toString()
                .trim();

        _avatarUrl =
            avatar != null &&
                    avatar.isNotEmpty
                ? avatar
                : null;

        _loadingProfile = false;
      });
    } catch (error) {
      debugPrint(
        'SISONKE PROFILE ERROR: $error',
      );

      if (!mounted) return;

      final user =
          _supabase.auth.currentUser;

      setState(() {
        _userName =
            user?.email
                    ?.split('@')
                    .first
                    .trim() ??
                'Sisonke Member';

        _loadingProfile = false;
      });
    }
  }

  String get _firstName {
    final name = _userName.trim();

    if (name.isEmpty) {
      return 'there';
    }

    return name.split(' ').first;
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<void> _loadUnreadNotifications() async {
    try {
      final user =
          _supabase.auth.currentUser;

      if (user == null) return;

      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq(
            'user_id',
            user.id,
          )
          .eq(
            'is_read',
            false,
          );

      if (!mounted) return;

      setState(() {
        _unreadNotifications =
            data.length;
      });
    } catch (error) {
      debugPrint(
        'SISONKE NOTIFICATION ERROR: $error',
      );
    }
  }

  void _listenForNotifications() {
    final user =
        _supabase.auth.currentUser;

    if (user == null) return;

    _notificationChannel =
        _supabase
            .channel(
              'home-notifications-${user.id}',
            )
            .onPostgresChanges(
              event:
                  PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter:
                  PostgresChangeFilter(
                type:
                    PostgresChangeFilterType
                        .eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (payload) {
                _loadUnreadNotifications();
              },
            )
            .subscribe();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const NotificationsScreen(),
      ),
    );

    await _loadUnreadNotifications();
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ProfileScreen(),
      ),
    );

    await _loadProfile();
  }

  Future<void> _openHelpExchange() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HelpExchangeScreen(),
      ),
    );
  }

  Future<void> _askForHelp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CreateHelpRequestScreen(),
      ),
    );
  }

  Future<void> _openOpportunities() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const OpportunitiesScreen(),
      ),
    );
  }

  // ============================================================
  // INFORMATION POSTS
  // ============================================================

  Stream<List<Map<String, dynamic>>> _loadPosts() {
    return _supabase
        .from('information_posts')
        .stream(
          primaryKey: ['id'],
        )
        .map(
          (posts) {
            final filtered =
                posts.where(
              (post) {
                final published =
                    _safeBool(
                  post['is_published'],
                  fallback: true,
                );

                final verified =
                    _safeBool(
                  post['is_verified'],
                  fallback: true,
                );

                return published &&
                    verified;
              },
            ).toList();

            filtered.sort(
              (a, b) {
                final aDate =
                    _postDate(a);

                final bDate =
                    _postDate(b);

                if (aDate == null &&
                    bDate == null) {
                  return 0;
                }

                if (aDate == null) {
                  return 1;
                }

                if (bDate == null) {
                  return -1;
                }

                return bDate
                    .compareTo(aDate);
              },
            );

            return filtered;
          },
        );
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadProfile(),
      _loadUnreadNotifications(),
    ]);

    if (!mounted) return;

    setState(() {
      _postsStream =
          _loadPosts();
    });

    await Future<void>.delayed(
      const Duration(
        milliseconds: 400,
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  bool _safeBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    return value
        .toString()
        .toLowerCase() ==
        'true';
  }

  DateTime? _postDate(
    Map<String, dynamic> post,
  ) {
    final value =
        post['published_at'] ??
            post['created_at'] ??
            post['updated_at'];

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Recently added';
    }

    final difference =
        DateTime.now().difference(
      date,
    );

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          background,

      body: SafeArea(
        child: RefreshIndicator(
          color: sisonkeGreen,

          onRefresh:
              _refreshHome,

          child:
              CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    0,
                  ),

                  child:
                      _buildHeader(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    26,
                    20,
                    0,
                  ),

                  child:
                      _buildWelcome(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    28,
                    20,
                    0,
                  ),

                  child:
                      _buildHelpHero(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    28,
                    20,
                    0,
                  ),

                  child:
                      _buildQuickActions(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    30,
                    20,
                    14,
                  ),

                  child:
                      _buildInformationHeader(),
                ),
              ),

              StreamBuilder<
                  List<
                      Map<String,
                          dynamic>>>(
                stream:
                    _postsStream,

                builder:
                    (context, snapshot) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          50,
                        ),
                        child:
                            Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                sisonkeGreen,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),
                        child:
                            _buildErrorState(
                          snapshot
                              .error
                              .toString(),
                        ),
                      ),
                    );
                  }

                  final posts =
                      snapshot.data ??
                          [];

                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          20,
                        ),
                        child:
                            _buildEmptyState(),
                      ),
                    );
                  }

                  return SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (
                        context,
                        index,
                      ) {
                        return Padding(
                          padding:
                              EdgeInsets.fromLTRB(
                            20,
                            index == 0
                                ? 0
                                : 12,
                            20,
                            index ==
                                    posts.length -
                                        1
                                ? 40
                                : 0,
                          ),

                          child:
                              _buildPostCard(
                            posts[index],
                          ),
                        );
                      },

                      childCount:
                          posts.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child:
              _buildSisonkeBrand(),
        ),

        const SizedBox(
          width: 12,
        ),

        _buildNotificationButton(),

        const SizedBox(
          width: 8,
        ),

        GestureDetector(
          onTap:
              _openProfile,

          child:
              _buildAvatar(
            radius: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildSisonkeBrand() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,

          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                sisonkeGreen,
                sisonkeGold,
                sisonkeRed,
                sisonkeBlue,
              ],
            ),

            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),

          child: const Icon(
            Icons.people_alt_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        const Text(
          'SISONKE',

          style: TextStyle(
            fontSize: 25,
            fontWeight:
                FontWeight.w900,
            letterSpacing: 1.2,
            color: textDark,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION BUTTON
  // ============================================================

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior:
          Clip.none,

      children: [
        Material(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          child:
              InkWell(
            borderRadius:
                BorderRadius.circular(
              16,
            ),

            onTap:
                _openNotifications,

            child:
                const SizedBox(
              width: 50,
              height: 50,

              child:
                  Icon(
                Icons
                    .notifications_none_rounded,

                size: 28,

                color:
                    textDark,
              ),
            ),
          ),
        ),

        if (_unreadNotifications >
            0)
          Positioned(
            top: -5,
            right: -5,

            child:
                Container(
              constraints:
                  const BoxConstraints(
                minWidth: 21,
                minHeight: 21,
              ),

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 5,
              ),

              alignment:
                  Alignment.center,

              decoration:
                  const BoxDecoration(
                color:
                    sisonkeRed,
                shape:
                    BoxShape.circle,
              ),

              child: Text(
                _unreadNotifications >
                        99
                    ? '99+'
                    : _unreadNotifications
                        .toString(),

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      10,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          _loadingProfile
              ? 'Welcome back'
              : 'Welcome back, $_firstName 👋',

          style:
              const TextStyle(
            fontSize: 32,
            height: 1.08,
            fontWeight:
                FontWeight.w900,
            color: textDark,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        const Text(
          'Real people. Real solutions. A brighter South Africa.',

          style: TextStyle(
            fontSize: 17,
            height: 1.45,
            color:
                Color(0xFF69707A),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELP HERO
  // ============================================================

  Widget _buildHelpHero() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            sisonkeDarkGreen,
            sisonkeGreen,
          ],
        ),

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        boxShadow: [
          BoxShadow(
            color:
                sisonkeGreen
                    .withAlpha(35),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .volunteer_activism_rounded,
                color:
                    Colors.white,
                size: 30,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                'HELP EXCHANGE',

                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      14,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      1.2,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'South Africans\nhelping South Africans.',

            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize:
                  27,
              height: 1.1,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Need something? Ask your community. Have something to give? Step forward.',

            style:
                TextStyle(
              color:
                  Colors.white70,
              fontSize:
                  15,
              height: 1.45,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          SizedBox(
            width:
                double.infinity,

            child:
                ElevatedButton(
              onPressed:
                  _openHelpExchange,

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    sisonkeGold,

                foregroundColor:
                    textDark,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 15,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    15,
                  ),
                ),
              ),

              child:
                  const Text(
                'VIEW HELP EXCHANGE',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'What can we do together?',

          style:
              TextStyle(
            fontSize: 23,
            fontWeight:
                FontWeight.w900,
            color: textDark,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                (constraints.maxWidth -
                        12) /
                    2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,

              children: [
                SizedBox(
                  width: width,
                  child:
                      _buildQuickActionCard(
                    title:
                        'ASK FOR\nHELP',
                    subtitle:
                        'Tell the community what you need',
                    icon:
                        Icons
                            .volunteer_activism_rounded,
                    color:
                        sisonkeRed,
                    onTap:
                        _askForHelp,
                  ),
                ),

                SizedBox(
                  width: width,
                  child:
                      _buildQuickActionCard(
                    title:
                        'I CAN\nHELP',
                    subtitle:
                        'Find someone who needs assistance',
                    icon:
                        Icons
                            .handshake_rounded,
                    color:
                        sisonkeGreen,
                    onTap:
                        _openHelpExchange,
                  ),
                ),

                SizedBox(
                  width: width,
                  child:
                      _buildQuickActionCard(
                    title:
                        'FIND\nHELP',
                    subtitle:
                        'Browse open community requests',
                    icon:
                        Icons.search_rounded,
                    color:
                        sisonkeBlue,
                    onTap:
                        _openHelpExchange,
                  ),
                ),

                SizedBox(
                  width: width,
                  child:
                      _buildQuickActionCard(
                    title:
                        'OPPORTUNITIES',
                    subtitle:
                        'Jobs, tenders, funding and training',
                    icon:
                        Icons
                            .business_center_rounded,
                    color:
                        sisonkeGold,
                    darkIcon:
                        true,
                    onTap:
                        _openOpportunities,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(
          height: 14,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _buildSmallAction(
                icon:
                    Icons.person_outline_rounded,
                label:
                    'My Profile',
                onTap:
                    _openProfile,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
                  _buildSmallAction(
                icon:
                    Icons
                        .notifications_none_rounded,
                label:
                    _unreadNotifications >
                            0
                        ? '$_unreadNotifications Notifications'
                        : 'Notifications',
                onTap:
                    _openNotifications,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool darkIcon = false,
  }) {
    return Material(
      color: color,

      borderRadius:
          BorderRadius.circular(
        23,
      ),

      child:
          InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          23,
        ),

        child:
            Container(
          height: 180,

          padding:
              const EdgeInsets.all(
            19,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                icon,
                size: 34,
                color: darkIcon
                    ? textDark
                    : Colors.white,
              ),

              const Spacer(),

              Text(
                title,

                style:
                    TextStyle(
                  color: darkIcon
                      ? textDark
                      : Colors.white,

                  fontSize:
                      21,

                  height:
                      1.05,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Text(
                subtitle,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    TextStyle(
                  color: darkIcon
                      ? textDark
                          .withAlpha(190)
                      : Colors.white70,

                  fontSize:
                      12.5,

                  height:
                      1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      child:
          InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        child:
            Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 15,
          ),

          child:
              Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                icon,
                size: 21,
                color:
                    sisonkeGreen,
              ),

              const SizedBox(
                width: 8,
              ),

              Flexible(
                child:
                    Text(
                  label,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    fontSize:
                        13,

                    fontWeight:
                        FontWeight.w700,
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
  // INFORMATION
  // ============================================================

  Widget _buildInformationHeader() {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'COMMUNITY INSIGHT',

          style:
              TextStyle(
            color:
                sisonkeGold,
            fontSize:
                13,
            letterSpacing:
                1.2,
            fontWeight:
                FontWeight.w900,
          ),
        ),

        SizedBox(
          height: 7,
        ),

        Text(
          'Verified information\nfor our community.',

          style:
              TextStyle(
            color:
                textDark,
            fontSize:
                27,
            height:
                1.12,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
  ) {
    final title =
        _safeText(
      post['title'],
      fallback:
          'Community Information',
    );

    final description =
        _safeText(
      post['description'],
      fallback:
          'Tap to view more information.',
    );

    final category =
        _safeText(
      post['category'],
      fallback:
          'Information',
    );

    final source =
        _safeText(
      post['source_name'] ??
          post['source'] ??
          post['organisation'],
    );

    final date =
        _formatDate(
      _postDate(post),
    );

    return Material(
      color:
          const Color(0xFF151515),

      borderRadius:
          BorderRadius.circular(
        24,
      ),

      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          24,
        ),

        onTap: () {
          _showPostDetails(
            post,
          );
        },

        child:
            Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),

          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,

                    decoration:
                        BoxDecoration(
                      color:
                          sisonkeGold
                              .withAlpha(
                        35,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons
                          .verified_rounded,
                      color:
                          sisonkeGold,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        Text(
                      category
                          .toUpperCase(),

                      style:
                          const TextStyle(
                        color:
                            sisonkeGold,
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            0.8,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        sisonkeGold,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(
                height: 17,
              ),

              Text(
                title,

                maxLines:
                    3,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      21,
                  height:
                      1.2,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                description,

                maxLines:
                    4,

                overflow:
                    TextOverflow.ellipsis,

                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                  fontSize:
                      14.5,
                  height:
                      1.5,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        Text(
                      source.isNotEmpty
                          ? source
                          : 'Sisonke',
                      maxLines:
                          1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize:
                            12,
                      ),
                    ),
                  ),

                  Text(
                    date,

                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize:
                          12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // POST DETAILS
  // ============================================================

  void _showPostDetails(
    Map<String, dynamic> post,
  ) {
    final title =
        _safeText(
      post['title'],
      fallback:
          'Community Information',
    );

    final description =
        _safeText(
      post['description'],
      fallback:
          'No additional information available.',
    );

    final category =
        _safeText(
      post['category'],
      fallback:
          'Information',
    );

    final source =
        _safeText(
      post['source_name'] ??
          post['source'] ??
          post['organisation'],
    );

    showModalBottomSheet(
      context: context,

      isScrollControlled:
          true,

      backgroundColor:
          Colors.transparent,

      builder:
          (context) {
        return DraggableScrollableSheet(
          initialChildSize:
              0.70,

          minChildSize:
              0.45,

          maxChildSize:
              0.94,

          builder:
              (
            context,
            controller,
          ) {
            return Container(
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFF151515),

                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(
                    28,
                  ),
                ),
              ),

              child:
                  ListView(
                controller:
                    controller,

                padding:
                    const EdgeInsets
                        .fromLTRB(
                  24,
                  16,
                  24,
                  40,
                ),

                children: [
                  Center(
                    child:
                        Container(
                      width: 45,
                      height: 5,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white24,

                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  Text(
                    category
                        .toUpperCase(),

                    style:
                        const TextStyle(
                      color:
                          sisonkeGold,
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing:
                          1,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    title,

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          27,
                      height:
                          1.15,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Text(
                    description,

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          16,
                      height:
                          1.6,
                    ),
                  ),

                  if (source.isNotEmpty) ...[
                    const SizedBox(
                      height: 25,
                    ),

                    const Divider(
                      color:
                          Colors.white12,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .business_outlined,
                          color:
                              Colors.white54,
                          size: 20,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                              Text(
                            source,

                            style:
                                const TextStyle(
                              color:
                                  Colors.white60,
                              fontSize:
                                  14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY / ERROR
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        28,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons
                .forum_outlined,
            size: 50,
            color:
                sisonkeGold,
          ),

          SizedBox(
            height: 15,
          ),

          Text(
            'Information is coming',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize:
                  20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Verified community information will appear here as it is published.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  Color(0xFF69707A),
              height:
                  1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String error,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        25,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child:
          Column(
        children: [
          const Icon(
            Icons
                .cloud_off_outlined,
            size: 48,
            color:
                sisonkeRed,
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'Unable to load information',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize:
                  20,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            error,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color:
                  Color(0xFF69707A),
              fontSize:
                  12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar({
    required double radius,
  }) {
    final hasAvatar =
        _avatarUrl != null &&
            _avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius:
          radius,

      backgroundColor:
          const Color(
        0xFFE6EFEA,
      ),

      backgroundImage:
          hasAvatar
              ? NetworkImage(
                  _avatarUrl!,
                )
              : null,

      child:
          hasAvatar
              ? null
              : Icon(
                  Icons.person,
                  size:
                      radius,
                  color:
                      sisonkeGreen,
                ),
    );
  }

  @override
  void dispose() {
    if (_notificationChannel !=
        null) {
      _supabase.removeChannel(
        _notificationChannel!,
      );
    }

    super.dispose();
  }
}
