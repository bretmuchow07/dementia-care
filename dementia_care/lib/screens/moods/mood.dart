import 'package:flutter/material.dart';

class MoodPage extends StatelessWidget {
  const MoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Page'),
      ),
      body: const Center(
        child: Text('This is the Mood Page'),
      ),
    );
  }
}
