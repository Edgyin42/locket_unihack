import 'package:demo/services/connection_service.dart';
import 'package:demo/services/class_student_service.dart';
import 'package:demo/views/class_posts_view.dart';
import 'package:demo/views/friends_list.dart';
import 'package:demo/views/viewProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'PostStatusPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _CameraHomePageState extends State<CameraHomePage> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Add this line
  bool _isFlashOn = false;
  double _currentZoom = 1.0;
  int _currentCameraIndex = 0;
  List<XFile> _capturedImages = [];
  int numFriends = 0;
  List<String> _friendIds = [];
  List<String> _classIds = [];
  final ConnectionService _connectionService = ConnectionService();
  final ClassStudentService _classStudentService = ClassStudentService();
  
  // Replace TabController with PageController for vertical scrolling
  late PageController _pageController;
  bool _isShowingPosts = false;
  bool _forceRefresh = false;
  bool _isLoading = true; // Add loading state
  
  @override
  void initState() {
    super.initState();
    // Initialize the camera controller
    _initializeCamera(widget.camera);
    _loadInformation();
    
    // Initialize PageController for vertical scrolling
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );
  }

  void _loadInformation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get student class IDs
      // List<String> classIds = await _classStudentService.getStudentClassIds(
      //   FirebaseAuth.instance.currentUser?.uid ?? "",
      // );
      List<String> classIds = [];
      var query1;

      print("Current user UID: ${FirebaseAuth.instance.currentUser?.uid}");
      try {
        print("Attempting to query with UID: ${FirebaseAuth.instance.currentUser?.uid}");
        query1 = await _firestore
          .collection('class_students')
          .where('student_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();
          
        print("Query result: ${query1.docs.length} documents found");
        
        // Process the query results here
        if (query1.docs.isEmpty) {
          print("No documents found with the current user ID");
        } else {
          for (var doc in query1.docs) {
            print("Document data: ${doc.data()}");
          }
        }
      } catch (e) {
        print("Query error: $e");
        // Handle error
      }
      if (query1 != null && query1.docs != null) {
        print("Query successful, docs count: ${query1.docs.length}");
        classIds = [];
        for (var doc in query1.docs) {
          if (doc.data() != null && doc.data()['class_id'] != null) {
            classIds.add(doc.data()['class_id']);
          }
        }
        print("Class IDs: $classIds");
        setState(() {
          _classIds = classIds;
        });
      }
      List<String> friends = await _connectionService.getUserFriends(
        FirebaseAuth.instance.currentUser?.uid ?? "",
      );
      
      // Update state with fetched data
      if (mounted) {
        setState(() {
          _classIds = classIds;
          _friendIds = friends;
          numFriends = friends.length;
          _isLoading = false;
        });
      }
      print('hfodsja_ $classIds');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
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
    _pageController.dispose();
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
        // Refresh class IDs when returning from PostStatusScreen
        _loadInformation();
      });
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: ${e.toString()}')),
      );
    }
  }

  void _toggleView() {
    setState(() {
      _isShowingPosts = !_isShowingPosts;
    });
    
    // Scroll to the appropriate page
    _pageController.animateToPage(
      _isShowingPosts ? 1 : 0, 
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeInOut
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with profile, friends count, and view toggle
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
                      ).then((_) {
                        // Refresh class IDs when returning from ViewProfileScreen
                        _loadInformation();
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),

                  // Toggle button instead of tabs
                  GestureDetector(
                    onTap: _toggleView,
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
                            _isShowingPosts ? Icons.camera_alt : Icons.grid_view,
                            color: Colors.amber,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isShowingPosts ? "Camera" : "Posts",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Friends count
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
                            "$numFriends",
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

            // Vertical PageView for swiping between camera and posts
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.amber))
                : PageView(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() {
                        _isShowingPosts = index == 1;
                      });
                      
                      // Force redraw of the posts view when switching to it
                      if (index == 1) {
                        setState(() {
                          // Recreate the ClassPostsView with new key to force complete refresh
                          _forceRefresh = !_forceRefresh;
                        });
                      }
                    },
                    children: [
                      _buildCameraView(),
                      ClassPostsView(
                        key: ValueKey('classPostsView${_forceRefresh ? '1' : '2'}'),
                        classIds: _classIds,
                      ),
                    ],
                  ),
            ),
            
            // Swipe indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Icon(
                    _isShowingPosts ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.amber,
                  ),
                  Text(
                    _isShowingPosts ? "Swipe up for camera" : "Swipe down for posts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _buildCameraView() {
    return Column(
      children: [
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
                          backgroundColor: Colors.grey[700]?.withOpacity(0.7),
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
                          double nextZoom = _currentZoom >= 3 ? 1.0 : _currentZoom + 1.0;
                          _setZoom(nextZoom);
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[700]?.withOpacity(0.7),
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
                    border: Border.all(color: Colors.amber, width: 4),
                  ),
                ),
              ),

              // Flip camera button
              GestureDetector(
                onTap: _switchCamera,
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}