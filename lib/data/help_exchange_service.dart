import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/help_request.dart';
import '../models/help_offer.dart';

class HelpExchangeService {
  final SupabaseClient _client;
  HelpExchangeService(this._client);

  String get _userId => _client.auth.currentUser?.id ??
      (throw StateError('You must be signed in to use Sisonke.'));

  Stream<List<HelpRequest>> watchOpenRequests() => _client
      .from('help_request_feed')
      .stream(primaryKey: ['id'])
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .map((rows) => rows.map(HelpRequest.fromMap).toList());

  Future<List<HelpRequest>> fetchOpenRequests() async {
    final rows = await _client
        .from('help_request_feed')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(HelpRequest.fromMap)
        .toList();
  }

  Future<String> createRequest({
    required String title,
    required String content,
    String? categoryId,
    String? provinceId,
    String? municipalityId,
    String? communityId,
  }) async {
    final post = await _client.from('posts').insert({
      'user_id': _userId,
      'category_id': categoryId,
      'type': 'help_needed',
      'title': title.trim(),
      'content': content.trim(),
      'province_id': provinceId,
      'municipality_id': municipalityId,
      'community_id': communityId,
    }).select('id').single();

    final request = await _client.from('help_requests').insert({
      'post_id': post['id'],
      'requester_id': _userId,
      'status': 'open',
    }).select('id').single();
    return request['id'].toString();
  }

  Future<void> offerHelp({
    required String helpRequestId,
    required String message,
  }) => _client.from('help_offers').insert({
        'help_request_id': helpRequestId,
        'helper_id': _userId,
        'message': message.trim(),
        'status': 'pending',
      });

  Stream<List<HelpOffer>> watchOffers(String requestId) => _client
      .from('help_offers')
      .stream(primaryKey: ['id'])
      .eq('help_request_id', requestId)
      .order('created_at', ascending: false)
      .asyncMap((rows) async {
        final ids = rows.map((r) => r['helper_id'].toString()).toSet().toList();
        final profiles = <String, String>{};
        if (ids.isNotEmpty) {
          final profileRows = await _client
              .from('profiles')
              .select('id,first_name')
              .inFilter('id', ids);
          for (final row in (profileRows as List).cast<Map<String, dynamic>>()) {
            profiles[row['id'].toString()] = row['first_name']?.toString() ?? 'Community member';
          }
        }
        return rows.map((row) {
          final copy = Map<String, dynamic>.from(row);
          copy['helper'] = {'first_name': profiles[copy['helper_id'].toString()] ?? 'Community member'};
          return HelpOffer.fromMap(copy);
        }).toList();
      });

  Future<List<HelpOffer>> fetchOffers(String requestId) async {
    final rows = await _client
        .from('help_offers')
        .select('*, helper:profiles!help_offers_helper_id_fkey(first_name)')
        .eq('help_request_id', requestId)
        .order('created_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(HelpOffer.fromMap)
        .toList();
  }

  Future<String> acceptOffer(HelpOffer offer) async =>
      (await _client.rpc('accept_help_offer', params: {'p_help_offer_id': offer.id}))
          .toString();

  Future<void> withdrawOffer(String offerId) =>
      _client.rpc('withdraw_help_offer', params: {'p_help_offer_id': offerId});

  Future<void> completeConnection(String id) =>
      _client.rpc('complete_help_connection', params: {'p_connection_id': id});
}
