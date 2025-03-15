import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:demo/helpers/seed_data.dart';
import 'package:flutter/material.dart';
import 'logIn.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await Supabase.initialize(
  //   url: 'https://cscyoladyqgzqebnoaqy.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzY3lvbGFkeXFnenFlYm5vYXF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIwMTM2NjAsImV4cCI6MjA1NzU4OTY2MH0.HYl9Yep6nlPlXJn6j-0lC26P71cigcLmFVug3LXrtx4',
  // );
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'ddpo3n8j3',
  );
  // await seedFirestoreClasses();
  // if (Supabase.instance.client.auth.currentUser != null) {
  //   print('hehe ');
  // } else {
  //   print('null roiiii');
  // }
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