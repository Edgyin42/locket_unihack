import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getUserFriends(String userId) async {
    List<String> friendIds = [];

    // Fetch connections where the user is student1
    var query1 =
        await _firestore
            .collection('connections')
            .where('student1_id', isEqualTo: userId)
            .get();
    friendIds.addAll(query1.docs.map((doc) => doc['student2_id'] as String));

    // Fetch connections where the user is student2
    var query2 =
        await _firestore
            .collection('connections')
            .where('student2_id', isEqualTo: userId)
            .get();
    friendIds.addAll(query2.docs.map((doc) => doc['student1_id'] as String));

    return friendIds;
  }

  Future<List<Map<String, dynamic>>> getFriendDetails(
    List<String> friendIds,
  ) async {
    if (friendIds.isEmpty) return [];

    var snapshot =
        await _firestore
            .collection("students")
            .where(FieldPath.documentId, whereIn: friendIds)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addFriend(String userId, String friendId) async {
    await _firestore.collection("connections").add({
      "student1_id": userId,
      "student2_id": friendId,
    });
  }
}
