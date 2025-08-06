import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/patient_mood.dart';

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  List<PatientMood> _patientMoods = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMoodHistory();
  }

  Future<void> _fetchMoodHistory() async {
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
          .order('logged_at', ascending: false);

      final List<PatientMood> moods = (response as List)
          .map((json) => PatientMood.fromJson(json))
          .toList();

      setState(() {
        _patientMoods = moods;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch mood history: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF265F7E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mood History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
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
                        onPressed: _fetchMoodHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _patientMoods.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mood_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No mood history found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start tracking your moods to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMoodHistory,
                      child: _buildMoodHistoryList(),
                    ),
    );
  }

  Widget _buildMoodHistoryList() {
    final groupedMoods = _groupMoodsByDate(_patientMoods);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: groupedMoods.length,
      itemBuilder: (context, index) {
        final entry = groupedMoods.entries.elementAt(index);
        final dateLabel = entry.key;
        final moods = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 32),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...moods.map((mood) => _buildMoodItem(mood)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildMoodItem(PatientMood mood) {
    final moodName = mood.mood?.name ?? 'Unknown';
    final moodDescription = mood.mood?.description ?? '';
    final userDescription = mood.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF265F7E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMoodIcon(moodName),
              color: const Color(0xFF265F7E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moodName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (moodDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    moodDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (userDescription != null && userDescription.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$userDescription"',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTime(mood.loggedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String moodName) {
    switch (moodName.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return Icons.sentiment_very_satisfied;
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return Icons.self_improvement;
      case 'neutral':
      case 'okay':
        return Icons.sentiment_neutral;
      case 'sad':
      case 'down':
      case 'upset':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'frustrated':
      case 'annoyed':
        return Icons.sentiment_dissatisfied;
      case 'confused':
      case 'lost':
        return Icons.help_outline;
      case 'anxious':
      case 'worried':
        return Icons.psychology;
      case 'tired':
      case 'exhausted':
        return Icons.bedtime;
      case 'energetic':
      case 'active':
        return Icons.bolt;
      default:
        return Icons.mood;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:$minute $period';
  }

  Map<String, List<PatientMood>> _groupMoodsByDate(List<PatientMood> moods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<PatientMood>> grouped = {};

    for (final mood in moods) {
      final moodDate = DateTime(
        mood.loggedAt.year,
        mood.loggedAt.month,
        mood.loggedAt.day,
      );

      String dateLabel;
      if (moodDate == today) {
        dateLabel = 'Today';
      } else if (moodDate == yesterday) {
        dateLabel = 'Yesterday';
      } else {
        // Format: "January 15, 2024"
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        dateLabel = '${months[moodDate.month - 1]} ${moodDate.day}, ${moodDate.year}';
      }

      grouped.putIfAbsent(dateLabel, () => []).add(mood);
    }

    // Sort moods within each day by time (newest first)
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }

    // Create sorted map with proper order
    final sortedGrouped = <String, List<PatientMood>>{};
    if (grouped.containsKey('Today')) {
      sortedGrouped['Today'] = grouped['Today']!;
    }
    if (grouped.containsKey('Yesterday')) {
      sortedGrouped['Yesterday'] = grouped['Yesterday']!;
    }

    // Sort other dates (newest first)
    final otherDates = grouped.keys
        .where((key) => key != 'Today' && key != 'Yesterday')
        .toList();
    
    // Sort by actual date, not string comparison
    otherDates.sort((a, b) {
      // Parse dates for proper sorting
      final dateA = _parseDateLabel(a);
      final dateB = _parseDateLabel(b);
      return dateB.compareTo(dateA);
    });

    for (final date in otherDates) {
      sortedGrouped[date] = grouped[date]!;
    }

    return sortedGrouped;
  }

  DateTime _parseDateLabel(String dateLabel) {
    // Helper to parse formatted date labels back to DateTime for sorting
    final parts = dateLabel.split(' ');
    if (parts.length == 3) {
      final months = {
        'January': 1, 'February': 2, 'March': 3, 'April': 4,
        'May': 5, 'June': 6, 'July': 7, 'August': 8,
        'September': 9, 'October': 10, 'November': 11, 'December': 12
      };
      final month = months[parts[0]] ?? 1;
      final day = int.tryParse(parts[1].replaceAll(',', '')) ?? 1;
      final year = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }
}