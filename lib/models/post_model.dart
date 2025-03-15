import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final List<String> classes;  // Changed from classId to classes array
  final String className;
  final String authorId;
  final String authorName;
  final String authorProfilePhoto;
  final String content;
  final String imageUrl;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.classes,  // Changed from classId to classes array
    required this.className,
    required this.authorId,
    required this.authorName,
    this.authorProfilePhoto = '',
    required this.content,
    this.imageUrl = '',
    required this.timestamp,
  });

  // Convert Firestore document to Post object
  factory Post.fromMap(Map<String, dynamic> map) {
    // Handle Firestore timestamp conversion
    DateTime parseTimestamp() {
      final timestamp = map['timestamp'];
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now(); // Fallback
    }

    // Handle classes array
    List<String> parseClasses() {
      final classes = map['classes'];
      if (classes is List) {
        return List<String>.from(classes.map((item) => item.toString()));
      }
      return [];
    }

    return Post(
      id: map['id'] ?? '',
      classes: parseClasses(),  // Parse the classes array
      className: map['className'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      authorProfilePhoto: map['authorProfilePhoto'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timestamp: parseTimestamp(),
    );
  }

  // Convert Post object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'classes': classes,  // Store the classes array
      'className': className,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfilePhoto': authorProfilePhoto,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }

  // Create a copy of the Post with some fields changed
  Post copyWith({
    String? id,
    List<String>? classes,  // Changed from classId to classes
    String? className,
    String? authorId,
    String? authorName,
    String? authorProfilePhoto,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return Post(
      id: id ?? this.id,
      classes: classes ?? this.classes,
      className: className ?? this.className,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfilePhoto: authorProfilePhoto ?? this.authorProfilePhoto,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}