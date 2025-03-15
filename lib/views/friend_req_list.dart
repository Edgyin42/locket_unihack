import 'package:demo/models/request_model.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatelessWidget {
  final List<FriendRequest> receivedRequests;

  const FriendRequestsPage({Key? key, required this.receivedRequests})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Received Friend Requests')),
      body: ListView.builder(
        itemCount: receivedRequests.length,
        itemBuilder: (context, index) {
          final request = receivedRequests[index];
          return ListTile(
            title: Text(
              request.fromStudentId,
            ), // Assuming the FriendRequest model has 'senderName'
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    // Handle accept friend request
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    // Handle decline friend request
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
