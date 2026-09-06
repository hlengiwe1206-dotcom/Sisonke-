import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService();

  final SupabaseClient supabase = Supabase.instance.client;

  /// Returns the currently logged-in user.
  User? get currentUser {
    return supabase.auth.currentUser;
  }

  /// Returns the current user's ID.
  String? get currentUserId {
    return supabase.auth.currentUser?.id;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  /// Create a new user account.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    return response;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Send a password reset email.
  Future<void> resetPassword({
    required String email,
  }) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  /// Update the current user's password.
  Future<UserResponse> updatePassword({
    required String password,
  }) async {
    final response = await supabase.auth.updateUser(
      UserAttributes(
        password: password,
      ),
    );

    return response;
  }
}
