import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/services/post_service.dart';
import 'package:demo/services/student_service.dart';
import 'package:demo/views/viewfriendprofile.dart';
import 'package:flutter/material.dart';

class PostsHistoryScreen extends StatefulWidget {
  const PostsHistoryScreen({Key? key}) : super(key: key);

  @override
  _PostsHistoryScreenState createState() => _PostsHistoryScreenState();
}

class _PostsHistoryScreenState extends State<PostsHistoryScreen> {
  late Future<List<Post>> _postsFuture;
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    _postsFuture = PostService().getRelevantPosts();
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white), // White text
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No posts available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return PageView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final post = snapshot.data![index];

              return FutureBuilder<Map<String, String>>(
                future: _studentService.getInfoPosterById(
                  post.userId,
                ), // Fetch profile photo too
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error fetching user details.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  String fullName =
                      userSnapshot.data?['fullName'] ?? "Unknown User";
                  String email = userSnapshot.data?['email'] ?? "";
                  String profilePhoto =
                      userSnapshot.data?['profilePhoto'] ??
                      ""; // Profile photo URL

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
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
                                        (context) =>
                                            FriendProfileScreen(email: email),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    profilePhoto.isNotEmpty
                                        ? NetworkImage(profilePhoto)
                                        : const AssetImage(
                                              'assets/default_profile.png',
                                            )
                                            as ImageProvider,
                                backgroundColor: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ), // Space between image and text
                            // User Name
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            FriendProfileScreen(email: email),
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
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Post Image - Modified to be square
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1.0, // Force 1:1 aspect ratio (square)
                            child: Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Post Description
                        Text(
                          post.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Hashtags
                        Wrap(
                          spacing: 8,
                          children:
                              post.hashtags.map((hashtag) {
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
            },
          );
        },
      ),
    );
  }
}
