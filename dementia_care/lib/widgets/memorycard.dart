import 'package:flutter/material.dart';

class MemoryCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const MemoryCard({super.key, required this.imageUrl, required this.title});
@override
Widget build(BuildContext context) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
          child: SizedBox(
            width: 120,
            height: 100,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
}
class MemoryCardList extends StatelessWidget {
  final List<Map<String, String>> memoryCards = [
    {'imageUrl': 'https://example.com/image1.jpg', 'title': 'Best of January'},
    {'imageUrl': 'https://example.com/image2.jpg', 'title': 'Best of February'},
    // Add more cards here
  ];

  MemoryCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: memoryCards.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: MemoryCard(
              imageUrl: memoryCards[index]['imageUrl']!,
              title: memoryCards[index]['title']!,
            ),
          );
        },
      ),
    );
  }
}