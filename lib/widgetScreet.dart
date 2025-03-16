import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:demo/services/post_service.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/services/student_service.dart';
import 'dart:convert';
import 'dart:io';

// Constants for widget communication
const String appGroupId = 'group.com.unihack.widget';
const String widgetName = 'RecentPostWidget';

class HomeWidgetSetup {
  static final PostService _postService = PostService();
  static final StudentService _studentService = StudentService();

  // Initialize the widget and set up background updates
  static Future<void> initHomeWidget() async {
    await HomeWidget.setAppGroupId(appGroupId);
    
    // Register for widget updates
    HomeWidget.registerBackgroundCallback(backgroundCallback);
    
    // Update widget data immediately
    await updateWidgetData();
    
    // Set up periodic updates (every hour)
    HomeWidget.saveWidgetData<String>('last_update', DateTime.now().toIso8601String());
  }

  // Background callback to update widget data
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updatewidget') {
      await updateWidgetData();
    }
  }

  // Update the widget with latest post data
  static Future<void> updateWidgetData() async {
    try {
      // Get the most recent post
      List<Post> recentPosts = await _postService.getRelevantPosts();
      
      if (recentPosts.isEmpty) {
        await HomeWidget.saveWidgetData<String>('post_data', jsonEncode({
          'hasData': false,
          'message': 'No posts available'
        }));
        return;
      }
      
      // Get the first (most recent) post
      Post latestPost = recentPosts.first;
      
      // Get author information
      Map<String, String> authorInfo = await _studentService.getInfoPosterById(latestPost.userId);
      
      // Format timestamp
      DateTime postTime = latestPost.createdAt.toDate();
      String formattedDate = "${postTime.month}/${postTime.day}/${postTime.year}";
      
      // Save widget data
      Map<String, dynamic> widgetData = {
        'hasData': true,
        'imageUrl': latestPost.imageUrl,
        'description': latestPost.description,
        'authorName': authorInfo['fullName'] ?? 'Unknown User',
        'authorImage': authorInfo['profilePhoto'] ?? '',
        'date': formattedDate
      };
      
      // Save to shared preferences for widget access
      await HomeWidget.saveWidgetData<String>('post_data', jsonEncode(widgetData));
      
      // Optionally download the image for local caching
      if (Platform.isIOS) {
        try {
          // For iOS widgets, we need to save the image locally
          // This implementation depends on your specific image handling approach
          // You might need to use a package like http and path_provider to download
          // and save the image to a location accessible by the widget extension
        } catch (e) {
          print('Error caching image: $e');
        }
      }
      
      // Trigger widget update
      await HomeWidget.updateWidget(
        name: widgetName,
        iOSName: 'unihack',
      );
    } catch (e) {
      print('Error updating widget: $e');
      await HomeWidget.saveWidgetData<String>('post_data', jsonEncode({
        'hasData': false,
        'message': 'Error loading data'
      }));
    }
  }
}

// Widget to display in the app showing current widget state
class HomeWidgetMonitor extends StatefulWidget {
  const HomeWidgetMonitor({Key? key}) : super(key: key);

  @override
  State<HomeWidgetMonitor> createState() => _HomeWidgetMonitorState();
}

class _HomeWidgetMonitorState extends State<HomeWidgetMonitor> {
  String _widgetData = 'No data';
  
  @override
  void initState() {
    super.initState();
    _loadWidgetData();
    
    // Listen for widget updates
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }
  
  void _loadWidgetData() async {
    final data = await HomeWidget.getWidgetData<String>('post_data', defaultValue: 'No data');
    setState(() {
      _widgetData = data ?? 'No data';
    });
  }
  
  void _handleWidgetClick(Uri? uri) {
    // Handle taps on the widget, e.g., navigate to post details
    if (uri != null) {
      // Parse parameters from uri and navigate accordingly
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Widget Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_widgetData),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await HomeWidgetSetup.updateWidgetData();
                _loadWidgetData();
              },
              child: const Text('Update Widget'),
            ),
          ],
        ),
      ),
    );
  }
}