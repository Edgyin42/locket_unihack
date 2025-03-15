import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Get current user's email
  String? getCurrentUserEmail() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  // Fetch student profile using email
  Future<Student?> getStudentProfileByEmail() async {
    try {
      String? email = getCurrentUserEmail();
      if (email == null) return null;

      QuerySnapshot querySnapshot =
          await _firestore
              .collection('students')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        return Student.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        // If student profile not found, return a new empty profile
        return Student(id: '', fullName: '', email: email);
      }
    } catch (e) {
      print('Error fetching student profile: $e');
      return null;
    }
  }

  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Create a reference to the storage location
      Reference storageRef = _storage.ref().child(
        'profile_pictures/$userId.jpg',
      );

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return ''; // Return empty string on failure
    }
  }

  // Create or update student profile
  Future<void> saveStudentProfile(Student student, {File? imageFile}) async {
    try {
      String profilePhotoUrl = student.profilePhoto;

      // Upload image if a new file is selected
      if (imageFile != null) {
        profilePhotoUrl = await uploadProfilePicture(imageFile);
      }

      // Convert student object to map
      Map<String, dynamic> studentData = student.toMap();
      studentData['profilePhoto'] =
          profilePhotoUrl; // Update only profile photo URL

      if (student.id.isEmpty) {
        // Create new profile
        await _firestore.collection('students').add(studentData);
      } else {
        // Update existing profile
        await _firestore.collection('students').doc(student.id).update({
          'fullName': student.fullName,
          'bio': student.bio,
          'profilePhoto': profilePhotoUrl, // Update only profile photo
        });
      }
    } catch (e) {
      print('Error saving student profile: $e');
    }
  }
}
