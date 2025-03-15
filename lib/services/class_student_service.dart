import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_student_model.dart';

class ClassStudentService {
  final CollectionReference _classStudentCollection = FirebaseFirestore.instance
      .collection('class_students');

  // Add a new class-student entry
  Future<void> addClassStudent(ClassStudent classStudent) async {
    await _classStudentCollection
        .doc(classStudent.id)
        .set(classStudent.toMap());
  }

  // Get all class-student relationships
  Future<List<ClassStudent>> getAllClassStudents() async {
    final querySnapshot = await _classStudentCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              ClassStudent.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get students by class_id
  Future<List<ClassStudent>> getStudentsByClass(String classId) async {
    final querySnapshot =
        await _classStudentCollection
            .where('class_id', isEqualTo: classId)
            .get();
    return querySnapshot.docs
        .map(
          (doc) =>
              ClassStudent.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get classes by student_id
  Future<List<ClassStudent>> getClassesByStudent(String studentId) async {
    final querySnapshot =
        await _classStudentCollection
            .where('student_id', isEqualTo: studentId)
            .get();
    return querySnapshot.docs
        .map(
          (doc) =>
              ClassStudent.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Delete a class-student entry
  Future<void> deleteClassStudent(String id) async {
    await _classStudentCollection.doc(id).delete();
  }

  Future<void> updateStudentClasses(
    String studentId,
    List<String> oldClassIds,
    List<String> newClassIds,
  ) async {
    try {
      // Determine classes to add and remove
      List<String> classesToAdd =
          newClassIds.where((id) => !oldClassIds.contains(id)).toList();
      List<String> classesToRemove =
          oldClassIds.where((id) => !newClassIds.contains(id)).toList();

      // Reference to Class_Student collection

      // Delete old classes
      for (String classId in classesToRemove) {
        QuerySnapshot query =
            await _classStudentCollection
                .where('student_id', isEqualTo: studentId)
                .where('class_id', isEqualTo: classId)
                .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
      }

      // Add new classes
      for (String classId in classesToAdd) {
        await _classStudentCollection.add({
          'student_id': studentId,
          'class_id': classId,
        });
      }

      print("Student classes updated successfully!");
    } catch (e) {
      print("Error updating student classes: $e");
    }
  }
}