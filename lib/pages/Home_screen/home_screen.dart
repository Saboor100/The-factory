import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_factory/services/auth_service.dart';
import 'package:the_factory/services/feed_service.dart';
import 'package:the_factory/providers/profile_provider.dart';
import 'widgets/create_post_card.dart';
import 'widgets/featured_training_videos.dart';
import 'widgets/featured_events.dart';
import 'widgets/user_post_card.dart';
import 'drawer_widget/hamburger.dart';

class FactoryFeedScreen extends StatefulWidget {
  const FactoryFeedScreen({Key? key}) : super(key: key);

  @override
  State<FactoryFeedScreen> createState() => FactoryFeedScreenState();
}

class FactoryFeedScreenState extends State<FactoryFeedScreen> {
  final FeedService _feedService = FeedService();

  List<Map<String, dynamic>> featuredVideos = [];
  List<Map<String, dynamic>> featuredEvents = [];
  List<Map<String, dynamic>> userPosts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
      loadFeedData();
    });
  }

  Future<void> loadFeedData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔄 Loading feed data...');

      final videos = await _feedService.getFeaturedVideos(limit: 3);
      final events = await _feedService.getFeaturedEvents(limit: 2);
      final feed = await _feedService.getFeed(page: 1, limit: 10);

      print('✅ Featured Videos: ${videos.length}');
      print('✅ Featured Events: ${events.length}');
      print('✅ User Posts: ${(feed['data'] as List).length}');

      setState(() {
        featuredVideos = videos;
        featuredEvents = events;
        userPosts = List<Map<String, dynamic>>.from(feed['data'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading feed data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load feed. Pull to refresh.';
      });
    }
  }

  void _navigateToTrainingVideos() {
    Navigator.pushNamed(context, '/training');
  }

  void _navigateToEvents() {
    Navigator.pushNamed(context, '/events');
  }

  void _toggleLike(int index) {
    setState(() {
      userPosts[index]['isLiked'] = !(userPosts[index]['isLiked'] ?? false);
    });
  }

  void _showComments(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comments - Coming Soon!'),
        backgroundColor: Color(0xFF2A2A2A),
      ),
    );
  }

  void _sharePost(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share - Coming Soon!'),
        backgroundColor: Color(0xFF2A2A2A),
      ),
    );
  }

  void _handleDrawerOptionTap(String option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$option - Coming Soon!'),
        backgroundColor: const Color(0xFFB8FF00),
      ),
    );
  }

  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final month = DateFormat('MMM').format(date).toUpperCase();
      final day = date.day.toString();
      return '$month\n$day';
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final avatarUrl = profileProvider.profile?.avatar?.url;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          drawer: FactoryDrawer(onOptionTap: _handleDrawerOptionTap),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Home',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
          ),
          body:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
                  )
                  : RefreshIndicator(
                    onRefresh: loadFeedData,
                    color: const Color(0xFFB8FF00),
                    child: _buildFeedContent(avatarUrl),
                  ),
        );
      },
    );
  }

  Widget _buildFeedContent(String? avatarUrl) {
    List<Widget> feedItems = [];

    feedItems.add(CreatePostCard(avatarUrl: avatarUrl));

    if (featuredVideos.isNotEmpty) {
      feedItems.add(
        FeaturedTrainingVideos(
          videos: featuredVideos,
          onViewAll: _navigateToTrainingVideos,
          formatDuration: _formatDuration,
        ),
      );
    }

    if (featuredEvents.isNotEmpty) {
      feedItems.add(
        FeaturedEvents(
          events: featuredEvents,
          onViewAll: _navigateToEvents,
          formatDate: _formatEventDate,
        ),
      );
    }

    if (userPosts.isNotEmpty) {
      for (var i = 0; i < userPosts.length; i++) {
        feedItems.add(
          UserPostCard(
            data: userPosts[i],
            index: i,
            onLike: () => _toggleLike(i),
            onComment: () => _showComments(i),
            onShare: () => _sharePost(i),
            onPostDeleted: () {},
          ),
        );
      }
    } else if (!isLoading) {
      feedItems.add(
        const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No posts yet.\nBe the first to post!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      feedItems.insert(
        0,
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: feedItems.length,
      itemBuilder: (context, index) => feedItems[index],
    );
  }
}
