class Mood {
  final String id;
  final DateTime createdAt;
  final String name;
  final String description;

  Mood({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.description,
  });

  factory Mood.fromJson(Map<String, dynamic> json) => Mood(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        name: json['name'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'name': name,
        'description': description,
      };
}
