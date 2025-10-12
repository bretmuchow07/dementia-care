import 'package:flutter/material.dart';
import 'package:dementia_care/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile.dart';
import 'edit_account.dart';

class ProfileView extends StatefulWidget {
  final Profile profile;

  const ProfileView({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late Profile _profile;
  int _totalMoods = 0;
  int _currentStreak = 0;
  String _mostFrequentMood = 'None';
  String _memberSince = 'Unknown';

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Get member since date
      final userResponse = await Supabase.instance.client.auth.admin.getUserById(user.id);
      if (userResponse.user?.createdAt != null) {
        final createdDate = DateTime.parse(userResponse.user!.createdAt);
        _memberSince = '${createdDate.day}/${createdDate.month}/${createdDate.year}';
      }

      // Get total moods logged
      final moodResponse = await Supabase.instance.client
          .from('patient_mood')
          .select('id')
          .eq('user_id', user.id);

      _totalMoods = (moodResponse as List).length;

      // Get current streak (consecutive days with mood entries)
      final streakResponse = await Supabase.instance.client
          .from('patient_mood')
          .select('logged_at')
          .eq('user_id', user.id)
          .order('logged_at', ascending: false);

      if (streakResponse.isNotEmpty) {
        final dates = (streakResponse as List)
            .map((e) => DateTime.parse(e['logged_at']))
            .toList();

        _currentStreak = _calculateStreak(dates);
      }

      // Get most frequent mood
      final moodStatsResponse = await Supabase.instance.client
          .from('patient_mood')
          .select('''
            mood:mood_id (
              name
            )
          ''')
          .eq('user_id', user.id);

      if (moodStatsResponse.isNotEmpty) {
        final moodCounts = <String, int>{};
        for (final entry in moodStatsResponse) {
          final moodName = entry['mood']?['name'] as String?;
          if (moodName != null) {
            moodCounts[moodName] = (moodCounts[moodName] ?? 0) + 1;
          }
        }

        if (moodCounts.isNotEmpty) {
          _mostFrequentMood = moodCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading profile data: $e');
    }
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime currentDate = todayNormalized;

    for (final date in dates) {
      final dateNormalized = DateTime(date.year, date.month, date.day);

      if (dateNormalized == currentDate) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (dateNormalized.isBefore(currentDate)) {
        // Gap in streak
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Header with Background
            _buildProfileHeader(),

            const SizedBox(height: 32),

            // Patient Details Card
            _buildPatientDetailsCard(),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E7E).withOpacity(0.8),
            const Color(0xFF1B5E7E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E7E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture with enhanced styling
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8B894),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _profile.profilePicture != null && _profile.profilePicture!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _profile.profilePicture!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _profile.fullName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8B894),
      ),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPatientDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E7E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1B5E7E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Name Field
          _buildDetailField(
            'Full Name', 
            _profile.fullName,
            Icons.badge_outlined,
          ),

          const SizedBox(height: 16),

          // Date of Birth Field
          _buildDetailField(
            'Date of Birth',
            _profile.dateOfBirth?.isNotEmpty == true ? _profile.dateOfBirth! : 'Not specified',
            Icons.cake_outlined,
          ),

          const SizedBox(height: 16),

          // Email Field (from auth)
          _buildDetailField(
            'Email',
            Supabase.instance.client.auth.currentUser?.email ?? 'Not available',
            Icons.email_outlined,
          ),

          const SizedBox(height: 16),

          // Member Since Field
          _buildDetailField(
            'Member Since',
            _memberSince,
            Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 16),

          // Total Moods Logged
          _buildDetailField(
            'Total Moods Logged',
            _totalMoods.toString(),
            Icons.mood_outlined,
          ),

          const SizedBox(height: 16),

          // Current Streak
          _buildDetailField(
            'Current Streak',
            '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}',
            Icons.local_fire_department_outlined,
          ),

          const SizedBox(height: 16),

          // Most Frequent Mood
          _buildDetailField(
            'Most Frequent Mood',
            _mostFrequentMood,
            Icons.trending_up_outlined,
          ),

          const SizedBox(height: 16),

          // Address Field
          _buildDetailField(
            'Location',
            _profile.country?.isNotEmpty == true ? _profile.country! : 'Not specified',
            Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B894).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE8B894),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value == 'Not specified' 
                        ? Colors.grey[400]
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Edit Profile Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E7E).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AboutMePage(profile: _profile.toJson()),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E7E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Edit Account Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditAccountPage(profile: _profile),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 20),
              label: const Text(
                'Edit Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B5E7E),
                side: BorderSide(color: const Color(0xFF1B5E7E).withOpacity(0.3), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}