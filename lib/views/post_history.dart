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
  late Future<List<Post>> _postsFuture; // Future to load posts
  final StudentService _studentService =
      StudentService(); // Instance of StudentService

  @override
  void initState() {
    super.initState();
    _postsFuture =
        PostService().getRelevantPosts(); // Fetch posts for the current user
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          // Display posts in a scrollable PageView
          return PageView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final post = snapshot.data![index];

              return FutureBuilder<Map<String, String>>(
                future: _studentService.getNameAndEmailById(post.userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    return Center(child: Text('Error fetching user details.'));
                  }

                  String fullName =
                      userSnapshot.data?['fullName'] ?? "Unknown User";
                  String email = userSnapshot.data?['email'] ?? "";

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User's full name and creation date
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
                              color: Colors.black, // Set text color to black
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                            color: Colors.black87, // Set text color to black
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Post image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250, // Adjust the height of the image
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Post description
                        Text(
                          post.description,
                          style: const TextStyle(
                            color: Colors.black, // Set text color to black
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
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.blueAccent,
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
