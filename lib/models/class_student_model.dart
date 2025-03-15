class ClassStudent {
  final String id;
  final String classId;
  final String studentId;

  ClassStudent({
    required this.id,
    required this.classId,
    required this.studentId,
  });

  // Convert Firestore document to ClassStudent object
  factory ClassStudent.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassStudent(
      id: documentId,
      classId: map['class_id'] ?? '',
      studentId: map['student_id'] ?? '',
    );
  }

  // Convert ClassStudent object to Firestore format
  Map<String, dynamic> toMap() {
    return {'class_id': classId, 'student_id': studentId};
  }
}