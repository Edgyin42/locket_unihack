import 'package:demo/models/post_model.dart';
import 'package:demo/services/request_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/student_service.dart';
import 'package:demo/services/connection_service.dart';
import 'package:demo/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendProfileScreen extends StatefulWidget {
  final String email;

  FriendProfileScreen({required this.email});

  @override
  _FriendProfileScreenState createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final StudentService _studentService = StudentService();
  final ConnectionService _connectionService = ConnectionService();
  final FriendRequestService _requestService = FriendRequestService();
  final PostService _postService = PostService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _username = "";
  String _bio = "";
  String? _profileImageUrl;
  int _friendsCount = 0;
  int _postsCount = 0;
  bool _isLoading = true;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  String? _friendId;
  List<Post> _posts = [];
  bool _loadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final student = await _studentService.getStudentByEmail(widget.email);
      if (student != null) {
        setState(() {
          _username = student.fullName ?? "User";
          _bio = student.bio ?? "No bio yet";
          _profileImageUrl = student.profilePhoto;
          _friendId = student.id;
        });
        _loadFriendsCount(student.id);
        _loadPostsCount(student.id);
        _checkFriendship();
        _loadPosts(student.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendsCount(String userId) async {
    final connections_ = await _connectionService.getUserFriends(userId);
    setState(() {
      _friendsCount = connections_.length;
    });
  }

  Future<void> _loadPostsCount(String userId) async {
    final posts =
        await _firestore
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .get();
    setState(() {
      _postsCount = posts.docs.length;
    });
  }

  Future<void> _loadPosts(String userId) async {
    setState(() {
      _loadingPosts = true;
    });

    try {
      final posts = await _postService.getPostsByUser(userId);
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      print("Error loading posts: ${e.toString()}");
    } finally {
      setState(() {
        _loadingPosts = false;
      });
    }
  }

  Future<void> _checkFriendship() async {
    String currentUserId = _auth.currentUser?.uid ?? "";
    if (_friendId == null || currentUserId.isEmpty) return;

    bool areFriends = await _connectionService.areFriends(
      currentUserId,
      _friendId!,
    );
    bool hasPendingReq = await _requestService.hasPendingFriendRequest(
      currentUserId,
      _friendId!,
    );
    setState(() {
      _isFriend = areFriends;
      _hasPendingRequest = hasPendingReq;
    });
  }

  Future<void> _toggleFriendship() async {
    String currentUserId = _auth.currentUser?.uid ?? "";
    if (_friendId == null || currentUserId.isEmpty) return;

    if (_isFriend) {
      await _connectionService.removeFriend(currentUserId, _friendId!);
    } else {
      await _requestService.sendFriendRequest(currentUserId, _friendId!);
    }

    setState(() {
      _isFriend = !_isFriend;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Edit profile functionality can be added here
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF0099)),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage:
                            _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                        child:
                            _profileImageUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat('Friends', _friendsCount),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[800],
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          _buildStat('Posts', _postsCount),
                        ],
                      ),
                      const SizedBox(height: 25),
                      if (_friendId != _auth.currentUser?.uid &&
                          _hasPendingRequest == false)
                        ElevatedButton(
                          onPressed: _toggleFriendship,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF0099),
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            _isFriend ? "Unfriend" : "Add Friend",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (_hasPendingRequest)
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 30,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Request Sent",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Recent Photos",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _loadingPosts
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF0099),
                            ),
                          )
                          : _posts.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "No posts yet",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          )
                          : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SinglePostViewScreen(
                                              postId: post.id,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        post.imageUrl.isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                post.imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      color: Color(0xFFFF0099),
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.image,
                                                      color: Colors.grey[400],
                                                      size: 40,
                                                    ),
                                              ),
                                            )
                                            : Icon(
                                              Icons.image,
                                              color: Colors.grey[400],
                                              size: 40,
                                            ),
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      ],
    );
  }
}

// This is a placeholder for the SinglePostViewScreen class
// You'll need to create this screen separately
class SinglePostViewScreen extends StatefulWidget {
  final String postId;

  SinglePostViewScreen({required this.postId});

  @override
  _SinglePostViewScreenState createState() => _SinglePostViewScreenState();
}

class _SinglePostViewScreenState extends State<SinglePostViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Post', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Text(
          'Viewing post ${widget.postId}',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
