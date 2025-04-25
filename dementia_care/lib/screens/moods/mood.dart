import 'package:dementia_care/screens/moods/moodcard.dart';
import 'package:flutter/material.dart';

class MoodPage extends StatelessWidget {
  const MoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.85; // Consistent width

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center items
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Today’s Mood',
                  style: TextStyle(
                    color: Color(0xFF265F7E),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),

            // MoodCard (Centered)
            Center(
              child: Container(
                height: 160.0, // Reduced height for better fit
                width: cardWidth, // Ensuring width consistency
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const MoodCard(emoji: '😊', moodTitle:'Happy'),
              ),
            ),

            const SizedBox(height: 20), // Reduced spacing

            // Buttons Aligned with MoodCard
            Center(
              child: Column(
                children: [
                  // "How are you feeling today?" Button
                  SizedBox(
                    width: cardWidth, // Matching MoodCard width
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement mood selection
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF265F7E),
                        padding: const EdgeInsets.symmetric(vertical: 12), // Adjusted padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'How are you feeling today?',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10), // Adjusted spacing

                  // "View Mood History" Button
                  SizedBox(
                    width: cardWidth, // Matching MoodCard width
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement mood history navigation
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2E8EA),
                        padding: const EdgeInsets.symmetric(vertical: 12), // Adjusted padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'View Mood History',
                        style: TextStyle(fontSize: 16, color: Color(0xFF265F7E),fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // Reduced spacing
 // Title
            const Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mood Board',
                  style: TextStyle(
                    color: Color(0xFF265F7E),
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            // Placeholder Content
            const Expanded(
              child: Center(
                child: Text('This is the Mood Page'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
