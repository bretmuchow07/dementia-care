import 'package:flutter/material.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Input',
            onPressed: () {
              // Add voice input functionality here
            },
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
            ),
            IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Upload Media',
          onPressed: () {
            // Add upload media functionality here
          },
            ),
          ],
        ),
          ),
          const Expanded(
            child: Center(
              child: Text('This is the Gallery Page'),
            ),
          ),
        ],
      ),
    );
  }
}
