import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendProfileScreen extends StatelessWidget {
  final String userId;

  FriendProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('students').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      userData["photoUrl"] != null
                          ? NetworkImage(userData["photoUrl"])
                          : null,
                  child:
                      userData["photoUrl"] == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                ),
                SizedBox(height: 16),
                Text(
                  userData["fullName"],
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  userData["email"],
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  "Class: ${userData["class_id"] ?? 'N/A'}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
