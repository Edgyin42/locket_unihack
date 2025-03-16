import 'package:demo/views/search_friends.dart';
import 'package:demo/views/viewfriendprofile.dart';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Friends List", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0099)),
                ),
              )
              : ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  var friend = _friends[index];

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        backgroundImage:
                            friend["profilePhoto"] != null
                                ? NetworkImage(friend["profilePhoto"])
                                : null,
                        child:
                            friend["profilePhoto"] == null
                                ? Icon(Icons.person, color: Colors.white70)
                                : null,
                      ),
                      title: Text(
                        friend["fullName"] ?? "",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        friend["email"] ?? "",
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    FriendProfileScreen(email: friend["email"]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        backgroundColor: Color(0xFFFF0099),
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
