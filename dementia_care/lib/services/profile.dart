import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/profile.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('No user is logged in.');
      return null;
    }

    final response = await _client
        .from('profile') // ✅ Your actual table name
        .select('id, full_name, profile_picture')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      print('No profile data found.');
      return null;
    }

    return Profile.fromJson(response);
  }
}
