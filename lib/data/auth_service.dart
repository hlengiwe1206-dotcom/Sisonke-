import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService();

  final SupabaseClient supabase =
      Supabase.instance.client;

  User? get currentUser {
    return supabase.auth.currentUser;
  }

  String? get currentUserId {
    return supabase.auth.currentUser?.id;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
      },
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await supabase.auth.resetPasswordForEmail(
      email,
    );
  }

  Future<UserResponse> updatePassword({
    required String password,
  }) async {
    return await supabase.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );
  }
}
