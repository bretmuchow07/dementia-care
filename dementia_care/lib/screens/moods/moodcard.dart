import 'package:flutter/material.dart';

class MoodCard extends StatelessWidget {
  final String emoji;
  final String moodTitle;

  const MoodCard({super.key, required this.emoji, required this.moodTitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: SizedBox(
        width: 120, // Fixed width for consistency
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40), // Large emoji
            ),
            const SizedBox(height: 8),
            Text(
              moodTitle,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MoodCardList extends StatelessWidget {
  final List<Map<String, String>> moodCards = [
    {'emoji': '😊', 'moodTitle': 'Happy'},
    {'emoji': '😢', 'moodTitle': 'Sad'},
    {'emoji': '😡', 'moodTitle': 'Angry'},
    {'emoji': '😴', 'moodTitle': 'Tired'},
    {'emoji': '😨', 'moodTitle': 'Anxious'},
    {'emoji': '🥰', 'moodTitle': 'Loved'},
  ];

  MoodCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150.0, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moodCards.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: MoodCard(
              emoji: moodCards[index]['emoji']!,
              moodTitle: moodCards[index]['moodTitle']!,
            ),
          );
        },
      ),
    );
  }
}
