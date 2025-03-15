import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedFirestoreClasses() async {
  final firestore = FirebaseFirestore.instance;

  final classes = [
    {
      "class_id": "class_001",
      "class_name": "Mathematics",
      "description": "Basic algebra and calculus.",
    },
    {
      "class_id": "class_002",
      "class_name": "Physics",
      "description": "Introduction to mechanics and thermodynamics.",
    },
    {
      "class_id": "class_003",
      "class_name": "Biology",
      "description": "Study of living organisms.",
    },
  ];

  for (var classData in classes) {
    await firestore.collection('Classes').add(classData);
  }

  print("Firestore class data seeded!");
}
