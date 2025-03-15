class ClassModel {
  final String id;
  final String classId;
  final String className;
  final String description;

  ClassModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.description,
  });

  // Convert Firestore document to ClassModel object
  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassModel(
      id: documentId,
      classId: map['class_id'] ?? '',
      className: map['class_name'] ?? '',
      description: map['description'] ?? '',
    );
  }

  // Convert ClassModel object to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'class_name': className,
      'description': description,
    };
  }
}
