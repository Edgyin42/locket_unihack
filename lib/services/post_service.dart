import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all posts
  Future<List<Post>> getPosts() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('posts')
              .orderBy('createdAt', descending: true) // Sort by newest first
              .get();

      return querySnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  // Fetch posts by user ID
  Future<List<Post>> getPostsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('posts')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching user posts: $e");
      return [];
    }
  }

  // Add a new post
  Future<void> addPost(Post post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
    } catch (e) {
      print("Error adding post: $e");
    }
  }
  // Add this method to your PostService class

  // Fetch posts by hashtag
  Future<List<Post>> getPostsByHashtag(String hashtag) async {
    try {
      // Make sure hashtag includes the # symbol if needed
      String searchTag = hashtag.startsWith('#') ? hashtag : '#$hashtag';

      QuerySnapshot querySnapshot =
          await _firestore
              .collection('posts')
              .where('hashtags', arrayContains: searchTag)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching posts by hashtag: $e");
      return [];
    }
  }

  // Fetch relevant posts for the current user
  Future<List<Post>> getRelevantPosts() async {
    try {
      String currentUserId = _auth.currentUser?.uid ?? "";

      if (currentUserId.isEmpty) {
        return [];
      }

      // Fetch class IDs where the current user is enrolled
      QuerySnapshot classSnapshot =
          await _firestore
              .collection('class_students')
              .where('student_id', isEqualTo: currentUserId)
              .get();

      List<String> classIds =
          classSnapshot.docs.map((doc) => doc['class_id'] as String).toList();

      // Fetch student IDs in the same classes
      QuerySnapshot studentsSnapshot =
          await _firestore
              .collection('class_students')
              .where('class_id', whereIn: classIds.isNotEmpty ? classIds : [''])
              .get();

      List<String> classmateIds =
          studentsSnapshot.docs
              .map((doc) => doc['student_id'] as String)
              .toList();

      // Fetch connected students
      QuerySnapshot connectionsSnapshot =
          await _firestore
              .collection('connections')
              .where('student1_id', isEqualTo: currentUserId)
              .get();

      List<String> connectedStudentIds =
          connectionsSnapshot.docs
              .map((doc) => doc['student2_id'] as String)
              .toList();

      QuerySnapshot reverseConnectionsSnapshot =
          await _firestore
              .collection('connections')
              .where('student2_id', isEqualTo: currentUserId)
              .get();

      connectedStudentIds.addAll(
        reverseConnectionsSnapshot.docs.map(
          (doc) => doc['student1_id'] as String,
        ),
      );

      // Combine unique student IDs (classmates + connections)
      Set<String> relevantStudentIds = {
        ...classmateIds,
        ...connectedStudentIds,
      };

      if (relevantStudentIds.isEmpty) {
        return [];
      }

      // Fetch posts from relevant students
      QuerySnapshot postsSnapshot =
          await _firestore
              .collection('posts')
              .where('userId', whereIn: relevantStudentIds.toList())
              .orderBy('createdAt', descending: true)
              .get();

      return postsSnapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching relevant posts: $e');
      return [];
    }
  }
}
