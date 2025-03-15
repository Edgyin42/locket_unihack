
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassService {
  final CollectionReference _classCollection = FirebaseFirestore.instance
      .collection('classes');

  // Add a new class
  Future<void> addClass(ClassModel classModel) async {
    await _classCollection.doc(classModel.id).set(classModel.toMap());
  }

  // Get all classes
  Future<List<ClassModel>> getAllClasses() async {
    final querySnapshot = await _classCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              ClassModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get a class by ID
  Future<ClassModel?> getClassById(String id) async {
    final docSnapshot = await _classCollection.doc(id).get();
    if (docSnapshot.exists) {
      return ClassModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    }
    return null;
  }

  // Update a class
  Future<void> updateClass(ClassModel classModel) async {
    await _classCollection.doc(classModel.id).update(classModel.toMap());
  }

  // Delete a class
  Future<void> deleteClass(String id) async {
    await _classCollection.doc(id).delete();
  }
}
