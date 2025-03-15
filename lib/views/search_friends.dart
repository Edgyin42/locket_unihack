import 'package:cloud_firestore/cloud_firestore.dart';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Friend request sent!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Friends")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                labelText: "Search by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user["photoUrl"] != null
                            ? NetworkImage(user["photoUrl"])
                            : null,
                    child: user["photoUrl"] == null ? Icon(Icons.person) : null,
                  ),
                  title: Text(user["fullName"]),
                  subtitle: Text(user["email"]),
                  trailing: IconButton(
                    icon: Icon(Icons.person_add, color: Colors.green),
                    onPressed: () => _addFriend(user["id"]),
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
