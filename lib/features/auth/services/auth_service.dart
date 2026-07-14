import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._supabase);

  final SupabaseClient _supabase;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
