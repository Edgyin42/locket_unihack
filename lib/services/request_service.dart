import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/request_model.dart';

import 'connection_service.dart';

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectionService _connectionService = ConnectionService();
  final String collectionName = "friend_requests";

  // Send a friend request
  Future<void> sendFriendRequest(
    String fromStudentId,
    String toStudentId,
  ) async {
    await _firestore.collection(collectionName).add({
      'from_studentid': fromStudentId,
      'to_studentid': toStudentId,
      'status': 'pending',
    });
  }

  // Accept a friend request and create a connection
  Future<void> acceptFriendRequest(
    String requestId,
    String fromStudentId,
    String toStudentId,
  ) async {
    WriteBatch batch = _firestore.batch();

    // Update friend request status to 'accepted'
    batch.update(_firestore.collection(collectionName).doc(requestId), {
      'status': 'accepted',
    });

    await batch.commit();

    // Create connection using ConnectionService
    await _connectionService.addFriend(fromStudentId, toStudentId);
  }

  // Reject a friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection(collectionName).doc(requestId).update({
      'status': 'rejected',
    });
  }

  // Remove a friend request
  Future<void> removeFriendRequest(String requestId) async {
    await _firestore.collection(collectionName).doc(requestId).delete();
  }

  // Get received friend requests (pending only)
  Future<List<FriendRequest>> getReceivedFriendRequests(String userId) async {
    var snapshot =
        await _firestore
            .collection(collectionName)
            .where('to_studentid', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

    return snapshot.docs
        .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Get sent friend requests (pending only)
  Future<List<FriendRequest>> getSentFriendRequests(String userId) async {
    var snapshot =
        await _firestore
            .collection(collectionName)
            .where('from_studentid', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

    return snapshot.docs
        .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Check if a friend request exists between two users
  Future<FriendRequest?> getFriendRequest(
    String userId1,
    String userId2,
  ) async {
    var query1 =
        await _firestore
            .collection(collectionName)
            .where('from_studentid', isEqualTo: userId1)
            .where('to_studentid', isEqualTo: userId2)
            .get();

    var query2 =
        await _firestore
            .collection(collectionName)
            .where('from_studentid', isEqualTo: userId2)
            .where('to_studentid', isEqualTo: userId1)
            .get();

    if (query1.docs.isNotEmpty) {
      return FriendRequest.fromMap(
        query1.docs.first.id,
        query1.docs.first.data(),
      );
    } else if (query2.docs.isNotEmpty) {
      return FriendRequest.fromMap(
        query2.docs.first.id,
        query2.docs.first.data(),
      );
    }
    return null;
  }

  // Check if a pending friend request exists
  Future<bool> hasPendingFriendRequest(String from, String to) async {
    var query1 =
        await _firestore
            .collection(collectionName)
            .where('from_studentid', isEqualTo: from)
            .where('to_studentid', isEqualTo: to)
            .where('status', isEqualTo: 'pending')
            .get();

    return query1.docs.isNotEmpty;
  }
}
