import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/student_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final String email;

  FriendProfileScreen({required this.email});

  @override
  _FriendProfileScreenState createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final StudentService _studentService = StudentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = "";
  String _bio = "";
  String? _profileImageUrl;
  int _friendsCount = 0;
  int _postsCount = 0;
  List<String> _interests = [];
  bool _isLoading = true;

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
          _interests = [];
        });
        _loadFriendsCount(student.id);
        _loadPostsCount(student.id);
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
    final connections =
        await _firestore
            .collection('connections')
            .where('student1_id', isEqualTo: userId)
            .get();
    setState(() {
      _friendsCount = connections.docs.length;
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
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
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
                      if (_interests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _interests
                                        .map(
                                          (interest) =>
                                              _buildInterestChip(interest),
                                        )
                                        .toList(),
                              ),
                            ],
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

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        interest,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
