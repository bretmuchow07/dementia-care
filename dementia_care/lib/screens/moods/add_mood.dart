import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/mood.dart';
import 'package:dementia_care/models/patient_mood.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchMoods();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back

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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E5A96) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E5A96) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          mood.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
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
