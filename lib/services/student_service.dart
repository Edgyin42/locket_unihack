import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Create or update student profile
  Future<void> saveStudentProfile(Student student) async {
    try {
      if (student.id.isEmpty) {
        // Create new profile
        await _firestore.collection('students').add(student.toMap());
      } else {
        // Update existing profile
        await _firestore
            .collection('students')
            .doc(student.id)
            .set(student.toMap());
      }
    } catch (e) {
      print('Error saving student profile: $e');
    }
  }
}
