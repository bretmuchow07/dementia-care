class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final String? dateOfBirth;
  final String? country;

  Profile({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    this.dateOfBirth,
    this.country,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        fullName: json['full_name'] ?? '',
        email: json['email'] ?? '',
        profilePicture: json['profile_picture'],
        dateOfBirth: json['date_of_birth'],
        country: json['country'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'profile_picture': profilePicture,
        'date_of_birth': dateOfBirth,
        'country': country,
      };
}
