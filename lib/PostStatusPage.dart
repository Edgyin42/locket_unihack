import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../services/student_service.dart';
import '../services/class_student_service.dart';

class PostStatusScreen extends StatefulWidget {
  final String imagePath;

  const PostStatusScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<PostStatusScreen> createState() => _PostStatusScreenState();
}

class _PostStatusScreenState extends State<PostStatusScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final List<String> _selectedClasses = [];
  final List<String> _hashtags = [];
  bool _isUploading = false;
  final int _maxWords = 100;
  int _currentWordCount = 0;
  List<ClassModel> _availableClasses = [];
  final ClassService _classService = ClassService();
  final StudentService _studentService = StudentService();
  final ClassStudentService _classStudentService = ClassStudentService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchUserClasses();
    _descriptionController.addListener(_countWords);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  void _countWords() {
    setState(() {
      final text = _descriptionController.text.trim();
      _currentWordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _fetchUserClasses() async {
    try {
      // First get current student profile
      final studentProfile = await _studentService.getStudentProfileByEmail();
      if (studentProfile != null) {
        _currentUserId = studentProfile.id;
        
        // Fetch all available classes
        final allClasses = await _classService.getAllClasses();
        
        // If student ID exists, fetch enrolled classes
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          final enrolledClasses = await _classStudentService.getClassesByStudent(_currentUserId!);
          final enrolledClassIds = enrolledClasses.map((cs) => cs.classId).toList();
          
          setState(() {
            _availableClasses = allClasses;
          });
        } else {
          // If no student ID, just show all classes
          setState(() {
            _availableClasses = allClasses;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching classes: $e')),
      );
    }
  }

  void _toggleClassSelection(String classId) {
    setState(() {
      if (_selectedClasses.contains(classId)) {
        _selectedClasses.remove(classId);
      } else {
        _selectedClasses.add(classId);
      }
    });
  }

  void _addHashtag() {
    final hashtag = _hashtagController.text.trim();
    if (hashtag.isNotEmpty) {
      // Format hashtag with # if not already present
      final formattedHashtag = hashtag.startsWith('#') ? hashtag : '#$hashtag';
      setState(() {
        _hashtags.add(formattedHashtag);
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(int index) {
    setState(() {
      _hashtags.removeAt(index);
    });
  }

  Future<void> _uploadImage() async {
    if (_currentWordCount > _maxWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description exceeds 100 words limit')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Configure Cloudinary
      final cloudinary = CloudinaryPublic('ddpo3n8j3', 'michaelwave');
      
      // Upload image to Cloudinary
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(widget.imagePath, folder: 'status_images'),
      );
      
      // Get the secure URL of the uploaded image
      final imageUrl = response.secureUrl;
      
      // Get current user
      final studentProfile = await _studentService.getStudentProfileByEmail();
      final userId = studentProfile?.id ?? 'unknown-user';
      
      // Save post data to Firebase
      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': imageUrl,
        'description': _descriptionController.text,
        'hashtags': _hashtags,
        'classes': _selectedClasses,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted successfully!')),
        );
        Navigator.of(context).pop(); // Return to previous screen after posting
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadImage,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '$_currentWordCount/$_maxWords words',
                        style: TextStyle(
                          color: _currentWordCount > _maxWords ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Classes section
              const Text(
                'Choose Classes (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _availableClasses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableClasses.map((classData) {
                        final isSelected = _selectedClasses.contains(classData.classId);
                        return GestureDetector(
                          onTap: () => _toggleClassSelection(classData.classId),
                          child: Chip(
                            backgroundColor: isSelected ? Colors.amber : Colors.grey[800],
                            label: Text(
                              classData.className,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),

              // Hashtags section
              const Text(
                'Add Hashtags',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hashtagController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a hashtag",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.tag, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addHashtag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addHashtag,
                    icon: Icon(Icons.add_circle, color: Colors.amber),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _hashtags.length,
                  (index) => Chip(
                    backgroundColor: Colors.amber.withOpacity(0.8),
                    label: Text(
                      _hashtags[index],
                      style: const TextStyle(color: Colors.black),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeHashtag(index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}