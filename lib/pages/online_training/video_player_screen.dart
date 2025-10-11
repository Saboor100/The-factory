import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:the_factory/services/video_api_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String videoId;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool isLiked;
  final bool isDisliked;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.videoId,
    this.onLike,
    this.onDislike,
    this.isLiked = false,
    this.isDisliked = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<String> _urlsToTry = [];
  int _currentUrlIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _errorMessage = '';
    });

    try {
      await _prepareVideoUrls();
      await _tryNextUrl();
    } catch (e) {
      print('Video initialization error: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize video: ${e.toString()}';
      });
    }
  }

  Future<void> _prepareVideoUrls() async {
    _urlsToTry.clear();
    _currentUrlIndex = 0;

    try {
      if (widget.videoId.isNotEmpty) {
        print('Getting streaming URL for video: ${widget.videoId}');
        final response = await VideoApiService.getStreamingUrl(widget.videoId);
        print('Stream URL response: $response');

        if (response is Map) {
          if (response['streamUrl'] != null) {
            _urlsToTry.add(response['streamUrl']);
          }

          if (response['alternativeUrls'] != null) {
            final alternatives = response['alternativeUrls'] as Map;

            // Priority order: HD -> SD -> Mobile -> Ultra Low
            final qualityOrder = [
              'hd1080', // Try 1080p first
              'hd720', // Then 720p
              'sd480', // Then 480p
              'mobile360', // Then 360p
              'ultraLow', // Last resort
            ];

            for (final key in qualityOrder) {
              final url = alternatives[key];
              if (url != null && !_urlsToTry.contains(url)) {
                _urlsToTry.add(url.toString());
              }
            }
          }
        }
      }
    } catch (e) {
      print('Backend streaming URL failed: $e');
    }

    if (widget.videoUrl.isNotEmpty && !_urlsToTry.contains(widget.videoUrl)) {
      _urlsToTry.add(widget.videoUrl);
    }

    print('📱 URLs to try (${_urlsToTry.length}):');
    for (int i = 0; i < _urlsToTry.length; i++) {
      print('  ${i + 1}. ${_urlsToTry[i]}');
    }
  }

  Future<void> _tryNextUrl() async {
    if (_currentUrlIndex >= _urlsToTry.length) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Unable to play video after ${_urlsToTry.length} attempts.\n\n'
            'This might be due to:\n'
            '• Network connectivity issues\n'
            '• Video format compatibility\n'
            '• Device codec support\n\n'
            'Please try again or contact support.';
      });
      return;
    }

    final currentUrl = _urlsToTry[_currentUrlIndex];
    print('🎬 Attempting URL ${_currentUrlIndex + 1}/${_urlsToTry.length}');
    print('   $currentUrl');

    // Dispose previous controllers
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    try {
      if (_currentUrlIndex > 0) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Create video player controller
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(currentUrl),
        httpHeaders: {
          'User-Agent': 'Flutter-VideoPlayer/1.0 (Mobile App; Android)',
          'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialize video player
      await _videoPlayerController!.initialize();

      if (!mounted) return;

      // Check if initialization was successful
      if (_videoPlayerController!.value.hasError) {
        throw Exception(
          'Video player error: ${_videoPlayerController!.value.errorDescription}',
        );
      }

      // Create Chewie controller with custom controls
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFB8FF00),
          handleColor: const Color(0xFFB8FF00),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFB8FF00)),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Playback Error',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Add listener for errors during playback
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError && !_hasError) {
          print('❌ Playback error detected');
          _handlePlaybackError();
        }
      });

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      print('✅ Video loaded successfully with URL ${_currentUrlIndex + 1}');
      print('   Duration: ${_videoPlayerController!.value.duration}');
      print('   Size: ${_videoPlayerController!.value.size}');
    } catch (e) {
      print('❌ URL ${_currentUrlIndex + 1} failed: $e');

      _currentUrlIndex++;

      if (_currentUrlIndex < _urlsToTry.length && mounted) {
        await _tryNextUrl();
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'Unable to play video after ${_urlsToTry.length} attempts.\n\n'
                'Last error: ${e.toString()}\n\n'
                'Please check your internet connection and try again.';
          });
        }
      }
    }
  }

  void _handlePlaybackError() {
    if (!_hasError && mounted) {
      print('🔄 Playback error detected, trying next URL...');
      _currentUrlIndex++;
      if (_currentUrlIndex < _urlsToTry.length) {
        _tryNextUrl();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Playback failed after trying all available video sources.';
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    _currentUrlIndex = 0;
    await _initializeVideo();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.videoTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to play video',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8FF00),
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tried ${_currentUrlIndex} of ${_urlsToTry.length} URLs',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.videoTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFB8FF00)),
              const SizedBox(height: 16),
              const Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Trying source ${_currentUrlIndex + 1} of ${_urlsToTry.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.videoTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Video Player with Chewie
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child:
                    _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                          aspectRatio:
                              _videoPlayerController!.value.aspectRatio,
                          child: Chewie(controller: _chewieController!),
                        )
                        : const CircularProgressIndicator(
                          color: Color(0xFFB8FF00),
                        ),
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              border: Border(
                top: BorderSide(color: const Color(0xFF404040), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.videoTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon:
                      widget.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  isActive: widget.isLiked,
                  onTap: widget.onLike,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon:
                      widget.isDisliked
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                  isActive: widget.isDisliked,
                  onTap: widget.onDislike,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB8FF00) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFB8FF00) : const Color(0xFF404040),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}
