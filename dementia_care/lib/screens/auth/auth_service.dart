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
    return session?.user.email;
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

  // Check if user profile exists in public.profile table
  Future<bool> checkUserProfile(String userId) async {
    final response = await _supabase
        .from('profile')
        .select('id')
        .eq('userId', userId)
        .maybeSingle();

    return response != null;
  }

  // ✏️ Update Username (in public.profile table)
  Future<void> updateUsername(String userId, String newUsername) async {
    await _supabase
        .from('profile')
        .update({'email': newUsername})
        .eq('id', userId);
  }

  // 🔐 Change Password
  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
