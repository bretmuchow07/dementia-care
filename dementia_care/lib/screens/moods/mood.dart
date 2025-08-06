// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:dementia_care/screens/moods/moodcard.dart';
import 'package:dementia_care/screens/moods/add_mood.dart';
import 'package:dementia_care/screens/moods/mood_history.dart';
import 'package:dementia_care/models/patient_mood.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  PatientMood? _latestMood;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLatestMood();
  }

  Future<void> _fetchLatestMood() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _loading = false;
        });
        return;
      }

      // Fixed table name and added mood relation
      final response = await Supabase.instance.client
          .from('patient_mood') // Fixed table name (was 'patient_moods')
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
          .eq('user_id', user.id) // Fixed column name (was 'patient_id')
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        if (response != null) {
          _latestMood = PatientMood.fromJson(response);
        } else {
          _latestMood = null;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch mood: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Widget _buildMoodDisplay() {
    if (_latestMood == null) {
      return Container(
        height: 160.0,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mood,
                size: 40,
                color: Color(0xFF265F7E),
              ),
              SizedBox(height: 8),
              Text(
                "No mood recorded today",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If mood data is available, display it
    return Container(
      height: 160.0,
      decoration: BoxDecoration(
        color: const Color(0xFF265F7E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF265F7E),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _latestMood!.mood?.name ?? 'Unknown Mood',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF265F7E),
              ),
            ),
            const SizedBox(height: 8),
            if (_latestMood!.mood?.description != null)
              Text(
                _latestMood!.mood!.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            const SizedBox(height: 8),
            if (_latestMood!.description != null)
              Text(
                '"${_latestMood!.description}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF888888),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Logged: ${_formatTime(_latestMood!.loggedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchLatestMood,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLatestMood,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          const Padding(
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Latest Mood',
                                style: TextStyle(
                                  color: Color(0xFF265F7E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),

                          // Mood Display
                          Center(
                            child: SizedBox(
                              width: cardWidth,
                              child: _buildMoodDisplay(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Buttons
                          Center(
                            child: Column(
                              children: [
                                // Add mood
                                SizedBox(
                                  width: cardWidth,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final user = Supabase
                                          .instance.client.auth.currentUser;
                                      if (user != null) {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddMoodScreen(
                                              patientId: user.id,
                                              onMoodSaved: (mood) {
                                                _fetchLatestMood(); // Refresh mood
                                              },
                                            ),
                                          ),
                                        );
                                        // Refresh if mood was added
                                        if (result == true) {
                                          _fetchLatestMood();
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF265F7E),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      'How are you feeling today?',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Mood history
                                SizedBox(
                                  width: cardWidth,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MoodHistoryScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE2E8EA),
                                      foregroundColor: const Color(0xFF265F7E),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Mood History',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Mood Board
                          const Padding(
                            padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Mood Board',
                                style: TextStyle(
                                  color: Color(0xFF265F7E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),

                          // Placeholder for mood board content
                          Container(
                            height: 200,
                            width: cardWidth,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Mood Board Coming Soon...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}