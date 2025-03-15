import 'package:demo/models/request_model.dart';
import 'package:demo/services/connection_service.dart';
import 'package:demo/services/request_service.dart'; // Import the FriendRequestService
import 'package:demo/views/friend_req_list.dart';
import 'package:demo/views/friends_list.dart';
import 'package:demo/views/post_history.dart';
import 'package:demo/views/viewProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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

  // List to hold the received friend requests
  List<FriendRequest> _receivedRequests = [];

  @override
  void initState() {
    super.initState();
    // Initialize the camera controller
    _initializeCamera(widget.camera);
    _loadInformation();
    _loadReceivedRequests(); // Load the received friend requests
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
      );
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: ${e.toString()}')),
      );
    }
  }

  // Navigate to post history
  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostsHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                                builder:
                                    (context) => FriendsListScreen(
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
                          builder:
                              (context) => FriendRequestsPage(
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

            // Camera preview area
            Expanded(
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

                  // History button
                  GestureDetector(
                    onTap: _navigateToHistory,
                    child: const Icon(
                      Icons.history,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
