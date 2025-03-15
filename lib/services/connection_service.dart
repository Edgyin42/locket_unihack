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

  Future<bool> areFriends(String userId, String friendId) async {
    var query =
        await _firestore
            .collection('connections')
            .where('student1_id', isEqualTo: userId)
            .where('student2_id', isEqualTo: friendId)
            .get();

    if (query.docs.isNotEmpty) return true;

    query =
        await _firestore
            .collection('connections')
            .where('student1_id', isEqualTo: friendId)
            .where('student2_id', isEqualTo: userId)
            .get();

    return query.docs.isNotEmpty;
  }

  Future<void> removeFriend(String userId, String friendId) async {
    var query1 =
        await _firestore
            .collection("connections")
            .where("student1_id", isEqualTo: userId)
            .where("student2_id", isEqualTo: friendId)
            .get();

    var query2 =
        await _firestore
            .collection("connections")
            .where("student1_id", isEqualTo: friendId)
            .where("student2_id", isEqualTo: userId)
            .get();

    for (var doc in query1.docs) {
      await _firestore.collection("connections").doc(doc.id).delete();
    }
    for (var doc in query2.docs) {
      await _firestore.collection("connections").doc(doc.id).delete();
    }
  }
}
