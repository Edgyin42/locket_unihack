import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:demo/helpers/seed_data.dart';
import 'package:flutter/material.dart';
import 'logIn.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:demo/services/post_service.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/services/student_service.dart';
import 'dart:convert';
import 'dart:io';
import 'widgetScreet.dart';




void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and other services as before
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Cloudinary
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'ddpo3n8j3',
  );
  
  // Initialize home widget
  if (Platform.isIOS) {
    await HomeWidgetSetup.initHomeWidget();
  }
  
  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  // Run the app with camera info
  runApp(MyApp(cameras: cameras, initialCamera: firstCamera));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final CameraDescription initialCamera;

  const MyApp({super.key, required this.cameras, required this.initialCamera});

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
      home: LoginPage(initialCamera: initialCamera, cameras: cameras),
    );
  }
}