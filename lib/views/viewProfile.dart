import 'package:flutter/material.dart';
import 'package:demo/views/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/src/material/page.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({Key? key}) : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data variables
  String _username = "";
  String _bio = "";
  int _friendsCount = 0;
  int _postsCount = 0;
  List<String> _interests = [];
  bool _isLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        final QuerySnapshot postsSnapshot =
            await _firestore
                .collection('posts')
                .where('userId', isEqualTo: currentUser.uid)
                .get();

        print(
          'Found ${postsSnapshot.docs.length} posts for user ${currentUser.uid}',
        );

        if (postsSnapshot.docs.isNotEmpty) {
          print('Posts exist, but the ordered query requires an index');
        }
        // Get user document from Firestore
        final DocumentSnapshot userDoc =
            await _firestore.collection('students').doc(currentUser.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _username = userData['fullName'] ?? "User";
            _bio = userData['bio'] ?? "No bio yet";
            _profileImageUrl = userData['profileImageUrl'];

            // Get interests (if stored as an array in Firestore)
            if (userData['interests'] != null) {
              _interests = List<String>.from(userData['interests']);
            }

            // Load counts with additional queries if needed
            _loadFriendsCount(currentUser.uid);
            _loadPostsCount(currentUser.uid);
          });
        }
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

  // Load friends count
  Future<void> _loadFriendsCount(String userId) async {
    try {
      // This is a placeholder - implement according to your database structure
      final QuerySnapshot friendsSnapshot =
          await _firestore
              .collection('connections')
              .where('userId', isEqualTo: userId)
              .get();

      setState(() {
        _friendsCount = friendsSnapshot.docs.length;
      });
    } catch (e) {
      // Handle error silently - friends count will remain at default
    }
  }

  // Load posts count
  Future<void> _loadPostsCount(String userId) async {
    try {
      // This is a placeholder - implement according to your database structure
      final QuerySnapshot postsSnapshot =
          await _firestore
              .collection('posts')
              .where('userId', isEqualTo: userId)
              .get();

      setState(() {
        _postsCount = postsSnapshot.docs.length;
      });
    } catch (e) {
      // Handle error silently - posts count will remain at default
    }
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              ).then((_) {
                // Reload data when returning from edit screen
                _loadUserData();
              });
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: Colors.amber,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Profile picture
                        Center(
                          child: Stack(
                            children: [
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
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Username
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Bio
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

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStat('Friends', _friendsCount),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[800],
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                            _buildStat('Posts', _postsCount),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Interests section
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

                        const SizedBox(height: 25),

                        // Recent photos grid - to be implemented with Firestore data
                        FutureBuilder<QuerySnapshot>(
                          future:
                              _firestore
                                  .collection('posts')
                                  .where(
                                    'userId',
                                    isEqualTo: _auth.currentUser?.uid,
                                  )
                                  // .orderBy('createdAt', descending: true)  // Comment this out temporarily
                                  .limit(6)
                                  .get(),
                          builder: (context, snapshot) {
                            List<Widget> photoWidgets = [];

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              photoWidgets =
                                  snapshot.data!.docs.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final imageUrl =
                                        data['imageUrl'] as String?;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                        image:
                                            imageUrl != null &&
                                                    imageUrl.isNotEmpty
                                                ? DecorationImage(
                                                  image: NetworkImage(imageUrl),
                                                  fit: BoxFit.cover,
                                                  onError: (
                                                    exception,
                                                    stackTrace,
                                                  ) {
                                                    print(
                                                      'Failed to load image: $imageUrl',
                                                    );
                                                  },
                                                )
                                                : null,
                                      ),
                                      child:
                                          imageUrl == null || imageUrl.isEmpty
                                              ? Icon(
                                                Icons.image,
                                                color: Colors.grey[400],
                                                size: 30,
                                              )
                                              : null,
                                    );
                                  }).toList();
                            } else {
                              // Show placeholders if no photos
                              photoWidgets = List.generate(
                                6,
                                (index) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                      size: 30,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Photos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    children: photoWidgets,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
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
