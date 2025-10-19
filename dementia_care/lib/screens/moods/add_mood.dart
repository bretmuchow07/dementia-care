import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/mood.dart';
import 'package:dementia_care/models/patient_mood.dart';
import 'package:dementia_care/services/tts_service.dart';
import 'package:dementia_care/widgets/success_dialog.dart';
import 'package:uuid/uuid.dart';

class AddMoodScreen extends StatefulWidget {
  final String patientId;
  final Function(PatientMood) onMoodSaved;

  const AddMoodScreen({
    Key? key,
    required this.patientId,
    required this.onMoodSaved,
  }) : super(key: key);

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  late final TextToSpeechService ttsService = TextToSpeechService();

  Mood? selectedMood;
  Set<String> selectedFactors = {};
  final TextEditingController otherFactorsController = TextEditingController();

  List<Mood> allMoods = [];
  bool showAllMoods = false;

  final Map<String, IconData> factors = {
    'Activity': Icons.fitness_center,
    'Sleep': Icons.bedtime,
    'Medication': Icons.medication,
    'Social Interaction': Icons.people,
    'Environment': Icons.eco,
  };

  final Map<String, String> moodAffirmations = {
    'Happy': "You're feeling happy today, that's wonderful!",
    'Sad': "It's okay to feel sad, take a deep breath",
    'Anxious': "It's okay to feel anxious, take a deep breath",
    'Calm': "You're feeling calm and centered, that's beautiful",
    'Excited': "Your excitement is wonderful to see!",
    'Angry': "It's normal to feel angry, you're processing your emotions",
    'Tired': "You're feeling tired, rest is important",
    'Content': "Feeling content is a wonderful state",
    'Frustrated': "Frustration is temporary, you're capable",
    'Peaceful': "Peaceful moments are precious",
  };

  final Map<String, String> moodEmojis = {
    // Map of mood name to a representative emoji string.
    // Keys should match the mood.name values used by the app (case-sensitive).
    'Happy': '😊',
    'Joyful': '😁',
    'Excited': '🤩',
    'Calm': '🌿',
    'Peaceful': '🕊️',
    'Relaxed': '😌',
    'Neutral': '😐',
    'Okay': '🙂',
    'Sad': '😔',
    'Down': '😞',
    'Upset': '😢',
    'Angry': '😠',
    'Frustrated': '😣',
    'Annoyed': '😒',
    'Confused': '🤔',
    'Lost': '😕',
    'Anxious': '😟',
    'Worried': '😰',
    'Tired': '😴',
    'Exhausted': '🥱',
    'Energetic': '⚡',
    'Active': '🏃‍♂️',
    'Content': '😊',
    // fallback handled by _getMoodEmoji
  };

  String _getMoodEmoji(String moodName) {
    return moodEmojis[moodName] ?? '😐';
  }

  @override
  void initState() {
    super.initState();
    _fetchMoods();
    ttsService.onStateChanged = () => setState(() {});
  }

  Future<void> _fetchMoods() async {
    final response = await Supabase.instance.client
        .from('mood')
        .select()
        .order('name', ascending: true);

    setState(() {
      allMoods = (response as List<dynamic>)
          .map((json) => Mood.fromJson(json))
          .toList();
    });
  }

  List<Mood> get _visibleMoods =>
      showAllMoods ? allMoods : allMoods.take(6).toList();

  Future<void> _saveMood() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final descriptionBuffer = StringBuffer();
      if (selectedFactors.isNotEmpty) {
        descriptionBuffer.write('Factors: ${selectedFactors.join(', ')}.');
      }
      if (otherFactorsController.text.isNotEmpty) {
        if (descriptionBuffer.isNotEmpty) descriptionBuffer.write(' ');
        descriptionBuffer.write('Other: ${otherFactorsController.text}.');
      }

      final now = DateTime.now();
      final uuid = Uuid();
      final patientMood = PatientMood(
        id: uuid.v4(), // Generate a proper UUID
        loggedAt: now,
        moodId: selectedMood!.id,
        userId: widget.patientId,
        description: descriptionBuffer.isEmpty ? null : descriptionBuffer.toString(),
      );

      await Supabase.instance.client
          .from('patient_mood')
          .insert({
            'id': patientMood.id,
            'logged_at': patientMood.loggedAt.toIso8601String(),
            'mood_id': patientMood.moodId,
            'user_id': patientMood.userId,
            'description': patientMood.description,
          });

      Navigator.pop(context); // Close loading

      widget.onMoodSaved(patientMood);

      // Show success dialog with animation and TTS
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SuccessDialog(
            moodName: selectedMood!.name,
            emoji: _getMoodEmoji(selectedMood!.name),
            onDismiss: () {
              Navigator.pop(context); // Go back after dialog dismisses
            },
          ),
        );
      }

    } catch (error) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mood: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    otherFactorsController.dispose();
    ttsService.onStateChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Mood',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(ttsService.ttsState == TtsState.playing ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              if (ttsService.ttsState == TtsState.playing) {
                ttsService.stop();
              } else {
                ttsService.speak("How are you feeling today? What might be influencing your mood?");
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._visibleMoods.map((mood) => _buildMoodChip(mood)),
                  if (!showAllMoods && allMoods.length > 6)
                    GestureDetector(
                      onTap: () => setState(() => showAllMoods = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: const Text(
                          'View More',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'What might be influencing your mood?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: factors.entries
                    .map((entry) => _buildFactorChip(entry.key, entry.value))
                    .toList(),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: otherFactorsController,
                  decoration: const InputDecoration(
                    hintText: 'Other factors',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: 3,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5A96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Mood',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(Mood mood) {
    final isSelected = selectedMood?.id == mood.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = mood;
        });
        // Play TTS when mood is selected
        final affirmation = moodAffirmations[mood.name] ?? "You're feeling ${mood.name.toLowerCase()}";
        ttsService.speak(affirmation);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E5A96) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E5A96) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E5A96).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up,
              size: 16,
              color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorChip(String factor, IconData icon) {
    final isSelected = selectedFactors.contains(factor);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedFactors.remove(factor);
          } else {
            selectedFactors.add(factor);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E5A96) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E5A96) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              factor,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
