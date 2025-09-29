import 'package:flutter/material.dart';
import 'video_detail_screen.dart';
import 'upload_video_screen.dart';
import 'package:the_factory/services/video_api_service.dart';

class OnlineTrainingScreen extends StatefulWidget {
  const OnlineTrainingScreen({super.key});

  @override
  State<OnlineTrainingScreen> createState() => _OnlineTrainingScreenState();
}

class _OnlineTrainingScreenState extends State<OnlineTrainingScreen> {
  String selectedCategory = 'All';
  List<Map<String, dynamic>> videos = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 1;
  bool hasMoreVideos = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> categories = [
    'All',
    'Hand Speed',
    'General Lacrosse',
    'Shooting',
    'Defense',
    'Goalie',
    'Conditioning',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      hasError = false;
      if (refresh) {
        videos = [];
        currentPage = 1;
        hasMoreVideos = true;
      }
    });

    try {
      final response = await VideoApiService.getVideos(
        category: selectedCategory == 'All' ? null : selectedCategory,
        page: currentPage,
        limit: 10,
      );

      if (response['success']) {
        final List<dynamic> newVideos =
            response['data']; // ✅ It's already a List
        final pagination =
            response['pagination'] ?? {}; // ✅ Moved out of `data`

        setState(() {
          if (refresh) {
            videos = newVideos.cast<Map<String, dynamic>>();
          } else {
            videos.addAll(newVideos.cast<Map<String, dynamic>>());
          }
          hasMoreVideos = pagination['hasNextPage'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = response['message'] ?? 'Failed to load videos';
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

  Future<void> _loadMoreVideos() async {
    if (!hasMoreVideos || isLoading) return;

    currentPage++;
    await _loadVideos();
  }

  Future<void> _refreshVideos() async {
    await _loadVideos(refresh: true);
  }

  void _onCategoryChanged(String category) {
    if (selectedCategory != category) {
      setState(() {
        selectedCategory = category;
        currentPage = 1;
      });
      _loadVideos(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Online Training',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadVideoScreen(),
                ),
              ).then((_) => _refreshVideos());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return GestureDetector(
                  onTap: () => _onCategoryChanged(category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFB8FF00)
                              : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFB8FF00)
                                : const Color(0xFF404040),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Videos List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshVideos,
              color: const Color(0xFFB8FF00),
              backgroundColor: const Color(0xFF2A2A2A),
              child: _buildVideosList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    if (isLoading && videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
      );
    }

    if (hasError && videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load videos',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8FF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: videos.length + (hasMoreVideos ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= videos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
            ),
          );
        }

        final video = videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final bool isFree = !(video['isPremium'] ?? false);
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final String instructorName = video['uploader']?['name'] ?? 'Unknown';
    final String instructorAvatar =
        video['uploader']?['profilePicture'] ??
        'https://i.pravatar.cc/150?u=${video['uploader']?['_id']}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    VideoDetailScreen(videoId: video['_id'], videoData: video),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFree ? const Color(0xFF404040) : const Color(0xFFFFD700),
            width: isFree ? 1.2 : 2.5,
          ),
          boxShadow: [
            if (!isFree)
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      thumbnailUrl.isNotEmpty
                          ? Image.network(
                            thumbnailUrl,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 170,
                                width: double.infinity,
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: Icon(
                                    Icons.video_library,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            height: 170,
                            width: double.infinity,
                            color: const Color(0xFF2A2A2A),
                            child: const Center(
                              child: Icon(
                                Icons.video_library,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.25),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Play icon
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
                // Duration badge
                if (video['duration'] != null)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(video['duration']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                // Free/Premium badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isFree
                              ? const Color(0xFFB8FF00)
                              : const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow:
                          isFree
                              ? []
                              : [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.25),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                    ),
                    child: Row(
                      children: [
                        if (!isFree)
                          const Icon(
                            Icons.workspace_premium,
                            size: 16,
                            color: Colors.black,
                          ),
                        if (!isFree) const SizedBox(width: 4),
                        Text(
                          isFree ? 'FREE' : 'PREMIUM',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Price badge for paid
                if (!isFree && video['price'] != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${video['price'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Video Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? 'Untitled Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video['description'] ?? 'No description available',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(instructorAvatar),
                        radius: 13,
                        onBackgroundImageError: (exception, stackTrace) {},
                        child:
                            instructorAvatar.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white54,
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          instructorName,
                          style: const TextStyle(
                            color: Color(0xFFB8FF00),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // View count and likes
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${video['viewCount'] ?? 0}', // ✅ Fixed: use 'viewCount' instead of 'views'
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.thumb_up,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${video['likes'] ?? 0}', // ✅ Fixed: removed .length since likes is an int
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

  String _formatDuration(dynamic duration) {
    if (duration == null) return '0:00';

    // If duration is already a formatted string
    if (duration is String) return duration;

    // If duration is in seconds
    if (duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    return duration.toString();
  }
}
