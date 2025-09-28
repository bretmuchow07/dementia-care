// ignore_for_file: use_build_context_synchronously

import 'package:dementia_care/models/profile.dart';
import 'package:dementia_care/screens/auth/auth_service.dart';
import 'package:dementia_care/screens/auth/profile_view.dart';
import 'package:dementia_care/screens/moods/moodcard.dart';
import 'package:dementia_care/widgets/memorycard.dart';
import 'package:flutter/material.dart';
import 'widgets/bottomnav.dart';
import 'package:dementia_care/services/profile.dart';
import 'screens/gallery/gallery.dart';
import 'screens/moods/mood.dart';
import 'screens/auth/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/patient_mood.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  Profile? _profile;

  final List<Widget> _pages = [
    const HomeScreenContent(),
    const GalleryPage(),
    const MoodPage(),
  ];

  Future<void> _loadProfile() async {
    final profile = await ProfileService().getProfile();
    setState(() {
      _profile = profile;
    });
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<String?> _getProfilePicture() async {
    final profile = await ProfileService().getProfile();
    return (profile?.profilePicture?.isNotEmpty ?? false) ? profile?.profilePicture : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getProfilePicture(),
      builder: (context, snapshot) {
        String profilePicture = "https://ui-avatars.com/api/?name=User&background=ccc&color=555&size=128";
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && (snapshot.data?.isNotEmpty ?? false)) {
          profilePicture = snapshot.data!;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF1F8FA),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dementia Care',
                  style: TextStyle(
                    color: Color(0xFF265F7E),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (BuildContext context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('My Profile'),
                            onTap: () {
                              Navigator.pop(context);
                              if (_profile != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileView(profile: _profile!),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile not loaded yet')),
                                );
                              }
                            },
                          ),
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Sign Out'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _authService.signOut();
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                      (route) => false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(profilePicture),
                  ),
                ),
              ],
            ),
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  // Fetch recent moods for the current user (most recent first, limit 10)
  Future<List<PatientMood>> _getRecentMoods() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('patient_mood')
        .select('''
          id,
          mood_id,
          logged_at,
          user_id,
          description,
          mood:mood_id (
            id,
            created_at,
            name,
            description
          )
        ''')
        .eq('user_id', user.id)
        .order('logged_at', ascending: false)
        .limit(10);

    final List list = response as List;
    return list.map((e) => PatientMood.fromJson(e)).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<Map<String, String>> _getUserInfo() async {
    final profile = await ProfileService().getProfile();
    final fullName = profile?.fullName ?? 'User';
    final firstName = fullName.split(' ').first;
    final profilePicture = profile?.profilePicture;
    return {
      'name': firstName,
      'picture': profilePicture ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load user info.'));
        }

        final greeting = _getGreeting();
        final userName = snapshot.data?['name'] ?? 'User';
        final profilePicture = (snapshot.data?['picture']?.isNotEmpty ?? false)
            ? snapshot.data!['picture']!
            : "https://ui-avatars.com/api/?name=$userName&background=ccc&color=555&size=128";

        return SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  height: 200,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 64, // 32 padding each side
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(profilePicture),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$greeting, $userName!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('This is the home page'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // My Memories Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Memories',
                          style: TextStyle(
                            color: Color(0xFF265F7E),
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GalleryPage()),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF265F7E),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MemoryCardList(),
                  ],
                ),
              ),
              // My Moods Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Moods',
                          style: TextStyle(
                            color: Color(0xFF265F7E),
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MoodPage()),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF265F7E),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<PatientMood>>(
                      future: _getRecentMoods(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 150.0,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return SizedBox(
                            height: 150.0,
                            child: Center(child: Text('Failed to load moods', style: TextStyle(color: Colors.grey[600]))),
                          );
                        }
                        final moods = snapshot.data ?? [];
                        return MoodCardList(moods: moods);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
