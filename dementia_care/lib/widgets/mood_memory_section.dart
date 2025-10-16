import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/memory.dart';
import 'package:dementia_care/widgets/memorycard.dart';

class MoodMemorySection extends StatefulWidget {
  final String? filterMood;

  const MoodMemorySection({super.key, this.filterMood});

  @override
  State<MoodMemorySection> createState() => _MoodMemorySectionState();
}

class _MoodMemorySectionState extends State<MoodMemorySection> {
  List<MemoryGroup> _memories = [];
  bool _isLoading = true;
  String? _error;

  final Map<String, Color> _moodColors = {
    'Happy': const Color(0xFFFFD700),
    'Sad': const Color(0xFF4169E1),
    'Anxious': const Color(0xFFFF6347),
    'Calm': const Color(0xFF32CD32),
    'Excited': const Color(0xFFFF69B4),
    'Angry': const Color(0xFFDC143C),
    'Tired': const Color(0xFF808080),
    'Content': const Color(0xFF00CED1),
    'Frustrated': const Color(0xFFFF4500),
    'Peaceful': const Color(0xFF98FB98),
  };

  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Anxious': '😰',
    'Calm': '😌',
    'Excited': '🤩',
    'Angry': '😠',
    'Tired': '😴',
    'Content': '🙂',
    'Frustrated': '😤',
    'Peaceful': '🕊️',
  };

  @override
  void initState() {
    super.initState();
    _fetchMemories();
  }

  @override
  void didUpdateWidget(covariant MoodMemorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterMood != widget.filterMood) {
      _fetchMemories();
    }
  }

  Future<void> _fetchMemories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Fetch gallery items from database
      final response = await Supabase.instance.client
          .from('gallery')
          .select('id, description, image_url, created_at, user_id')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final allMemories = (response as List<dynamic>).map((json) {
        final imageUrl = json['image_url'] as String?;

        return MemoryGroup(
          title: json['description'] as String? ?? 'Untitled',
          imageUrls: imageUrl != null ? [imageUrl] : [],
          date: DateTime.parse(json['created_at'] as String),
        );
      }).toList();

      // Group memories by mood
      final moodGroups = <String, List<MemoryGroup>>{};

      for (final memory in allMemories) {
        final mood = _parseMoodFromDescription(memory.title, '');
        if (widget.filterMood == null || mood == widget.filterMood) {
          moodGroups.putIfAbsent(mood, () => []).add(memory);
        }
      }

      // Convert to list of sections
      final sections = <Map<String, dynamic>>[];
      moodGroups.forEach((mood, memories) {
        sections.add({
          'mood': mood,
          'memories': memories,
          'color': _moodColors[mood] ?? Colors.grey,
          'emoji': _moodEmojis[mood] ?? '😐',
        });
      });

      // Sort by number of memories (most to least)
      sections.sort((a, b) => (b['memories'] as List).length.compareTo((a['memories'] as List).length));

      setState(() {
        _memories = sections.expand((section) => section['memories'] as List<MemoryGroup>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch memories: $e';
        _isLoading = false;
      });
    }
  }

  String _parseMoodFromDescription(String title, String description) {
    final text = '$title'.toLowerCase();

    // Keywords for each mood
    final moodKeywords = {
      'Happy': ['happy', 'joy', 'excited', 'delighted', 'cheerful', 'glad', 'pleased', 'thrilled', 'ecstatic', 'overjoyed'],
      'Sad': ['sad', 'unhappy', 'depressed', 'down', 'blue', 'melancholy', 'sorrow', 'grief', 'heartbroken', 'disappointed'],
      'Anxious': ['anxious', 'worried', 'nervous', 'stressed', 'tense', 'uneasy', 'apprehensive', 'fearful', 'panicked', 'overwhelmed'],
      'Calm': ['calm', 'peaceful', 'relaxed', 'serene', 'tranquil', 'composed', 'placid', 'soothed', 'content', 'at ease'],
      'Excited': ['excited', 'thrilled', 'enthusiastic', 'eager', 'pumped', 'amped', 'hyped', 'jazzed', 'fired up', 'stoked'],
      'Angry': ['angry', 'mad', 'furious', 'irritated', 'annoyed', 'frustrated', 'rage', 'outraged', 'livid', 'enraged'],
      'Tired': ['tired', 'exhausted', 'fatigued', 'weary', 'drained', 'sleepy', 'worn out', 'beat', 'pooped', 'knackered'],
      'Content': ['content', 'satisfied', 'fulfilled', 'pleased', 'gratified', 'happy', 'comfortable', 'at peace'],
      'Frustrated': ['frustrated', 'annoyed', 'irritated', 'vexed', 'exasperated', 'aggravated', 'displeased', 'irked'],
      'Peaceful': ['peaceful', 'serene', 'calm', 'tranquil', 'placid', 'quiet', 'restful', 'harmonious'],
    };

    // Count matches for each mood
    final moodScores = <String, int>{};
    moodKeywords.forEach((mood, keywords) {
      int score = 0;
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          score++;
        }
      }
      if (score > 0) {
        moodScores[mood] = score;
      }
    });

    // Return mood with highest score, or 'Neutral' if none found
    if (moodScores.isEmpty) {
      return 'Neutral';
    }

    return moodScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMemories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Group memories by mood for display
    final moodGroups = <String, List<MemoryGroup>>{};
    for (final memory in _memories) {
      final mood = _parseMoodFromDescription(memory.title, '');
      moodGroups.putIfAbsent(mood, () => []).add(memory);
    }

    if (moodGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.filterMood != null
                  ? 'No memories found for ${widget.filterMood}'
                  : 'No memories found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: moodGroups.length,
      itemBuilder: (context, index) {
        final mood = moodGroups.keys.elementAt(index);
        final memories = moodGroups[mood]!;
        final color = _moodColors[mood] ?? Colors.grey;
        final emoji = _moodEmojis[mood] ?? '😐';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$mood (${memories.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Memory cards
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: memories.length,
                itemBuilder: (context, memoryIndex) {
                  final memory = memories[memoryIndex];
                  final firstUrl = memory.imageUrls.isNotEmpty ? memory.imageUrls[0] : '';

                  return Container(
                    width: 250,
                    margin: EdgeInsets.only(
                      right: memoryIndex == memories.length - 1 ? 0 : 12,
                    ),
                    child: MemoryCard(
                      imageUrl: firstUrl,
                      title: memory.title,
                      onTap: () {
                        // Open full memory view
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: Text(memory.title)),
                              body: Center(
                                child: firstUrl.isNotEmpty
                                    ? Image.network(firstUrl, fit: BoxFit.contain)
                                    : const Text('No image available'),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}