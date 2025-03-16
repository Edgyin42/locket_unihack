import 'package:demo/models/post_model.dart';
import 'package:demo/models/request_model.dart';
import 'package:demo/services/connection_service.dart';
import 'package:demo/services/post_service.dart';
import 'package:demo/services/request_service.dart';
import 'package:demo/services/student_service.dart';
import 'package:demo/views/friend_req_list.dart';
import 'package:demo/views/friends_list.dart';
import 'package:demo/views/viewProfile.dart';
import 'package:demo/views/viewfriendprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PostStatusPage.dart';

class CameraApp extends StatelessWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;

  const CameraApp({Key? key, required this.camera, required this.cameras})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera App',
      theme: ThemeData.dark(),
      home: CameraHomePage(camera: camera, cameras: cameras),
    );
  }
}

class CameraHomePage extends StatefulWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;

  const CameraHomePage({Key? key, required this.camera, required this.cameras})
      : super(key: key);

  @override
  State<CameraHomePage> createState() => _CameraHomePageState();
}

class _CameraHomePageState extends State<CameraHomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  int _currentCameraIndex = 0;
  List<XFile> _capturedImages = [];
  int numFriends = 0;
  List<String> _friendIds = [];
  final ConnectionService _connectionService = ConnectionService();
  final FriendRequestService _friendRequestService = FriendRequestService();
  final PostService _postService = PostService();
  final StudentService _studentService = StudentService();

  // Controller for the main scrollable view
  final ScrollController _scrollController = ScrollController();

  // State for post history
  late Future<List<Post>> _postsFuture;

  // List to hold the received friend requests
  List<FriendRequest> _receivedRequests = [];

  @override
  void initState() {
    super.initState();
    // Initialize the camera controller
    _initializeCamera(widget.camera);
    _loadInformation();
    _loadReceivedRequests();
    _postsFuture = _postService.getRelevantPosts();
  }

  // Load the received friend requests
  void _loadReceivedRequests() async {
    List<FriendRequest> receivedRequests = await _friendRequestService
        .getReceivedFriendRequests(
      FirebaseAuth.instance.currentUser?.uid ?? "",
    );
    setState(() {
      _receivedRequests = receivedRequests;
    });
  }

  void _loadInformation() async {
    List<String> friends = await _connectionService.getUserFriends(
      FirebaseAuth.instance.currentUser?.uid ?? "",
    );
    setState(() {
      _friendIds = friends;
      numFriends = friends.length;
    });
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.month}/${date.day}/${date.year}";
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture; // Wait for initialization to complete

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFlash() async {
    if (_controller.value.isInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });

      await _controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller.value.isInitialized) {
      await _controller.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    }
  }

  void _switchCamera() async {
    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
    final newCamera = widget.cameras[_currentCameraIndex];

    await _controller.dispose();
    await _initializeCamera(newCamera);
  }

  Future<void> _takePicture() async {
    try {
      // Ensure the camera is initialized
      await _initializeControllerFuture;

      // Take the picture
      final XFile image = await _controller.takePicture();

      // Get the application directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/Pictures';

      // Create the directory if it doesn't exist
      await Directory(dirPath).create(recursive: true);

      // Copy the image to the app's directory
      final String fileName = path.basename(image.path);
      final String localPath = '$dirPath/$fileName';

      File(image.path).copy(localPath);

      setState(() {
        _capturedImages.add(image);
      });

      // Navigate to the post status screen with the image path
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostStatusScreen(imagePath: image.path),
        ),
      ).then((_) {
        // Refresh posts when returning from posting a new image
        setState(() {
          _postsFuture = _postService.getRelevantPosts();
        });
      });
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: ${e.toString()}')),
      );
    }
  }

  // Scroll to history section
  void _scrollToHistory() {
    _scrollController.animateTo(
      MediaQuery.of(context).size.height * 0.9, // Scroll past the camera view
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Top bar with profile, friends count, and chat
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile picture
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),

                    // Friends count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsListScreen(
                                    friendIds: _friendIds,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "$numFriends friends",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chat button with received requests count
                    GestureDetector(
                      onTap: () {
                        // Navigate to chat or friend requests page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendRequestsPage(
                              receivedRequests: _receivedRequests,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                            if (_receivedRequests.isNotEmpty)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    '${_receivedRequests.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Camera preview area - fixed height container
              Container(
                height: MediaQuery.of(context).size.height * 0.6, // Fixed height for camera view
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Camera preview
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              child: CameraPreview(_controller),
                            ),
                          ),

                          // Flash button
                          Positioned(
                            left: 32,
                            top: 32,
                            child: GestureDetector(
                              onTap: _toggleFlash,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[700]?.withOpacity(
                                  0.7,
                                ),
                                child: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // Zoom button
                          Positioned(
                            right: 32,
                            top: 32,
                            child: GestureDetector(
                              onTap: () {
                                // Cycle through zoom levels: 1x, 2x, 3x
                                double nextZoom =
                                    _currentZoom >= 3 ? 1.0 : _currentZoom + 1.0;
                                _setZoom(nextZoom);
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey[700]?.withOpacity(
                                  0.7,
                                ),
                                child: Text(
                                  "${_currentZoom.toStringAsFixed(0)}×",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Show loading indicator while camera initializes
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),

              // Bottom camera controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    GestureDetector(
                      onTap: () {
                        // TODO: Open gallery
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gallery opened')),
                        );
                      },
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),

                    // History button (now scrolls to history instead of navigating)
                    GestureDetector(
                      onTap: _scrollToHistory,
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // History section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Your History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.expand_less,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),

              Container(
                height: MediaQuery.of(context).size.height , // Full screen height
                child: FutureBuilder<List<Post>>(
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

                    // Use ListView.builder for post-by-post scrolling
                    return ListView.builder(
                      physics: const PageScrollPhysics(), // Snap-like scrolling
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final post = snapshot.data![index];

                        return FutureBuilder<Map<String, String>>(
                          future: _studentService.getInfoPosterById(post.userId),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.pinkAccent),
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

                            String fullName = userSnapshot.data?['fullName'] ?? "Unknown User";
                            String email = userSnapshot.data?['email'] ?? "";
                            String profilePhoto = userSnapshot.data?['profilePhoto'] ?? "";

                            // Each post takes up the full screen height
                            return SizedBox(
                              height: MediaQuery.of(context).size.height,
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                color: Colors.grey[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                                                  builder: (context) =>
                                                      FriendProfileScreen(email: email),
                                                ),
                                              );
                                            },
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundImage: profilePhoto.isNotEmpty
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
                                                  builder: (context) =>
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
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.1, // Adjust this value to control the delay
                                      ),

                                      // Post Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AspectRatio(
                                          aspectRatio: 1.0,
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
                                        children: post.hashtags.map((hashtag) {
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
                                ),
                              ),
                            );
                          },
                        );
                      },
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
}

