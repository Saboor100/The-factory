import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:the_factory/services/feed_service.dart';
import 'package:provider/provider.dart';
import 'package:the_factory/providers/user_provider.dart';

class UserPostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onPostDeleted;

  const UserPostCard({
    Key? key,
    required this.data,
    required this.index,
    required this.onPostDeleted,
    required void Function() onShare,
    required void Function() onComment,
    required void Function() onLike,
  }) : super(key: key);

  @override
  State<UserPostCard> createState() => _UserPostCardState();
}

class _UserPostCardState extends State<UserPostCard>
    with SingleTickerProviderStateMixin {
  final FeedService _feedService = FeedService();
  late bool isLiked;
  late int likesCount;
  late int commentsCount;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.data['isLiked'] ?? false;
    likesCount = (widget.data['likes'] as List?)?.length ?? 0;
    commentsCount = (widget.data['comments'] as List?)?.length ?? 0;

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      isLiked = !isLiked;
      likesCount = isLiked ? likesCount + 1 : likesCount - 1;
    });

    if (isLiked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }

    try {
      final postId = widget.data['_id'];
      final result = await _feedService.toggleLike(postId);

      if (!result['success']) {
        setState(() {
          isLiked = !isLiked;
          likesCount = isLiked ? likesCount + 1 : likesCount - 1;
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      setState(() {
        isLiked = !isLiked;
        likesCount = isLiked ? likesCount + 1 : likesCount - 1;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleComment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CommentsBottomSheet(
            postId: widget.data['_id'],
            onCommentAdded: () {
              setState(() {
                commentsCount++;
              });
            },
          ),
    );
  }

  void _showLikes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LikesBottomSheet(postId: widget.data['_id']),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final postId = widget.data['_id'];
        final result = await _feedService.deletePost(postId);

        if (result['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Color(0xFFB8FF00),
            ),
          );
          widget.onPostDeleted();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTimeAgo(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  bool _isCurrentUserPost(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.user.id;
    final postUserId = widget.data['user']?['_id'];
    return currentUserId == postUserId;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.data['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;
    final avatar = profile?['avatar'] as Map<String, dynamic>?;
    final avatarUrl = avatar?['url'] ?? '';
    final username = profile?['fullName'] ?? user?['name'] ?? 'Unknown User';
    final imageUrl = widget.data['imageUrl'] ?? '';
    final caption = widget.data['caption'] ?? '';
    final createdAt = widget.data['createdAt'] ?? '';
    final isMyPost = _isCurrentUserPost(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF232723),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(username, avatarUrl, createdAt, isMyPost),
          if (caption.isNotEmpty) _buildCaption(caption),
          if (imageUrl.isNotEmpty) _buildImage(imageUrl),
          _buildActionBar(),
          if (likesCount > 0) _buildLikesPreview(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String username,
    String avatarUrl,
    String createdAt,
    bool isMyPost,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMyPost)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleDelete,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder:
            (context, imageProvider) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB8FF00), width: 2.5),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB8FF00).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        placeholder: (context, url) => _buildDefaultAvatar(isLoading: true),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar({bool isLoading = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3A3A3A),
        border: Border.all(color: const Color(0xFFB8FF00), width: 2.5),
      ),
      child:
          isLoading
              ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Color(0xFFB8FF00),
                    strokeWidth: 2,
                  ),
                ),
              )
              : const Icon(
                Icons.person_rounded,
                color: Color(0xFFB8FF00),
                size: 24,
              ),
    );
  }

  Widget _buildCaption(String caption) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        caption,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheWidth: 1080,
        maxWidthDiskCache: 1080,
        placeholder:
            (context, url) => Container(
              height: 400,
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB8FF00),
                  strokeWidth: 2.5,
                ),
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              height: 400,
              color: const Color(0xFF1A1A1A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white.withOpacity(0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildLikeButton(),
          const SizedBox(width: 20),
          _buildCommentButton(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLikeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleLike,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _likeScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _likeScaleAnimation.value,
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? const Color(0xFFB8FF00) : Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleComment,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                commentsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikesPreview() {
    final likes = widget.data['likes'] as List? ?? [];

    if (likes.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showLikes,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchLikesPreview(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildLikesText(likes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildLikesText(likes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }

            final likesData = snapshot.data!;
            final displayCount = likesData.length > 3 ? 3 : likesData.length;

            return Row(
              children: [
                // Display up to 3 overlapping profile pictures
                SizedBox(
                  height: 28,
                  width: displayCount * 20.0 + 8,
                  child: Stack(
                    children: List.generate(displayCount, (index) {
                      final like = likesData[index];
                      final user = like['user'] as Map<String, dynamic>?;
                      final profile = user?['profile'] as Map<String, dynamic>?;
                      final avatar =
                          profile?['avatar'] as Map<String, dynamic>?;
                      final avatarUrl = avatar?['url'] ?? '';

                      return Positioned(
                        left: index * 20.0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF232723),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF3A3A3A),
                            backgroundImage:
                                avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            child:
                                avatarUrl.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Color(0xFFB8FF00),
                                    )
                                    : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildLikesTextWithNames(likesData),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLikesPreview() async {
    try {
      final result = await _feedService.getLikes(widget.data['_id']);
      if (result['success'] == true) {
        final data = result['data'] as List;
        return data.take(3).map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error fetching likes preview: $e');
    }
    return [];
  }

  String _buildLikesTextWithNames(List<Map<String, dynamic>> likesData) {
    if (likesData.isEmpty) {
      return 'Liked by ${widget.data['likes']?.length ?? 0} ${(widget.data['likes']?.length ?? 0) == 1 ? 'person' : 'people'}';
    }

    final firstLike = likesData[0];
    final firstUser = firstLike['user'] as Map<String, dynamic>?;
    final firstProfile = firstUser?['profile'] as Map<String, dynamic>?;
    final firstName =
        firstProfile?['fullName'] ?? firstUser?['name'] ?? 'Someone';

    final totalLikes = widget.data['likes']?.length ?? 0;

    if (totalLikes == 1) {
      return 'Liked by $firstName';
    } else if (totalLikes == 2 && likesData.length >= 2) {
      final secondLike = likesData[1];
      final secondUser = secondLike['user'] as Map<String, dynamic>?;
      final secondProfile = secondUser?['profile'] as Map<String, dynamic>?;
      final secondName =
          secondProfile?['fullName'] ?? secondUser?['name'] ?? 'Someone';
      return 'Liked by $firstName and $secondName';
    } else {
      final othersCount = totalLikes - 1;
      return 'Liked by $firstName and $othersCount ${othersCount == 1 ? 'other' : 'others'}';
    }
  }

  String _buildLikesText(List likes) {
    if (likes.isEmpty) return '';

    if (likes.length == 1) {
      return 'Liked by 1 person';
    } else {
      return 'Liked by ${likes.length} people';
    }
  }
}

// Likes Bottom Sheet Widget
class LikesBottomSheet extends StatefulWidget {
  final String postId;

  const LikesBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  final FeedService _feedService = FeedService();
  List<Map<String, dynamic>> likes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() => isLoading = true);
    try {
      final result = await _feedService.getLikes(widget.postId);
      if (result['success'] == true) {
        setState(() {
          likes = List<Map<String, dynamic>>.from(result['data'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading likes: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [_buildHeader(), Expanded(child: _buildLikesList())],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Likes (${likes.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLikesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
      );
    }

    if (likes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No likes yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to like this post!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: likes.length,
      itemBuilder: (context, index) {
        final like = likes[index];
        final user = like['user'] as Map<String, dynamic>?;
        final profile = user?['profile'] as Map<String, dynamic>?;
        final avatar = profile?['avatar'] as Map<String, dynamic>?;
        final avatarUrl = avatar?['url'] ?? '';
        final username = profile?['fullName'] ?? user?['name'] ?? 'Unknown';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF3A3A3A),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child:
                    avatarUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          size: 22,
                          color: Color(0xFFB8FF00),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Comments Bottom Sheet Widget
class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const CommentsBottomSheet({
    Key? key,
    required this.postId,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final FeedService _feedService = FeedService();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => isLoading = true);
    try {
      final result = await _feedService.getComments(widget.postId);
      if (result['success'] == true) {
        setState(() {
          comments = List<Map<String, dynamic>>.from(result['data'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || isSubmitting) return;

    setState(() => isSubmitting = true);

    try {
      final result = await _feedService.addComment(widget.postId, text);
      if (result['success'] == true && mounted) {
        _commentController.clear();
        widget.onCommentAdded();
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _getTimeAgo(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCommentsList()),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
      );
    }

    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final user = comment['user'] as Map<String, dynamic>?;
        final profile = user?['profile'] as Map<String, dynamic>?;
        final avatar = profile?['avatar'] as Map<String, dynamic>?;
        final avatarUrl = avatar?['url'] ?? '';
        final username = profile?['fullName'] ?? user?['name'] ?? 'Unknown';
        final text = comment['comment'] ?? '';
        final timestamp = comment['createdAt'] ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF3A3A3A),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child:
                    avatarUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFFB8FF00),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF232723),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFB8FF00),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: isSubmitting ? null : _submitComment,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                child:
                    isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1A1A1A),
                          ),
                        )
                        : const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF1A1A1A),
                          size: 20,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
