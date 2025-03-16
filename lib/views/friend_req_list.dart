import 'package:demo/models/request_model.dart';
import 'package:demo/services/request_service.dart';
import 'package:demo/views/viewfriendprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/student_service.dart';

class FriendRequestsPage extends StatefulWidget {
  final List<FriendRequest> receivedRequests;

  const FriendRequestsPage({Key? key, required this.receivedRequests})
    : super(key: key);

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final StudentService studentService = StudentService();
  final FriendRequestService _friendRequestService = FriendRequestService();
  late List<FriendRequest> _currentRequests;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRequests = List.from(widget.receivedRequests);
  }

  // Method to reload friend requests from server
  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh data from server
      final updatedRequests = await _friendRequestService
          .getReceivedFriendRequests(
            FirebaseAuth.instance.currentUser?.uid ?? "",
          );

      setState(() {
        _currentRequests = updatedRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to refresh requests: $e')));
    }
  }

  // Method to handle accepting a request
  Future<void> _handleAcceptRequest(FriendRequest request) async {
    try {
      await _friendRequestService.acceptFriendRequest(
        request.id,
        request.fromStudentId,
        request.toStudentId,
      );

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Friend request accepted!')));

      // Refresh the requests list from server
      await _refreshRequests();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Received Friend Requests')),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _currentRequests.isEmpty
                ? Center(child: Text('No friend requests'))
                : ListView.builder(
                  itemCount: _currentRequests.length,
                  itemBuilder: (context, index) {
                    final request = _currentRequests[index];
                    return FutureBuilder<Map<String, String>>(
                      future: studentService.getInfoPosterById(
                        request.fromStudentId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            leading: CircularProgressIndicator(),
                            title: Text('Loading...'),
                          );
                        } else if (snapshot.hasError) {
                          return ListTile(
                            title: Text('Error loading user data'),
                            subtitle: Text('${snapshot.error}'),
                          );
                        } else if (snapshot.hasData) {
                          final userData = snapshot.data!;
                          final fullName = userData['fullName'] ?? 'Unknown';
                          final email = userData['email'] ?? '';
                          final profilePhoto = userData['profilePhoto'];

                          return ListTile(
                            leading:
                                profilePhoto != null && profilePhoto.isNotEmpty
                                    ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        profilePhoto,
                                      ),
                                      radius: 25,
                                    )
                                    : CircleAvatar(
                                      child: Text(fullName[0]),
                                      radius: 25,
                                    ),
                            title: Text(fullName),
                            subtitle: Text(email),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          FriendProfileScreen(email: email),
                                ),
                              );
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed:
                                      () => _handleAcceptRequest(request),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    // Handle decline friend request
                                    // Similar implementation would go here
                                  },
                                ),
                              ],
                            ),
                          );
                        } else {
                          return ListTile(title: Text('No data available'));
                        }
                      },
                    );
                  },
                ),
      ),
    );
  }
}
