import 'package:demo/models/post_model.dart';
import 'package:demo/services/post_service.dart';
import 'package:demo/views/post_detail_view.dart';
import 'package:flutter/material.dart';

class ClassPostsView extends StatefulWidget {
  final List<String> classIds;
  final VoidCallback? onPageVisible;
  
  const ClassPostsView({
    Key? key, 
    required this.classIds,
    this.onPageVisible,
  }) : super(key: key);

  @override
  State<ClassPostsView> createState() => _ClassPostsViewState();
}

class _ClassPostsViewState extends State<ClassPostsView> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onPageVisible != null) {
      widget.onPageVisible!();
    }
  }

  void refreshPosts() {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    // Check if the widget is still mounted before proceeding
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print("ClassPostsView._loadPosts called with classIds: ${widget.classIds}");

      if (widget.classIds.isEmpty) {
        print("ClassPostsView: No class IDs available");
        // Check if still mounted before setting state
        if (!mounted) return;
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      List<Post> fetchedPosts = await _postService.getPostsForClasses(widget.classIds);
      print("ClassPostsView: Fetched ${fetchedPosts.length} posts");
      
      // Check if still mounted before setting state
      if (!mounted) return;
      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
    } catch (e) {
      print("ClassPostsView: Error loading posts: $e");
      // Check if still mounted before setting state
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load posts: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts available for your classes',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostCard(post: post);
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailView(post: post),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with author info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.authorProfilePhoto.isNotEmpty
                        ? NetworkImage(post.authorProfilePhoto)
                        : null,
                    child: post.authorProfilePhoto.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          post.className,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(post.timestamp),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Post content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  post.content,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              
            // Post image if available
            if (post.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  post.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Post actions row (share only)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.share_outlined, size: 20),
                      SizedBox(width: 4),
                      Text('Share'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}