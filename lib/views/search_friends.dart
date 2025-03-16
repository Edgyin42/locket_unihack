import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/views/viewfriendprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/connection_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final ConnectionService _connectionService = ConnectionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    var snapshot =
        await _firestore
            .collection('students')
            .where('fullName', isGreaterThanOrEqualTo: query)
            .where('fullName', isLessThan: query + '\uf8ff')
            .get();

    setState(() {
      _searchResults = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _addFriend(String friendId) async {
    await _connectionService.addFriend(currentUserId, friendId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Friend request sent!"),
        backgroundColor: Color(0xFFFF0099),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Search Friends", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Search by name",
                labelStyle: TextStyle(color: Color(0xFFFF0099)),
                prefixIcon: Icon(Icons.search, color: Color(0xFFFF0099)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF0099)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF0099), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var user = _searchResults[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FriendProfileScreen(email: user["email"]),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage:
                          user["profilePhoto"] != null
                              ? NetworkImage(user["profilePhoto"])
                              : null,
                      child:
                          user["profilePhoto"] == null
                              ? Icon(Icons.person, color: Colors.white70)
                              : null,
                    ),
                    title: Text(
                      user["fullName"],
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user["email"],
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.person_add, color: Color(0xFFFF0099)),
                      onPressed: () => _addFriend(user["id"]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
