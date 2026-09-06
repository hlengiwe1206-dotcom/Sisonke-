import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
class ChatService {
 final SupabaseClient _client; ChatService(this._client);
 String get userId => _client.auth.currentUser!.id;
 Future<String?> conversationForConnection(String connectionId) async {
  final row=await _client.from('conversations').select('id').eq('connection_id',connectionId).maybeSingle(); return row?['id']?.toString();
 }
 Stream<List<SisonkeMessage>> watchMessages(String conversationId)=>_client.from('messages').stream(primaryKey:['id']).eq('conversation_id',conversationId).order('created_at').map((r)=>r.map(SisonkeMessage.fromMap).toList());
 Future<void> send(String conversationId,String text) async { if(text.trim().isEmpty)return; await _client.from('messages').insert({'conversation_id':conversationId,'sender_id':userId,'content':text.trim()}); }
}
