import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_player_screen.dart';
import 'package:the_factory/services/video_api_service.dart';
import 'package:the_factory/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:the_factory/providers/user_provider.dart';
import 'dart:convert';

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
  bool isProcessingPayment = false;
  bool isAuthenticated = false;
  String? userId;
  String? authToken;
  int likesCount = 0;
  int dislikesCount = 0;
  bool isDescriptionExpanded = false;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    video = widget.videoData;
    _checkAuthentication();
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

  Future<void> _checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = prefs.getKeys();
      print('🔍 ALL SharedPreferences keys: $keys');

      final token = prefs.getString('x-auth-token');
      final uid = prefs.getString('userId');
      final userData = prefs.getString('user-data');

      print('🔐 Auth Debug Info:');
      print('   Token exists: ${token != null}');
      print('   Token value: ${token?.substring(0, 20) ?? 'null'}...');
      print('   UserId exists: ${uid != null}');
      print('   UserId value: $uid');
      print('   UserData exists: ${userData != null}');

      String? extractedUserId = uid;
      if (extractedUserId == null && userData != null) {
        try {
          final userJson = json.decode(userData);
          extractedUserId = userJson['_id'] ?? userJson['id'];
          if (extractedUserId != null) {
            await prefs.setString('userId', extractedUserId);
            print('   ✅ Extracted userId from user-data: $extractedUserId');
          }
        } catch (e) {
          print('   ❌ Failed to extract userId: $e');
        }
      }

      setState(() {
        isAuthenticated = token != null && extractedUserId != null;
        authToken = token;
        userId = extractedUserId;
      });

      print(
        '🔐 Final Auth Status: ${isAuthenticated ? "Logged In" : "Not Logged In"}',
      );
    } catch (e) {
      print('❌ Auth check error: $e');
      setState(() {
        isAuthenticated = false;
      });
    }
  }

  void _initializeVideoState() {
    if (video != null) {
      likesCount = video!['likes'] ?? 0;
      dislikesCount = video!['dislikes'] ?? 0;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.user.id;

      print('Initializing video state for user: $currentUserId');
      print('Video likes data: ${video!['likedBy']}');
      print('Video dislikes data: ${video!['dislikedBy']}');

      if (video!['likedBy'] != null) {
        if (video!['likedBy'] is List) {
          isLiked = (video!['likedBy'] as List).any(
            (id) => id.toString() == currentUserId,
          );
        }
      }

      if (video!['dislikedBy'] != null) {
        if (video!['dislikedBy'] is List) {
          isDisliked = (video!['dislikedBy'] as List).any(
            (id) => id.toString() == currentUserId,
          );
        }
      }

      print('Is liked: $isLiked, Is disliked: $isDisliked');
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

    if (!isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (isLoadingComments) return;

    setState(() {
      isLoadingComments = true;
    });

    try {
      final response = await VideoApiService.addComment(
        widget.videoId,
        commentText,
      );
      if (response['success']) {
        _commentController.clear();
        await _loadComments();
        _showSuccessSnackBar('Comment added successfully!');
      } else {
        _showErrorSnackBar('Failed to add comment');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add comment: $e');
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final response = await VideoApiService.deleteComment(
        widget.videoId,
        commentId,
      );
      if (response['success'] == true) {
        await _loadComments();
        _showSuccessSnackBar('Comment deleted successfully!');
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      print('Delete comment error: $e');
      _showErrorSnackBar('Failed to delete comment');
    }
  }

  void _showDeleteCommentDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Comment',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this comment?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteComment(commentId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _likeVideo() async {
    if (!isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

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
    if (!isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFB8FF00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8FF00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.login,
                    color: Color(0xFFB8FF00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Login Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'You need to be logged in to access this feature.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  void _showPaymentDialog() {
    final double price = (video!['price'] ?? 0).toDouble();
    final String title = video!['title'] ?? 'Video';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Premium Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase "$title" to watch',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price:',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '✓ Lifetime access\n✓ Watch anytime\n✓ HD quality',
                  style: TextStyle(
                    color: Color(0xFFB8FF00),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _processVideoPayment(price);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Purchase Now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _processVideoPayment(double amount) async {
    if (!isAuthenticated || authToken == null || userId == null) {
      _showErrorSnackBar('Please login to purchase videos');
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      print('💳 Starting payment process...');
      print('   Video ID: ${widget.videoId}');
      print('   Amount: \$${amount.toStringAsFixed(2)}');
      print('   User ID: $userId');

      final bool success = await PaymentService.processVideoPayment(
        videoId: widget.videoId,
        amount: amount,
        videoTitle: video!['title'] ?? 'Video',
        userId: userId!,
        token: authToken!,
      );

      setState(() {
        isProcessingPayment = false;
      });

      if (success) {
        print('✅ Payment successful!');
        _showSuccessDialog();
        await _loadVideoDetails();
      } else {
        print('❌ Payment failed');
        _showErrorSnackBar(
          'Payment was cancelled or failed. Please try again.',
        );
      }
    } catch (e) {
      print('❌ Payment error: $e');
      setState(() {
        isProcessingPayment = false;
      });
      _showErrorSnackBar('Payment error: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFFB8FF00), size: 32),
                SizedBox(width: 12),
                Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: const Text(
              'You now have lifetime access to this video.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _watchVideo();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8FF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Watch Now',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isActive
                  ? (activeColor ?? const Color(0xFFB8FF00))
                  : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
        comment['user']?['avatar']?['url'] ??
        comment['user']?['profilePicture'] ??
        '';

    final String commentText = comment['comment'] ?? '';
    final String timeAgo = _formatDate(comment['createdAt']);
    final String commentId = comment['_id'] ?? '';
    final String commentUserId = comment['user']?['_id'] ?? '';

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserId = userProvider.user.id;
    final bool isOwnComment = commentUserId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A2A2A),
            child:
                userAvatar.isNotEmpty
                    ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userAvatar,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        placeholder:
                            (context, url) => const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFB8FF00),
                            ),
                        errorWidget: (context, url, error) {
                          return const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 18,
                          );
                        },
                      ),
                    )
                    : const Icon(Icons.person, color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                color: Color(0xFFB8FF00),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $timeAgo',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwnComment)
                      GestureDetector(
                        onTap: () => _showDeleteCommentDialog(commentId),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  commentText,
                  style: const TextStyle(
                    color: Colors.white,
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
  }

  Widget _buildDescriptionBox() {
    final description = video!['description'] ?? 'No description available';
    final shouldShowReadMore = description.length > 150;
    final category = video!['category'] ?? 'Training';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFB8FF00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Description',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCrossFade(
            firstChild: Text(
              description.length > 150
                  ? '${description.substring(0, 150)}...'
                  : description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            secondChild: Text(
              description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            crossFadeState:
                isDescriptionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (shouldShowReadMore) ...[
            const SizedBox(height: 10),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (video!['tags'] != null && video!['tags'].isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.from(
                video!['tags'].map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
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

  void _watchVideo() {
    if (video == null) return;

    final bool isPremium = video!['isPremium'] ?? false;

    // Check authentication first
    if (!isAuthenticated && isPremium) {
      _showLoginRequiredDialog();
      return;
    }

    // Check access for premium videos
    if (isPremium) {
      final userAccess = video!['userAccess'];

      if (userAccess != null) {
        final bool hasAccess = userAccess['hasAccess'] ?? false;
        final bool requiresPayment = userAccess['requiresPayment'] ?? false;

        print('📊 Video Access Status:');
        print('   isPremium: $isPremium');
        print('   hasAccess: $hasAccess');
        print('   requiresPayment: $requiresPayment');

        if (!hasAccess && requiresPayment) {
          _showPaymentDialog();
          return;
        }
      }
    }

    // User has access or video is free - play video
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
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (video == null) return const SizedBox();

    final bool isPremium = video!['isPremium'] ?? false;
    final String thumbnailUrl = video!['thumbnailUrl'] ?? '';

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
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: Icon(
                              Icons.video_library,
                              color: Colors.white30,
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
                          Colors.black.withOpacity(0.2),
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
                      onTap: isProcessingPayment ? null : _watchVideo,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                        ),
                        child:
                            isProcessingPayment
                                ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                                : const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 40,
                                ),
                      ),
                    ),
                  ),

                  // Premium badge
                  if (isPremium)
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
                              '${(video!['price'] ?? 0).toDouble().toStringAsFixed(2)}',
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Title
                  Text(
                    video!['title'] ?? 'Untitled Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Video Stats Row
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${video!['viewCount'] ?? 0} views',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '• ${_formatDate(video!['createdAt'])}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon:
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
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
                        activeColor: const Color(0xFF666666),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description Box
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${comments.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Add Comment Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
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
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  isLoadingComments ? null : _postComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB8FF00),
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: const Color(
                                  0xFF2A2A2A,
                                ),
                                disabledForegroundColor: Colors.white38,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                              child:
                                  isLoadingComments
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white38,
                                        ),
                                      )
                                      : const Text(
                                        'Comment',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Comments List
                  if (isLoadingComments && comments.isEmpty)
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
