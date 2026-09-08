import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> getUnreadCount() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return 0;
    }

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false);

    return response.length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
        })
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
        })
        .eq('user_id', user.id)
        .eq('is_read', false);
  }
} 
