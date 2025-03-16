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

  // Define theme colors
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Color(0xFFFF1493); // Hot pink
  final Color _cardColor = Color(0xFF1E1E1E); // Dark grey

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request accepted!'),
          backgroundColor: _accentColor,
        ),
      );

      // Refresh the requests list from server
      await _refreshRequests();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        color: _accentColor,
        backgroundColor: _cardColor,
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator(color: _accentColor))
                : _currentRequests.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_disabled,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No Friend Requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'You don\'t have any friend requests at the moment',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
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
                          return Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey.shade800,
                                  child: CircularProgressIndicator(
                                    color: _accentColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Loading...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error loading user data',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${snapshot.error}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasData) {
                          final userData = snapshot.data!;
                          final fullName = userData['fullName'] ?? 'Unknown';
                          final email = userData['email'] ?? '';
                          final profilePhoto = userData['profilePhoto'];

                          return Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
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
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    profilePhoto != null &&
                                            profilePhoto.isNotEmpty
                                        ? Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _accentColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              profilePhoto,
                                            ),
                                            radius: 28,
                                          ),
                                        )
                                        : Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _accentColor,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor: _accentColor
                                                .withOpacity(0.2),
                                            child: Text(
                                              fullName[0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                              ),
                                            ),
                                            radius: 28,
                                          ),
                                        ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.check_circle,
                                              color: _accentColor,
                                            ),
                                            onPressed:
                                                () => _handleAcceptRequest(
                                                  request,
                                                ),
                                            tooltip: 'Accept',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.cancel,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              // Handle decline friend request
                                            },
                                            tooltip: 'Decline',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'No data available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
      ),
    );
  }
}
