import 'package:dementia_care/models/mood.dart';

class PatientMood {
  final String id;
  final String? moodId;
  final DateTime loggedAt;
  final String? userId;
  final String? description;
  final Mood? mood; // Add the related mood object

  PatientMood({
    required this.id,
    required this.moodId,
    required this.loggedAt,
    this.userId,
    this.description,
    this.mood, // Include mood in constructor
  });

  factory PatientMood.fromJson(Map<String, dynamic> json) {
    return PatientMood(
      id: json['id'] as String,
      moodId: json['mood_id'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      userId: json['user_id'] as String?,
      description: json['description'] as String?,
      // Handle nested mood data if present
      mood: json['mood'] != null
          ? Mood.fromJson(json['mood'] as Map<String, dynamic>)
          : null,
    );
  }

  // Factory constructor for data that includes joined mood information
  factory PatientMood.fromJsonWithMoodData(Map<String, dynamic> json) {
    return PatientMood(
      id: json['id'] as String,
      moodId: json['mood_id'] as String?,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      userId: json['user_id'] as String?,
      description: json['description'] as String?,
      // Create mood from flattened join data
      mood: json['mood_id'] != null && json['mood_name'] != null
          ? Mood(
              id: json['mood_id'] as String,
              createdAt: json['mood_created_at'] != null 
                  ? DateTime.parse(json['mood_created_at'] as String)
                  : DateTime.now(),
              name: json['mood_name'] as String,
              description: json['mood_description'] as String? ?? '',
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_id': moodId,
      'logged_at': loggedAt.toIso8601String(),
      'user_id': userId,
      'description': description,
      // Include mood data if available
      if (mood != null) 'mood': mood!.toJson(),
    };
  }

  // Helper method to copy with mood data
  PatientMood copyWithMood(Mood? mood) {
    return PatientMood(
      id: id,
      moodId: moodId,
      loggedAt: loggedAt,
      userId: userId,
      description: description,
      mood: mood,
    );
  }
}