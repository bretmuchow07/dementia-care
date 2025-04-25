import 'package:dementia_care/screens/auth/edit_profile.dart';
import 'package:dementia_care/screens/moods/moodcard.dart';
import 'package:dementia_care/widgets/memorycard.dart';
import 'package:flutter/material.dart';
import 'widgets/bottomnav.dart';
import 'screens/gallery/gallery.dart';
import 'screens/moods/mood.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages to switch between
  final List<Widget> _pages = [
    const HomeScreenContent(),
    const GalleryPage(),
    const MoodPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                            title: const Text('Edit Profile'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutMePage(),
                              ),
                              );
                            },
                            ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Sign Out'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/user_profile.jpg'),
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
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Centered Card
          Center(
            child: SizedBox(
              height: 200,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                color: Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage('assets/user_profile.jpg'),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to Dementia Care',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('This is the home page'),
                        ],
                      ),
                    ],
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
                        fontSize: 20,
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
                MemoryCardList(), // Ensure this is properly imported
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
                        fontSize: 20,
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
                MoodCardList(), // Ensure this is properly imported
              ],
            ),
          ),
        ],
      ),
    );
  }
}
