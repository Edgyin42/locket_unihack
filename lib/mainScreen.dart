import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraApp extends StatelessWidget {
  final CameraDescription camera;
  final List<CameraDescription> cameras;
  
  const CameraApp({
    Key? key, 
    required this.camera,
    required this.cameras,
  }) : super(key: key);

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
  
  const CameraHomePage({
    Key? key, 
    required this.camera,
    required this.cameras,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    // Initialize the camera controller
    _initializeCamera(widget.camera);
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
    
    if (mounted) {
      setState(() {});
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture saved!')),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Friends count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '9 Friends',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Chat button
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
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
                        border: Border.all(
                          color: Colors.amber,
                          width: 4,
                        ),
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
            
            // History section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Thumbnail - show last captured image if available
                      Container(
                        height: 30,
                        width: 30,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                          image: _capturedImages.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(_capturedImages.last.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _capturedImages.isEmpty
                            ? Icon(Icons.image, color: Colors.grey[300], size: 20)
                            : null,
                      ),
                      
                      // Text
                      const Text(
                        'History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
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