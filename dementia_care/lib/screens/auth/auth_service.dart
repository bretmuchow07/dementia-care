import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign In with Email and Password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get Current User's Email
  String? getCurrentUser() {
    final session = _supabase.auth.currentSession;
    return session?.user?.email;
  }

  // 🔐 Get Access Token (JWT)
  String? getAccessToken() {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  // 🔁 Get Refresh Token
  String? getRefreshToken() {
    final session = _supabase.auth.currentSession;
    return session?.refreshToken;
  }
}
