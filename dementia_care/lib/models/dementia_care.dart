import 'dart:convert';
import 'gallery.dart';
import 'mood.dart';
import 'profile.dart';

DementiaCare dementiaCareFromJson(String str) => DementiaCare.fromJson(json.decode(str));
String dementiaCareToJson(DementiaCare data) => json.encode(data.toJson());

class DementiaCare {
  final String schema;
  final String title;
  final String type;
  final DementiaCareProperties properties;

  DementiaCare({
    required this.schema,
    required this.title,
    required this.type,
    required this.properties,
  });

  DementiaCare copyWith({
    String? schema,
    String? title,
    String? type,
    DementiaCareProperties? properties,
  }) =>
      DementiaCare(
        schema: schema ?? this.schema,
        title: title ?? this.title,
        type: type ?? this.type,
        properties: properties ?? this.properties,
      );

  factory DementiaCare.fromJson(Map<String, dynamic> json) => DementiaCare(
        schema: json["\u0024schema"],
        title: json["title"],
        type: json["type"],
        properties: DementiaCareProperties.fromJson(json["properties"]),
      );

  Map<String, dynamic> toJson() => {
        "\u0024schema": schema,
        "title": title,
        "type": type,
        "properties": properties.toJson(),
      };
}

class DementiaCareProperties {
  final Gallery gallery;
  final Mood mood;
  final Gallery patientMood;
  final Profile profile;

  DementiaCareProperties({
    required this.gallery,
    required this.mood,
    required this.patientMood,
    required this.profile,
  });

  DementiaCareProperties copyWith({
    Gallery? gallery,
    Mood? mood,
    Gallery? patientMood,
    Profile? profile,
  }) =>
      DementiaCareProperties(
        gallery: gallery ?? this.gallery,
        mood: mood ?? this.mood,
        patientMood: patientMood ?? this.patientMood,
        profile: profile ?? this.profile,
      );

  factory DementiaCareProperties.fromJson(Map<String, dynamic> json) => DementiaCareProperties(
        gallery: Gallery.fromJson(json["gallery"]),
        mood: Mood.fromJson(json["mood"]),
        patientMood: Gallery.fromJson(json["patient_mood"]),
        profile: Profile.fromJson(json["profile"]),
      );

  Map<String, dynamic> toJson() => {
        "gallery": gallery.toJson(),
        "mood": mood.toJson(),
        "patient_mood": patientMood.toJson(),
        "profile": profile.toJson(),
      };
}