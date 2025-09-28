class Gallery {
  final String id;
  final DateTime createdAt;
  final String? imageUrl;
  final String description;
  final String userId;

  Gallery({
    required this.id,
    required this.createdAt,
    this.imageUrl,
    required this.description,
    required this.userId,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) => Gallery(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at']),
        imageUrl: json['image_url'],
        description: json['description'],
        userId: json['user_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'image_url': imageUrl,
        'description': description,
        'user_id': userId,
      };
}
