import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_student_model.dart';

class ClassStudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all class-student associations for a student
  Future<List<ClassStudent>> getClassesByStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('class_students')
          .where('studentId', isEqualTo: studentId)
          .get();
          
      return snapshot.docs
          .map((doc) => ClassStudent(
                id: doc.id,
                classId: doc['classId'] ?? '',
                studentId: doc['studentId'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('Error getting classes by student: $e');
      return [];
    }
  }

  // Get just the class IDs for a student
  Future<List<String>> getStudentClassIds(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('class_students')
          .where('studentId', isEqualTo: studentId)
          .get();
          
      return snapshot.docs
          .map((doc) => doc['classId'] as String)
          .where((classId) => classId.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting student class IDs: $e');
      return [];
    }
  }

  // Update a student's class enrollments
  Future<void> updateStudentClasses(
    String studentId,
    List<String> initialClassIds,
    List<String> newClassIds,
  ) async {
    try {
      // Classes to remove (in initial but not in new)
      final classesToRemove = initialClassIds
          .where((id) => !newClassIds.contains(id))
          .toList();

      // Classes to add (in new but not in initial)
      final classesToAdd = newClassIds
          .where((id) => !initialClassIds.contains(id))
          .toList();

      // Remove classes
      for (String classId in classesToRemove) {
        await _removeStudentFromClass(studentId, classId);
      }

      // Add classes
      for (String classId in classesToAdd) {
        await _addStudentToClass(studentId, classId);
      }
    } catch (e) {
      print('Error updating student classes: $e');
      throw e;
    }
  }

  Future<void> _addStudentToClass(String studentId, String classId) async {
    try {
      // Check if association already exists
      final existingDoc = await _firestore
          .collection('class_students')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .get();

      if (existingDoc.docs.isEmpty) {
        // Add new association
        await _firestore.collection('class_students').add({
          'studentId': studentId,
          'classId': classId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding student to class: $e');
      throw e;
    }
  }

  Future<void> _removeStudentFromClass(String studentId, String classId) async {
    try {
      final docs = await _firestore
          .collection('class_students')
          .where('studentId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .get();

      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing student from class: $e');
      throw e;
    }
  }
}