import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final List<String> classes;
  final Timestamp createdAt;
  final String description;
  final List<String> hashtags;
  final String imageUrl;
  final String userId;

  Post({
    required this.id,
    required this.classes,
    required this.createdAt,
    required this.description,
    required this.hashtags,
    required this.imageUrl,
    required this.userId,
  });

  // Convert Firestore document to Post object
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      classes: List<String>.from(doc['classes'] ?? []),
      createdAt: doc['createdAt'] ?? Timestamp.now(),
      description: doc['description'] ?? '',
      hashtags: List<String>.from(doc['hashtags'] ?? []),
      imageUrl: doc['imageUrl'] ?? '',
      userId: doc['userId'] ?? '',
    );
  }

  // Convert Post object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'classes': classes,
      'createdAt': createdAt,
      'description': description,
      'hashtags': hashtags,
      'imageUrl': imageUrl,
      'userId': userId,
    };
  }
}
