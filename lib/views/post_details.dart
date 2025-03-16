import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:demo/services/student_service.dart';
import 'package:demo/views/viewfriendprofile.dart';
import 'package:flutter/material.dart';

class SinglePostViewScreen extends StatefulWidget {
  final String postId;

  const SinglePostViewScreen({Key? key, required this.postId})
    : super(key: key);

  @override
  _SinglePostViewScreenState createState() => _SinglePostViewScreenState();
}

class _SinglePostViewScreenState extends State<SinglePostViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentService _studentService = StudentService();
  bool _isLoading = true;
  Map<String, dynamic>? _postData;

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get post document
      final DocumentSnapshot postDoc =
          await _firestore.collection('posts').doc(widget.postId).get();

      if (postDoc.exists) {
        setState(() {
          _postData = postDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post not found'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading post: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
              : _buildPostContent(),
    );
  }

  Widget _buildPostContent() {
    if (_postData == null) {
      return const Center(
        child: Text(
          'Post data not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final String userId = _postData!['userId'] as String;
    final String imageUrl = _postData!['imageUrl'] as String;
    final String description = _postData!['description'] as String;
    final List<dynamic> hashtags =
        _postData!['hashtags'] as List<dynamic>? ?? [];
    final Timestamp createdAt = _postData!['createdAt'] as Timestamp;

    return FutureBuilder<Map<String, String>>(
      future: _studentService.getInfoPosterById(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }

        if (userSnapshot.hasError) {
          return Center(
            child: Text(
              'Error fetching user details',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        String fullName = userSnapshot.data?['fullName'] ?? "Unknown User";
        String email = userSnapshot.data?['email'] ?? "";
        String profilePhoto = userSnapshot.data?['profilePhoto'] ?? "";

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Row (Profile Picture + Name)
              Row(
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FriendProfileScreen(email: email),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          profilePhoto.isNotEmpty
                              ? NetworkImage(profilePhoto)
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // User Name
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FriendProfileScreen(email: email),
                        ),
                      );
                    },
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Post Image - Square
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.0, // Square aspect ratio
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Post Description
              Text(
                description,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Hashtags
              Wrap(
                spacing: 8,
                children:
                    hashtags.map((hashtag) {
                      return Chip(
                        label: Text(
                          "#$hashtag",
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.pinkAccent,
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
