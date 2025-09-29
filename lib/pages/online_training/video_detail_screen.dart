import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'video_player_screen.dart';
import 'package:the_factory/services/video_api_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic>? videoData;

  const VideoDetailScreen({super.key, required this.videoId, this.videoData});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  Map<String, dynamic>? video;
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  bool isLoadingComments = false;
  bool hasError = false;
  String errorMessage = '';
  bool isLiked = false;
  bool isDisliked = false;
  bool isPurchased = false;
  int likesCount = 0;
  int dislikesCount = 0;
  bool isDescriptionExpanded = false;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    video = widget.videoData;
    if (video != null) {
      _initializeVideoState();
    }
    _loadVideoDetails();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeVideoState() {
    if (video != null) {
      // Assuming your API returns integer counts directly
      likesCount = video!['likes'] ?? 0;
      dislikesCount = video!['dislikes'] ?? 0;

      // Note: You'll need to check if current user has liked/disliked
      // This would require the user ID from your auth system
    }
  }

  Future<void> _loadVideoDetails() async {
    if (video != null && !isLoading) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await VideoApiService.getVideoById(widget.videoId);

      if (response['success']) {
        print(response['data']);
        setState(() {
          video = response['data'];
          _initializeVideoState();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = response['message'] ?? 'Failed to load video';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      isLoadingComments = true;
    });

    try {
      final response = await VideoApiService.getComments(widget.videoId);
      if (response['success']) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(response['data'] ?? []);
          isLoadingComments = false;
        });
      } else {
        setState(() {
          isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      final response = await VideoApiService.addComment(
        widget.videoId,
        commentText,
      );
      if (response['success']) {
        _commentController.clear();
        await _loadComments(); // Reload comments
        _showSuccessSnackBar('Comment added successfully!');
      } else {
        _showErrorSnackBar('Failed to add comment');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add comment: $e');
    }
  }

  Future<void> _likeVideo() async {
    try {
      final response = await VideoApiService.likeVideo(widget.videoId);
      if (response['success']) {
        setState(() {
          if (isLiked) {
            likesCount--;
            isLiked = false;
          } else {
            if (isDisliked) {
              dislikesCount--;
              isDisliked = false;
            }
            likesCount++;
            isLiked = true;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to like video: $e');
    }
  }

  Future<void> _dislikeVideo() async {
    try {
      final response = await VideoApiService.dislikeVideo(widget.videoId);
      if (response['success']) {
        setState(() {
          if (isDisliked) {
            dislikesCount--;
            isDisliked = false;
          } else {
            if (isLiked) {
              likesCount--;
              isLiked = false;
            }
            dislikesCount++;
            isDisliked = true;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to dislike video: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB8FF00),
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Purchase Video',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video!['title'],
                style: const TextStyle(
                  color: Color(0xFFB8FF00),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Price: \$${video!['price']?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Once purchased, you\'ll have lifetime access to this video.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isPurchased = true;
                });
                _showSuccessSnackBar('Video purchased successfully!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Purchase',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB8FF00) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFB8FF00) : const Color(0xFF404040),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final String userName =
        comment['user']?['profile']?['fullName'] ??
        comment['user']?['name'] ??
        'Anonymous';

    final String userAvatar =
        comment['user']?['profile']?['avatar']?['url'] ??
        'https://i.pravatar.cc/150?u=${comment['user']?['_id']}';
    final String commentText = comment['comment'] ?? '';
    final String timeAgo = _formatDate(comment['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: userAvatar,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                placeholder:
                    (context, url) =>
                        const CircularProgressIndicator(strokeWidth: 1),
                errorWidget:
                    (context, url, error) =>
                        const Icon(Icons.person, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Color(0xFFB8FF00),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  commentText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox() {
    final description = video!['description'] ?? 'No description available';
    final shouldShowReadMore = description.length > 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(
              description.length > 150
                  ? '${description.substring(0, 150)}...'
                  : description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            crossFadeState:
                isDescriptionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (shouldShowReadMore) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Text(
                isDescriptionExpanded ? 'Show less' : 'Show more',
                style: const TextStyle(
                  color: Color(0xFFB8FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Tags
          if (video!['tags'] != null && video!['tags'].isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.from(
                video!['tags'].map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';

    try {
      DateTime date;
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        date = dateTime;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _watchVideo() {
    if (video == null) return;

    final bool isFree = !(video!['isPremium'] ?? false);

    if (!isFree && !isPurchased) {
      _showPurchaseDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VideoPlayerScreen(
              videoUrl: video!['videoUrl'] ?? '',
              videoTitle: video!['title'] ?? '',
              videoId: widget.videoId,
              onLike: _likeVideo,
              onDislike: _dislikeVideo,
              isLiked: isLiked,
              isDisliked: isDisliked,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadVideoDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (video == null) return const SizedBox();

    final bool isFree = !(video!['isPremium'] ?? false);
    final String thumbnailUrl = video!['thumbnailUrl'] ?? '';
    final String instructorName =
        video!['uploadedBy']?['profile']?['fullName'] ??
        video!['uploadedBy']?['name'] ??
        'Unknown';

    final String instructorAvatar =
        video!['uploadedBy']?['profile']?['avatar']?['url'] ??
        'https://i.pravatar.cc/150?u=${video!['uploadedBy']?['_id']}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar with Thumbnail
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Thumbnail
                  if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        );
                      },
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Play button
                  Center(
                    child: GestureDetector(
                      onTap: _watchVideo,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  // Premium badge
                  if (!isFree)
                    Positioned(
                      top: 60,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.black,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${video!['price']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Video Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Title
                  Text(
                    video!['title'] ?? 'Untitled Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Video Stats & Actions
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[800],
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: instructorAvatar,
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            placeholder:
                                (context, url) =>
                                    const CircularProgressIndicator(
                                      strokeWidth: 1,
                                    ),
                            errorWidget:
                                (context, url, error) => const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instructorName,
                              style: const TextStyle(
                                color: Color(0xFFB8FF00),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${video!['views'] ?? 0} views • ${_formatDate(video!['createdAt'])}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          _buildActionButton(
                            icon:
                                isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                            label: likesCount.toString(),
                            isActive: isLiked,
                            onTap: _likeVideo,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon:
                                isDisliked
                                    ? Icons.thumb_down
                                    : Icons.thumb_down_outlined,
                            label: dislikesCount.toString(),
                            isActive: isDisliked,
                            onTap: _dislikeVideo,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Enhanced Description Box
                  _buildDescriptionBox(),

                  const SizedBox(height: 24),

                  // Comments Section Header
                  Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${comments.length})',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Enhanced Add Comment Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF404040)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _commentController.clear();
                              },
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _postComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB8FF00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Comment',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Comments List
                  if (isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Color(0xFFB8FF00),
                        ),
                      ),
                    )
                  else if (comments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Column(
                      children:
                          comments
                              .map((comment) => _buildCommentItem(comment))
                              .toList(),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
