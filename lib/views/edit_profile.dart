import 'dart:io';
import 'package:camera/camera.dart';
import 'package:demo/logIn.dart';
import 'package:demo/models/class_model.dart';
import 'package:demo/services/class_service.dart';
import 'package:demo/services/class_student_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/student_service.dart';
import '../models/student_model.dart';
import '../models/class_student_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final StudentService _studentService = StudentService();
  final ClassStudentService _classStudentService = ClassStudentService();
  final ClassService _classService = ClassService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Student? student;
  File? _imageFile;
  List<ClassModel> allClasses = [];
  List<String> selectedClassIds = [];
  List<String> initialSelectedClassIds = [];
  bool _isLoading = true;

  // Define theme colors
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Color(0xFFFF1493); // Hot pink
  final Color _cardColor = Color(0xFF1E1E1E); // Dark grey

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    final cameras_ = await availableCameras();
    final firstCamera = cameras_.first;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  LoginPage(initialCamera: firstCamera, cameras: cameras_),
        ),
      );
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    Student? fetchedStudent = await _studentService.getStudentProfileByEmail();
    if (fetchedStudent != null) {
      List<ClassStudent> classStudents = await _classStudentService
          .getClassesByStudent(fetchedStudent.id);
      List<String> studentClassIds =
          classStudents.map((cs) => cs.classId).toList();
      List<ClassModel> classes = await _classService.getAllClasses();

      setState(() {
        student = fetchedStudent;
        _nameController.text = student!.fullName;
        _bioController.text = student!.bio;
        allClasses = classes;
        selectedClassIds = [...studentClassIds];
        initialSelectedClassIds = [...studentClassIds];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (student == null) return;

    setState(() {
      _isLoading = true;
    });

    String profilePhotoUrl = student!.profilePhoto;
    if (_imageFile != null) {
      profilePhotoUrl = await _studentService.uploadProfilePicture(_imageFile!);
    }

    Student updatedStudent = Student(
      id: student!.id,
      fullName: _nameController.text.trim(),
      email: student!.email,
      bio: _bioController.text.trim(),
      profilePhoto: profilePhotoUrl,
    );

    await _studentService.saveStudentProfile(updatedStudent);
    await _classStudentService.updateStudentClasses(
      student!.id,
      initialSelectedClassIds,
      selectedClassIds,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: _accentColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: _accentColor))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: _accentColor.withOpacity(0.2),
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (student?.profilePhoto.isNotEmpty ??
                                          false)
                                      ? NetworkImage(student!.profilePhoto)
                                          as ImageProvider
                                      : const AssetImage(
                                        'assets/default_profile.png',
                                      ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text(
                            //   'Personal Information',
                            //   style: TextStyle(
                            //     color: _accentColor,
                            //     fontSize: 18,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            // SizedBox(height: 20),
                            // TextField(
                            //   controller: _nameController,
                            //   style: TextStyle(color: Colors.white),
                            //   decoration: InputDecoration(
                            //     labelText: 'Full Name',
                            //     labelStyle: TextStyle(color: Colors.grey),
                            //     enabledBorder: OutlineInputBorder(
                            //       borderSide: BorderSide(
                            //         color: Colors.grey.shade800,
                            //       ),
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     focusedBorder: OutlineInputBorder(
                            //       borderSide: BorderSide(color: _accentColor),
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     prefixIcon: Icon(
                            //       Icons.person,
                            //       color: _accentColor,
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(height: 15),
                            // TextField(
                            //   controller: _bioController,
                            //   style: TextStyle(color: Colors.white),
                            //   maxLines: 3,
                            //   decoration: InputDecoration(
                            //     labelText: 'Bio',
                            //     labelStyle: TextStyle(color: Colors.grey),
                            //     enabledBorder: OutlineInputBorder(
                            //       borderSide: BorderSide(
                            //         color: Colors.grey.shade800,
                            //       ),
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     focusedBorder: OutlineInputBorder(
                            //       borderSide: BorderSide(color: _accentColor),
                            //       borderRadius: BorderRadius.circular(10),
                            //     ),
                            //     prefixIcon: Icon(
                            //       Icons.edit,
                            //       color: _accentColor,
                            //     ),
                            //   ),
                            // ),
                            // Within the Personal Information container section
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 25),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 5, bottom: 10),
                                  child: Text(
                                    'Full Name',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your full name',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade900,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade800,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _accentColor,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Padding(
                                  padding: EdgeInsets.only(left: 5, bottom: 10),
                                  child: Text(
                                    'Bio',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextField(
                                  controller: _bioController,
                                  style: TextStyle(color: Colors.white),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Write something about yourself',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade900,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade800,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _accentColor,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Classes',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 15),
                            TextField(
                              controller: _searchController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Search Classes',
                                labelStyle: TextStyle(color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade800,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: _accentColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: _accentColor,
                                ),
                              ),
                              onChanged: (value) => setState(() {}),
                            ),
                            SizedBox(height: 15),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: ListView(
                                children:
                                    allClasses
                                        .where(
                                          (cls) => cls.className
                                              .toLowerCase()
                                              .contains(
                                                _searchController.text
                                                    .toLowerCase(),
                                              ),
                                        )
                                        .map((cls) {
                                          bool isSelected = selectedClassIds
                                              .contains(cls.classId);
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade900,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: CheckboxListTile(
                                              title: Text(
                                                cls.className,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              value: isSelected,
                                              onChanged: (selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    selectedClassIds.add(
                                                      cls.classId,
                                                    );
                                                  } else {
                                                    selectedClassIds.remove(
                                                      cls.classId,
                                                    );
                                                  }
                                                });
                                              },
                                              activeColor: _accentColor,
                                              checkColor: Colors.white,
                                              side: BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Selected Classes:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  selectedClassIds.map((classId) {
                                    final className =
                                        allClasses
                                            .firstWhere(
                                              (cls) => cls.classId == classId,
                                              orElse:
                                                  () => ClassModel(
                                                    id: '',
                                                    classId: '',
                                                    className: 'Unknown',
                                                    description: '',
                                                  ),
                                            )
                                            .className;
                                    return Chip(
                                      label: Text(
                                        className,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: _accentColor.withOpacity(
                                        0.8,
                                      ),
                                      deleteIconColor: Colors.white,
                                      onDeleted:
                                          () => setState(
                                            () => selectedClassIds.remove(
                                              classId,
                                            ),
                                          ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'SAVE PROFILE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      TextButton(
                        onPressed: _signOut,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Sign Out'),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}
