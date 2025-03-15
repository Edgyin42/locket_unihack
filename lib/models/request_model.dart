class FriendRequest {
  final String id;
  final String fromStudentId;
  final String toStudentId;
  final String status;

  FriendRequest({
    required this.id,
    required this.fromStudentId,
    required this.toStudentId,
    required this.status,
  });

  factory FriendRequest.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequest(
      id: id,
      fromStudentId: data['from_studentid'],
      toStudentId: data['to_studentid'],
      status: data['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from_studentid': fromStudentId,
      'to_studentid': toStudentId,
      'status': status,
    };
  }
}
