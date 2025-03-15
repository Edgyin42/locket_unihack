import 'package:demo/views/search_friends.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/connection_service.dart';

class FriendsListScreen extends StatefulWidget {
  final List<String> friendIds;

  const FriendsListScreen({Key? key, required this.friendIds})
    : super(key: key);

  @override
  _FriendsListScreenState createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final ConnectionService _connectionService = ConnectionService();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() async {
    List<Map<String, dynamic>> friends = await _connectionService
        .getFriendDetails(widget.friendIds);
    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Friends List")),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  var friend = _friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          friend["photoUrl"] != null
                              ? NetworkImage(friend["photoUrl"])
                              : null,
                      child:
                          friend["photoUrl"] == null
                              ? Icon(Icons.person)
                              : null,
                    ),
                    title: Text(friend["name"]),
                    subtitle: Text(friend["email"]),
                  );
                },
              ),

      // Floating Action Button to add friends
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
