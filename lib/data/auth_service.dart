import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'first_name': firstName},
    );

    // Profile creation is handled securely by the Phase 2 database trigger.
    // Do not upsert profiles here: email confirmation may leave the client unauthenticated.
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
