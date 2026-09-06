import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _connectionsFuture;

  @override
  void initState() {
    super.initState();
    _connectionsFuture = _loadConnections();
  }

  Future<List<Map<String, dynamic>>> _loadConnections() async {
    try {
      final List<dynamic> data = await _supabase
          .from('profiles')
          .select()
          .limit(100);

      return data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _connectionsFuture = _loadConnections();
    });

    await _connectionsFuture;
  }

  String _safeText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final String text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _profileName(Map<String, dynamic> profile) {
    final String fullName = _safeText(
      profile['full_name'] ??
          profile['name'] ??
          profile['display_name'] ??
          profile['username'],
    );

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return 'Sisonke Community Member';
  }

  String _location(Map<String, dynamic> profile) {
    return _safeText(
      profile['location'] ??
          profile['city'] ??
          profile['province'],
      fallback: 'Sisonke Community',
    );
  }

  String _bio(Map<String, dynamic> profile) {
    return _safeText(
      profile['bio'] ??
          profile['about'] ??
          profile['description'],
      fallback: 'Building connections and making a difference in the community.',
    );
  }

  Future<void> _showProfile(
    Map<String, dynamic> profile,
  ) async {
    final String name = _profileName(profile);
    final String location = _location(profile);
    final String bio = _bio(profile);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You can now connect with $name through Sisonke.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Connect'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _connectionsFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: _refresh,
            );
          }

          final List<Map<String, dynamic>> profiles =
              snapshot.data ?? <Map<String, dynamic>>[];

          if (profiles.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const <Widget>[
                  SizedBox(height: 100),
                  Icon(
                    Icons.people_outline,
                    size: 64,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No connections to show yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back soon as more people join the Sisonke community.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              separatorBuilder: (
                BuildContext context,
                int index,
              ) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final Map<String, dynamic> profile = profiles[index];

                final String name = _profileName(profile);
                final String location = _location(profile);
                final String bio = _bio(profile);

                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showProfile(profile),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 26,
                            child: Text(
                              _initials(name),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
  });

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            'Unable to load connections',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}
