import 'package:flutter/material.dart';
import 'logIn.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  
  // Run the app with camera info
  runApp(MyApp(cameras: cameras, initialCamera: firstCamera));
}


class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final CameraDescription initialCamera;

  const MyApp({
    Key? key, 
    required this.cameras, 
    required this.initialCamera
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
      home: LoginPage(initialCamera: initialCamera, cameras: cameras,)
    );
  }
}

