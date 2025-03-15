import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw ArgumentError("Document data cannot be null");
    }

    return Student(
      id: doc.id, // ✅ Correctly accessing Firestore document ID
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      profilePhoto: data['profilePhoto'] ?? '',
    );
  }

  //   factory Student.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>?; // Ensure proper type casting

  //   if (data == null) {
  //     throw ArgumentError("Document data cannot be null");
  //   }

  //   return Student(
  //     id: doc.id, // Get document ID separately
  //     fullName: data['fullName'] ?? '',
  //     email: data['email'] ?? '',
  //     bio: data['bio'] ?? '',
  //     profilePhoto: data['profilePhoto'] ?? '',

  //   );
  // }

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