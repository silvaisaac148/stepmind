class UserProfile {
  final String firstName;
  final String lastName;
  final String username;
  final int age;
  final String country;
  final String? profileImagePath;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.age,
    required this.country,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'age': age,
      'country': country,
      'profileImagePath': profileImagePath,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      age: json['age'] ?? 0,
      country: json['country'] ?? '',
      profileImagePath: json['profileImagePath'],
    );
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    int? age,
    String? country,
    String? profileImagePath,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      age: age ?? this.age,
      country: country ?? this.country,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  String get fullName => '$firstName $lastName';
}
