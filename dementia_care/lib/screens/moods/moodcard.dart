import 'package:flutter/material.dart';
import 'package:dementia_care/models/patient_mood.dart';

// Public helper so other widgets can reuse mood icons
IconData getMoodIconByName(String moodName) {
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

class MoodCard extends StatelessWidget {
  final PatientMood mood;

  const MoodCard({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final moodName = (mood.mood?.name ?? 'Unknown').toString();
    final userDescription = mood.description;
    final dateLabel = _formatDateTime(mood.loggedAt);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: SizedBox(
        width: 140, // keep same width as before
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF265F7E).withOpacity(0.12),
                child: Icon(
                  _getMoodIcon(moodName),
                  color: const Color(0xFF265F7E),
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                moodName,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (userDescription != null && userDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  userDescription,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // keep private method but delegate to public helper
  IconData _getMoodIcon(String moodName) => getMoodIconByName(moodName);

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayPart;
    if (d == today) {
      dayPart = 'Today';
    } else if (d == yesterday) {
      dayPart = 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      dayPart = '${months[d.month - 1]} ${d.day}';
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timePart = '$displayHour:$minute $period';

    return '$dayPart • $timePart';
  }
}

class MoodCardList extends StatelessWidget {
  final List<PatientMood> moods;

  const MoodCardList({super.key, required this.moods});

  @override
  Widget build(BuildContext context) {
    if (moods.isEmpty) {
      return SizedBox(
        height: 150.0,
        child: Center(
          child: Text(
            'No recent moods',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180.0, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final patientMood = moods[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: MoodCard(mood: patientMood),
          );
        },
      ),
    );
  }
}
