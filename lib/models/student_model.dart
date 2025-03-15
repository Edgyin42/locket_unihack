class Student {
  final String id;
  final String fullName;
  final String email;
  final String bio;
  final String profilePhoto;

  Student({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio = '',
    this.profilePhoto = '',
  });

  // Convert Firestore data to a Student object
  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      id: id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      profilePhoto: data['profilePhoto'] ?? '',
    );
  }

  // Convert Student object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'profilePhoto': profilePhoto,
    };
  }
}
