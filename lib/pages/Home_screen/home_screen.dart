import 'dart:math';
import 'package:flutter/material.dart';
import '../Home_screen/drawer_widget/hamburger.dart';
import 'package:the_factory/services/auth_service.dart';
import 'package:the_factory/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FactoryFeedScreen extends StatefulWidget {
  FactoryFeedScreen({Key? key}) : super(key: key);

  @override
  State<FactoryFeedScreen> createState() => _FactoryFeedScreenState();
}

class _FactoryFeedScreenState extends State<FactoryFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  // Dummy data for user posts
  final List<Map<String, dynamic>> userPosts = List.generate(
    10,
    (i) => {
      'username': 'User${i + 1}',
      'avatar': 'https://i.pravatar.cc/150?img=${i + 10}',
      'image': 'https://picsum.photos/seed/post$i/400/250',
      'caption':
          'Great day on the field! Working on my skills #training #lacrosse',
      'time': '${i + 1}h',
      'likes': Random().nextInt(50) + 10,
      'comments': Random().nextInt(15) + 1,
      'isLiked': false,
    },
  );

  // User stories data
  final List<Map<String, String>> userStories = [
    {
      'username': 'Your Story',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isOwn': 'true',
    },
    {
      'username': 'CoachMike',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'isOwn': 'false',
    },
    {
      'username': 'TeamCaptain',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isOwn': 'false',
    },
    {
      'username': 'ProPlayer',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'isOwn': 'false',
    },
    {
      'username': 'Teammate1',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'isOwn': 'false',
    },
    {
      'username': 'Teammate2',
      'avatar': 'https://i.pravatar.cc/150?img=6',
      'isOwn': 'false',
    },
  ];

  // Training videos data
  final List<Map<String, dynamic>> featuredTrainingVideos = [
    {
      'title': 'Quick Hands Drill',
      'subtitle': 'Hand Speed',
      'price': 'FREE',
      'image': 'https://picsum.photos/seed/video1/400/300',
      'duration': '3:45',
    },
    {
      'title': 'Shooting Technique',
      'subtitle': 'Shooting',
      'price': null,
      'image': 'https://picsum.photos/seed/video2/400/300',
      'duration': '5:20',
    },
    {
      'title': 'Defensive Stance',
      'subtitle': 'Defense',
      'price': 'PREMIUM',
      'image': 'https://picsum.photos/seed/video3/400/300',
      'duration': '4:15',
    },
  ];

  // Events data
  final List<Map<String, dynamic>> events = [
    {
      'title': 'Elite Camp',
      'date': 'JUN\n20',
      'location': 'Baltimore, MD',
      'type': 'National',
      'price': '\$250',
      'discountPrice': '\$20',
    },
    {
      'title': 'Summer League',
      'date': 'JUL\n15',
      'location': 'New York, NY',
      'type': 'Regional',
      'price': '\$150',
      'discountPrice': null,
    },
  ];

  // Reduced ads data
  final List<Map<String, String>> ads = [
    {
      'image': 'https://picsum.photos/seed/ad1/300/150',
      'title': 'New Sports Gear!',
      'subtitle': 'Premium equipment',
      'button': 'Shop Now',
      'brand': 'SportsPro',
    },
    {
      'image': 'https://picsum.photos/seed/ad2/300/150',
      'title': 'Elite Training',
      'subtitle': 'Upgrade your game',
      'button': 'Learn More',
      'brand': 'TrainingMax',
    },
  ];

  void _navigateToTrainingVideos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Training Videos screen - Coming Soon!'),
        backgroundColor: Color(0xFFB8FF00),
      ),
    );
  }

  void _navigateToEvents() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Events screen - Coming Soon!'),
        backgroundColor: Color(0xFFB8FF00),
      ),
    );
  }

  void _createPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create Post - Coming Soon!'),
        backgroundColor: Color(0xFFB8FF00),
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      userPosts[index]['isLiked'] = !userPosts[index]['isLiked'];
      if (userPosts[index]['isLiked']) {
        userPosts[index]['likes']++;
      } else {
        userPosts[index]['likes']--;
      }
    });
  }

  void _showComments(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comments for ${userPosts[index]['username']}\'s post'),
        backgroundColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  void _sharePost(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${userPosts[index]['username']}\'s post'),
        backgroundColor: const Color(0xFF2A2A2A),
      ),
    );
  }

  // Handle drawer option taps
  void _handleDrawerOptionTap(String option) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$option - Coming Soon!'),
        backgroundColor: const Color(0xFFB8FF00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final avatarUrl = profileProvider.profile?.avatar?.url;

        List<Widget> feedItems = [];

        feedItems.add(CreatePostCard(avatarUrl: avatarUrl));

        feedItems.add(
          _FeaturedTrainingVideos(
            videos: featuredTrainingVideos,
            onViewAll: _navigateToTrainingVideos,
          ),
        );

        feedItems.add(
          _FeaturedEvents(events: events, onViewAll: _navigateToEvents),
        );

        int adIndex = 0;
        for (int i = 0; i < userPosts.length; i++) {
          feedItems.add(
            _UserPostCard(
              data: userPosts[i],
              index: i,
              onLike: () => _toggleLike(i),
              onComment: () => _showComments(i),
              onShare: () => _sharePost(i),
            ),
          );

          if ((i + 1) % 5 == 0 && adIndex < ads.length) {
            feedItems.add(_CompactAdCard(data: ads[adIndex]));
            adIndex++;
          }
        }

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
          body: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: feedItems.length,
            itemBuilder: (context, index) => feedItems[index],
          ),
        );
      },
    );
  }
}

// FactoryDrawer widget - add this to your file or import it
class FactoryDrawer extends StatelessWidget {
  final void Function(String)? onOptionTap;
  const FactoryDrawer({Key? key, this.onOptionTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Drawer(
      backgroundColor: const Color(0xFF232723),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF232723)),
              child: Center(
                child: Text(
                  'The Factory',
                  style: TextStyle(
                    color: Color(0xFFB8FF00),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _DrawerOption(
              icon: Icons.person_outline,
              label: 'Manage Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _DrawerOption(
              icon: Icons.event_note_outlined,
              label: 'Events',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/events');
              },
            ),
            _DrawerOption(
              icon: Icons.play_circle_outline,
              label: 'Online Training',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/training');
              },
            ),
            _DrawerOption(
              icon: Icons.shopping_bag_outlined,
              label: 'Apparel Sales',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/store');
              },
            ),
            _DrawerOption(
              icon: Icons.logout_outlined,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _showLogoutDialog(context, authService);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '© 2024 The Factory',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                // Clean up profile and prefs before dismissing the dialog
                final profileProvider = Provider.of<ProfileProvider>(
                  context,
                  listen: false,
                );
                await profileProvider.clearCache();
                profileProvider.clearProfile();

                // THEN close dialog
                navigator.pop(); // Close logout confirmation dialog

                // NOW perform logout + navigate
                await authService.logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8FF00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFB8FF00)),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// User Stories Section (Instagram-style)
class CreatePostCard extends StatelessWidget {
  final String? avatarUrl;
  const CreatePostCard({Key? key, this.avatarUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232723),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ INSTANT Profile Avatar with caching
          _buildProfileAvatar(),
          const SizedBox(width: 12),
          // Hint text
          Expanded(
            child: Text(
              "What's on your mind?",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15.5,
              ),
            ),
          ),
          // Image icon
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: Color(0xFFB8FF00),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (avatarUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder:
            (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider, radius: 20),
        placeholder:
            (context, url) => const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF3A3A3A),
              child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
            ),
        errorWidget:
            (context, url, error) => const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF3A3A3A),
              child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
            ),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }

    // Fallback for when no avatar URL
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Color(0xFF3A3A3A),
      child: Icon(Icons.person, color: Color(0xFFB8FF00), size: 24),
    );
  }
}

// Featured Events Section
class _FeaturedEvents extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onViewAll;

  const _FeaturedEvents({required this.events, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPCOMING EVENTS',
                style: TextStyle(
                  color: Color(0xFFB8FF00),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8FF00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.black, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder:
                (context, index) => _HorizontalEventCard(data: events[index]),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Horizontal Event Card
class _HorizontalEventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HorizontalEventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3A3A),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                data['date']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB8FF00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['location']!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    data['type']!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data['discountPrice'] != null) ...[
                  Text(
                    data['price']!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    data['discountPrice']!,
                    style: const TextStyle(
                      color: Color(0xFFB8FF00),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Text(
                    data['price']!,
                    style: const TextStyle(
                      color: Color(0xFFB8FF00),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Featured Training Videos Section
class _FeaturedTrainingVideos extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onViewAll;

  const _FeaturedTrainingVideos({
    required this.videos,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRAINING VIDEOS',
                style: TextStyle(
                  color: Color(0xFFB8FF00),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8FF00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.black, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: videos.length,
            itemBuilder:
                (context, index) => _HorizontalVideoCard(data: videos[index]),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Horizontal Video Card (unchanged)
class _HorizontalVideoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HorizontalVideoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    data['image']!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data['duration']!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                if (data['price'] != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            data['price'] == 'FREE'
                                ? const Color(0xFFB8FF00)
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['price']!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data['subtitle']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// User Post Card (unchanged from previous version)
class _UserPostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _UserPostCard({
    required this.data,
    required this.index,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(data['avatar']!),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['username']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        data['time']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, color: Colors.grey.shade400),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              data['image']!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['caption']!,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            data['isLiked']
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                data['isLiked']
                                    ? Colors.red
                                    : const Color(0xFFB8FF00),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${data['likes']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: onComment,
                      child: Row(
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${data['comments']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: onShare,
                      child: Icon(
                        Icons.share_outlined,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
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
}

// Compact Ad Card (smaller, better design)
class _CompactAdCard extends StatelessWidget {
  final Map<String, String> data;
  const _CompactAdCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Row(
        children: [
          // Ad image (smaller)
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Image.network(
              data['image']!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data['brand']!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['subtitle']!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // CTA Button (smaller)
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                elevation: 0,
                minimumSize: Size.zero,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening ${data['brand']} store...'),
                    backgroundColor: const Color(0xFFB8FF00),
                  ),
                );
              },
              child: Text(
                data['button']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
