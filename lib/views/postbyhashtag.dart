import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/models/student_model.dart'; // Assuming Student model is in this file
import 'package:demo/services/post_service.dart';

class HashtagPage extends StatefulWidget {
  final String hashtag;

  const HashtagPage({Key? key, required this.hashtag}) : super(key: key);

  @override
  State<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> postsWithUserData = [];
  final PostService _postService = PostService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch posts with the given hashtag
      List<Post> hashtagPosts = await _postService.getPostsByHashtag(
        widget.hashtag,
      );
      print('POST GET DUOC $hashtagPosts');

      // Get user data for each post
      List<Map<String, dynamic>> enrichedPosts = [];

      for (Post post in hashtagPosts) {
        // Fetch user data for this post
        DocumentSnapshot userDoc =
            await _firestore.collection('students').doc(post.userId).get();
        Student? student;

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          userData['id'] = userDoc.id;
          student = Student(
            id: userDoc.id,
            fullName: userData['fullName'] ?? 'Unknown User',
            email: userData['email'] ?? '',
            bio: userData['bio'] ?? '',
            profilePhoto:
                userData['profilePhoto'] ?? 'https://via.placeholder.com/50',
          );
        }

        enrichedPosts.add({'post': post, 'user': student});
      }

      setState(() {
        postsWithUserData = enrichedPosts;
        isLoading = false;
      });
    } catch (e) {
      print("Error in fetchPosts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hashtag),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved ${widget.hashtag} to bookmarks')),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
              : Column(
                children: [
                  _buildHashtagHeader(),
                  Expanded(
                    child:
                        postsWithUserData.isEmpty
                            ? _buildEmptyState()
                            : _buildPostsList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No posts with ${widget.hashtag} yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post with this hashtag!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hashtag,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${postsWithUserData.length} posts',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(),
          // Row(
          //   children: [
          //     ElevatedButton(
          //       onPressed: () {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(content: Text('Following this hashtag')),
          //         );
          //       },
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.pinkAccent,
          //         foregroundColor: Colors.white,
          //         padding: const EdgeInsets.symmetric(horizontal: 24),
          //       ),
          //       child: const Text('Follow'),
          //     ),
          //     const SizedBox(width: 12),
          //     OutlinedButton(
          //       onPressed: () {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(content: Text('Share dialog would open')),
          //         );
          //       },
          //       style: OutlinedButton.styleFrom(
          //         foregroundColor: Colors.pinkAccent,
          //         side: const BorderSide(color: Colors.pinkAccent),
          //         padding: const EdgeInsets.symmetric(horizontal: 24),
          //       ),
          //       child: const Text('Share'),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: fetchPosts,
      color: Colors.pinkAccent,
      child: ListView.builder(
        itemCount: postsWithUserData.length,
        itemBuilder: (context, index) {
          final Post post = postsWithUserData[index]['post'];
          final Student? user = postsWithUserData[index]['user'];
          final bool hasImage =
              post.imageUrl != null && post.imageUrl.isNotEmpty;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to user profile
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfilePage(userId: post.userId)));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            user?.profilePhoto ??
                                'https://via.placeholder.com/50',
                          ),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatTimestamp(post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (post.description != null && post.description.isNotEmpty)
                    Text(
                      post.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (hasImage) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (post.hashtags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children:
                          post.hashtags.map((tag) {
                            return GestureDetector(
                              onTap: () {
                                if (tag != widget.hashtag) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              HashtagPage(hashtag: tag),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight:
                                      tag == widget.hashtag
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildInteractionButton(
                            icon: Icons.favorite_border,
                            count: 0, // Update this once you have likes data
                            onPressed: () {
                              // Implement like functionality
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildInteractionButton(
                            icon: Icons.chat_bubble_outline,
                            count: 0, // Update this once you have comments data
                            onPressed: () {
                              // Navigate to comments page
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.share, color: Colors.grey[600]),
                        onPressed: () {
                          // Implement share functionality
                        },
                      ),
                    ],
                  ),
                  if (post.classes.isNotEmpty) ...[
                    const Divider(),
                    Wrap(
                      spacing: 4,
                      children:
                          post.classes.map((className) {
                            return Chip(
                              label: Text(className),
                              backgroundColor: Colors.grey[200],
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[800],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
