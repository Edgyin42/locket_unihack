
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ClassModel>> getAllClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();
      return snapshot.docs
          .map((doc) => ClassModel(
                id: doc.id,
                classId: doc['class_id'],
                className: doc['class_name'] ?? '',
                description: doc['description'] ?? '',
              ))
          .toList();
    } catch (e) {
      print('Error getting all classes: $e');
      return [];
    }
  }

  // Add this new method to get classes by their IDs
  Future<List<ClassModel>> getClassesByIds(List<String> classIds) async {
    if (classIds.isEmpty) {
      return [];
    }

    try {
      // Using whereIn operator, which supports up to 10 values at a time
      // If more than 10 ids, we need to split into multiple queries
      List<ClassModel> result = [];
      
      // Process classIds in batches of 10
      for (int i = 0; i < classIds.length; i += 10) {
        final end = (i + 10 < classIds.length) ? i + 10 : classIds.length;
        final batch = classIds.sublist(i, end);
        
        final snapshot = await _firestore
            .collection('classes')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
            
        final classes = snapshot.docs.map((doc) => ClassModel(
              id: doc.id,
              classId: doc.id,
              className: doc['class_id'] ?? 'Unknown Class',
              description: doc['description'] ?? '',
            )).toList();
            
        result.addAll(classes);
      }
      
      return result;
    } catch (e) {
      print('Error getting classes by IDs: $e');
      return [];
    }
  }

  Future<ClassModel?> getClassById(String classId) async {
    try {
      final doc = await _firestore.collection('classes').doc(classId).get();
      if (doc.exists) {
        return ClassModel(
          id: doc.id,
          classId: doc.id,
          className: doc['className'] ?? '',
          description: doc['description'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print('Error getting class by ID: $e');
      return null;
    }
  }
}