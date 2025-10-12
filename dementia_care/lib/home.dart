// ignore_for_file: use_build_context_synchronously

import 'package:dementia_care/screens/auth/auth_service.dart';
import 'package:dementia_care/screens/auth/profile_view.dart';
import 'package:dementia_care/screens/moods/moodcard.dart';
import 'package:dementia_care/widgets/memorycard.dart';
import 'package:dementia_care/widgets/welcome_card.dart';
import 'package:dementia_care/screens/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'widgets/bottomnav.dart';
import 'package:dementia_care/services/profile.dart';
import 'screens/gallery/gallery.dart';
import 'screens/moods/mood.dart';
import 'screens/auth/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/profile.dart';
import 'package:dementia_care/models/gallery.dart';
import 'package:dementia_care/models/memory.dart';
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
                            leading: const Icon(Icons.person),
                            title: const Text('View Profile'),
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
                                leading: const Icon(Icons.settings),
                                title: const Text('Settings'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.info),
                                title: const Text('About'),
                                onTap: () {
                                  Navigator.pop(context);
                                  showAboutDialog(
                                    context: context,
                                    applicationName: 'Dementia Care',
                                    applicationVersion: '1.0.0',
                                    applicationLegalese: '© 2025 brets corner',
                                    applicationIcon: Image.asset(
                                      'assets/images/dementia_care.png',
                                      width: 64,
                                      height: 64,
                                    ),
                                  );
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

  // Fetch recent gallery items for the current user and group them by date
  Future<List<MemoryGroup>> _getRecentMemories() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('gallery')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50); // Fetch more to have enough for grouping

    final List list = response as List;
    final galleries = list.map((e) => Gallery.fromJson(e)).toList();
    
    // Group images by date categories
    final Map<String, List<Gallery>> grouped = {};
    final now = DateTime.now();
    
    for (var gallery in galleries) {
      final createdDate = gallery.createdAt;
      final difference = now.difference(createdDate);
      
      String groupKey;
      if (difference.inDays == 0) {
        groupKey = 'Today';
      } else if (difference.inDays == 1) {
        groupKey = 'Yesterday';
      } else if (difference.inDays <= 7) {
        groupKey = 'This Week';
      } else if (difference.inDays <= 30) {
        groupKey = 'This Month';
      } else if (difference.inDays <= 90) {
        groupKey = 'Recent';
      } else {
        groupKey = 'Older';
      }
      
      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(gallery);
    }
    
    // Convert to MemoryGroup objects
    final memoryGroups = grouped.entries.map((entry) {
      final imageUrls = entry.value
          .map((g) => g.imageUrl ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      return MemoryGroup(title: entry.key, imageUrls: imageUrls);
    }).where((mg) => mg.imageUrls.isNotEmpty).toList();
    
    // Sort groups by priority (Today, Yesterday, This Week, etc.)
    final priorityOrder = ['Today', 'Yesterday', 'This Week', 'This Month', 'Recent', 'Older'];
    memoryGroups.sort((a, b) {
      final aIndex = priorityOrder.indexOf(a.title);
      final bIndex = priorityOrder.indexOf(b.title);
      return aIndex.compareTo(bIndex);
    });
    
    return memoryGroups;
  }

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

  Future<String?> _getLastMood() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response = await Supabase.instance.client
        .from('patient_mood')
        .select('''
          mood:mood_id (
            name
          )
        ''')
        .eq('user_id', user.id)
        .order('logged_at', ascending: false)
        .limit(1);

    final List list = response as List;
    if (list.isNotEmpty) {
      final moodData = list.first['mood'];
      return moodData?['name'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _getUserInfo(),
        shouldShowWelcomeCard(),
        _getLastMood(),
      ]).then((results) => {
        'userInfo': results[0],
        'showWelcome': results[1],
        'lastMood': results[2],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load user info.'));
        }

        final userInfo = snapshot.data?['userInfo'] as Map<String, String>? ?? {};
        final showWelcome = snapshot.data?['showWelcome'] as bool? ?? false;
        final lastMood = snapshot.data?['lastMood'] as String?;

        final greeting = _getGreeting();
        final userName = userInfo['name'] ?? 'User';
        final profilePicture = (userInfo['picture']?.isNotEmpty ?? false)
            ? userInfo['picture']!
            : "https://ui-avatars.com/api/?name=$userName&background=ccc&color=555&size=128";

        return SingleChildScrollView(
          child: Column(
            children: [
              if (showWelcome)
                WelcomeCard(lastMood: lastMood),
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
                    FutureBuilder<List<MemoryGroup>>(
                      future: _getRecentMemories(),
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
                            child: Center(child: Text('Failed to load memories', style: TextStyle(color: Colors.grey[600]))),
                          );
                        }
                        final memoryGroups = snapshot.data ?? [];
                        
                        if (memoryGroups.isEmpty) {
                          return SizedBox(
                            height: 150.0,
                            child: Center(
                              child: Text(
                                'No memories yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ),
                          );
                        }
                        
                        // Use MemoryCardList widget to display grouped memories
                        return MemoryCardList(memoryGroups: memoryGroups);
                      },
                    ),
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