class Connection {
  final String student1Id;
  final String student2Id;

  Connection({required this.student1Id, required this.student2Id});

  // Convert Firestore document to Connection object
  factory Connection.fromMap(Map<String, dynamic> map) {
    return Connection(
      student1Id: map['student1_id'] as String,
      student2Id: map['student2_id'] as String,
    );
  }

  // Convert Connection object to Firestore document
  Map<String, dynamic> toMap() {
    return {'student1_id': student1Id, 'student2_id': student2Id};
  }
}
