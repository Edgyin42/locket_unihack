import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Post>> getPostsForClasses(List<String> classIds) async {
    try {
      if (classIds.isEmpty) {
        print("PostService: No class IDs provided");
        return [];
      }
      
      print("PostService: Fetching posts for classes: $classIds");
      
      final List<Post> allPosts = [];
      
      // Since we're using array-contains-any, we need to process in chunks of 10
      for (int i = 0; i < classIds.length; i += 10) {
        final end = (i + 10 < classIds.length) ? i + 10 : classIds.length;
        final chunk = classIds.sublist(i, end);
        
        print("PostService: Processing chunk ${i ~/ 10 + 1}: $chunk");
        
        final querySnapshot = await _firestore
          .collection('posts')
          .where('classes', arrayContainsAny: chunk)  // Use arrayContainsAny for arrays
          .orderBy('createdAt', descending: true)
          .get();
        
        print("PostService: Chunk ${i ~/ 10 + 1} returned ${querySnapshot.docs.length} documents");
        
        final posts = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Post.fromMap({
            'id': doc.id,
            ...data,
          });
        }).toList();
        
        allPosts.addAll(posts);
      }
      
      // Remove duplicates that might come from different chunks
      final uniquePosts = <String, Post>{};
      for (var post in allPosts) {
        uniquePosts[post.id] = post;
      }
      
      // Sort all posts by timestamp
      final result = uniquePosts.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print("PostService: Total unique posts fetched: ${result.length}");
      return result;
      
    } catch (e) {
      print("PostService: Error in getPostsForClasses: $e");
      rethrow;
    }
  }

  Future<Post?> getPostById(String postId) async {
    try {
      final docSnapshot = await _firestore.collection('posts').doc(postId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return Post.fromMap({
        'id': docSnapshot.id,
        ...docSnapshot.data()!,
      });
    } catch (e) {
      print("PostService: Error getting post by ID: $e");
      rethrow;
    }
  }

  Future<void> createPost({
    required List<String> classes,  // Changed from classId to classes array
    required String className,
    required String content, 
    required String authorId, 
    required String authorName,
    String authorProfilePhoto = '',
    String imageUrl = '',
  }) async {
    try {
      await _firestore.collection('posts').add({
        'classes': classes,  // Now storing an array of class IDs
        'className': className,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'authorProfilePhoto': authorProfilePhoto,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("PostService: Error creating post: $e");
      rethrow;
    }
  }
}