import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Campus Connect', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: () {
              // TODO: Navigate to reels screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reels feature coming soon!')),
              );
            },
            tooltip: 'Reels',
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _postService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final posts = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(posts[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        ),
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final userId = _authService.currentUser?.uid;
    final isLiked = userId != null && post.isLikedBy(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
                  backgroundImage: post.isAnonymous || post.userAvatar == null
                      ? null
                      : CachedNetworkImageProvider(post.userAvatar!),
                  child: post.isAnonymous || post.userAvatar == null
                      ? const Icon(Icons.person, color: AppColors.primaryPurple)
                      : null,
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isAnonymous ? 'Anonymous' : post.username,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.grey),
                  onPressed: () => _showPostOptions(post),
                ),
              ],
            ),
          ),

          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post.content,
                style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
              ),
            ),

          // Media
          if (post.hasMedia) _buildPostMedia(post),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: AppColors.errorRed),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 16, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${post.shareCount} shares',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                // Like Button
                Expanded(
                  child: TextButton.icon(
                    onPressed: userId != null
                        ? () => _toggleLike(post.id, userId)
                        : null,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? AppColors.errorRed : AppColors.grey,
                    ),
                    label: Text(
                      'Like',
                      style: GoogleFonts.poppins(
                        color: isLiked ? AppColors.errorRed : AppColors.grey,
                      ),
                    ),
                  ),
                ),
                // Comment Button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showComments(post.id),
                    icon: const Icon(Icons.comment, color: AppColors.grey),
                    label: Text('Comment', style: GoogleFonts.poppins(color: AppColors.grey)),
                  ),
                ),
                // Share Button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _sharePost(post),
                    icon: const Icon(Icons.share, color: AppColors.grey),
                    label: Text('Share', style: GoogleFonts.poppins(color: AppColors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(PostModel post) {
    if (!post.hasMedia) return const SizedBox.shrink();

    // Single image
    if (post.mediaUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showMediaViewer(post.mediaUrls, 0),
        child: Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(int.parse(post.backgroundColor.substring(1), radix: 16)),
          ),
          child: CachedNetworkImage(
            imageUrl: post.mediaUrls[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    // Multiple images - carousel
    return Container(
      height: 300,
      color: Color(int.parse(post.backgroundColor.substring(1), radix: 16)),
      child: PageView.builder(
        itemCount: post.mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showMediaViewer(post.mediaUrls, index),
            child: CachedNetworkImage(
              imageUrl: post.mediaUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(color: AppColors.primaryPurple),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 80, color: AppColors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String postId, String userId) async {
    try {
      await _postService.toggleLike(postId, userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: postId),
    );
  }

  Future<void> _sharePost(PostModel post) async {
    try {
      final shareableLink = 'https://campusconnect.app/post/${post.id}';
      final message = '${post.content}\n\nCheck out this post on Campus Connect: $shareableLink';
      
      await Share.share(message);
      
      // Increment share count
      await _postService.incrementShareCount(post.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  void _showMediaViewer(List<String> mediaUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: mediaUrls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: mediaUrls[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: AppColors.errorRed),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported')),
                );
              },
            ),
            if (post.userId == _authService.currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.errorRed),
                title: const Text('Delete Post'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    try {
      await _postService.deletePost(postId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, yyyy').format(date);
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

// Comments Bottom Sheet
class CommentsBottomSheet extends StatefulWidget {
  final String postId;

  const CommentsBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _postService.addComment(
        postId: widget.postId,
        content: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _postService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No comments yet'));
                }

                final comments = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentCard(comments[index]);
                  },
                );
              },
            ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      activeColor: AppColors.primaryPurple,
                    ),
                    Text('Comment anonymously', style: GoogleFonts.poppins(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          filled: true,
                          fillColor: AppColors.lightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.send, color: AppColors.primaryPurple),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommentModel comment) {
    final userId = _authService.currentUser?.uid;
    final isLiked = userId != null && comment.isLikedBy(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
            backgroundImage: comment.isAnonymous || comment.userAvatar == null
                ? null
                : CachedNetworkImageProvider(comment.userAvatar!),
            child: comment.isAnonymous || comment.userAvatar == null
                ? const Icon(Icons.person, size: 16, color: AppColors.primaryPurple)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.isAnonymous ? 'Anonymous' : comment.username,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: userId != null
                          ? () => _postService.toggleCommentLike(comment.id, userId)
                          : null,
                      child: Text(
                        'Like',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${comment.likeCount} likes',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}