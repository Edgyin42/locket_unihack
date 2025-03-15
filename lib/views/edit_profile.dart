import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/student_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  Student? student;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    Student? fetchedStudent = await _studentService.getStudentProfileByEmail();
    if (fetchedStudent != null) {
      setState(() {
        student = fetchedStudent;
        _nameController.text = student!.fullName;
        _bioController.text = student!.bio;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (student == null) return;

    Student updatedStudent = Student(
      id: student!.id,
      fullName: _nameController.text.trim(),
      email: student!.email,
      bio: _bioController.text.trim(),
      profilePhoto: student!.profilePhoto,
    );

    await _studentService.saveStudentProfile(updatedStudent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
