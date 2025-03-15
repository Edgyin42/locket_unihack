// import 'dart:io';

// import 'package:demo/models/class_model.dart';
// import 'package:demo/services/class_service.dart';
// import 'package:demo/services/class_student_service.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../services/student_service.dart';
// import '../models/student_model.dart';
// import '../models/class_student_model.dart';

// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({super.key});

//   @override
//   _EditProfileScreenState createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final StudentService _studentService = StudentService();
//   final ClassStudentService _classStudentService = ClassStudentService();
//   final ClassService _classService = ClassService();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _bioController = TextEditingController();
//   Student? student;
//   File? _imageFile;
//   List<ClassStudent>? classStudents = List.empty();
//   List<ClassModel> allClasses = [];
//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   Future<void> _loadProfile() async {
//     Student? fetchedStudent = await _studentService.getStudentProfileByEmail();
//     classStudents = await _classStudentService.getClassesByStudent(
//       fetchedStudent!.id,
//     );
//     allClasses = await _classService.getAllClasses();
//     setState(() {
//       student = fetchedStudent;
//       _nameController.text = student!.fullName;
//       _bioController.text = student!.bio;
//     });
//   }

//   Future<void> _pickImage() async {
//     final pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('New profile picture uploaded successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       setState(() {
//         _imageFile = File(pickedFile.path);
//       });
//     }
//   }

//   Future<void> _saveProfile() async {
//     if (student == null) return;

//     String profilePhotoUrl = student!.profilePhoto;

//     if (_imageFile != null) {
//       try {
//         profilePhotoUrl = await _studentService.uploadProfilePicture(
//           _imageFile!,
//         );
//       } catch (e) {
//         print(e);
//       }
//     }
//     print('nhinhinhi $profilePhotoUrl');

//     Student updatedStudent = Student(
//       id: student!.id,
//       fullName: _nameController.text.trim(),
//       email: student!.email,
//       bio: _bioController.text.trim(),
//       profilePhoto: profilePhotoUrl,
//     );

//     await _studentService.saveStudentProfile(updatedStudent);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Edit Profile')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundColor: Colors.grey[300],
//                 backgroundImage:
//                     _imageFile != null
//                         ? FileImage(_imageFile!)
//                         : (student?.profilePhoto.isNotEmpty ?? false)
//                         ? NetworkImage(student!.profilePhoto) as ImageProvider
//                         : const AssetImage('assets/default_profile.png'),
//                 child:
//                     _imageFile == null &&
//                             (student?.profilePhoto.isEmpty ?? true)
//                         ? const Icon(
//                           Icons.camera_alt,
//                           size: 40,
//                           color: Colors.grey,
//                         )
//                         : null,
//               ),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: 'Full Name'),
//             ),
//             TextField(
//               controller: _bioController,
//               decoration: const InputDecoration(labelText: 'Bio'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:demo/models/class_model.dart';
import 'package:demo/services/class_service.dart';
import 'package:demo/services/class_student_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _imageFile != null
                        ? FileImage(_imageFile!)
                        : (student?.profilePhoto.isNotEmpty ?? false)
                        ? NetworkImage(student!.profilePhoto) as ImageProvider
                        : const AssetImage('assets/default_profile.png'),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(labelText: 'Search Classes'),
              onChanged: (value) => setState(() {}),
            ),
            Expanded(
              child: ListView(
                children:
                    allClasses
                        .where(
                          (cls) => cls.className.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ),
                        )
                        .map((cls) {
                          bool isSelected = selectedClassIds.contains(
                            cls.classId,
                          );
                          return CheckboxListTile(
                            title: Text(cls.className),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedClassIds.add(cls.classId);
                                } else {
                                  selectedClassIds.remove(cls.classId);
                                }
                              });
                            },
                          );
                        })
                        .toList(),
              ),
            ),
            Wrap(
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
                      label: Text(className),
                      onDeleted:
                          () =>
                              setState(() => selectedClassIds.remove(classId)),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}