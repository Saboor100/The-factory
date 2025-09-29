import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  List<String> _urlsToTry = [];
  int _currentUrlIndex = 0;

  @override
  void initState() {
    super.initState();
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controlsAnimationController);

    _initializeVideo();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controlsAnimationController.dispose();
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

    // Try to get URLs from backend first
    try {
      if (widget.videoId.isNotEmpty) {
        print('Getting streaming URL for video: ${widget.videoId}');
        final response = await VideoApiService.getStreamingUrl(widget.videoId);
        print('Stream URL response: $response');

        if (response is Map) {
          // Add primary URL first
          if (response['streamUrl'] != null &&
              response['streamUrl'].toString().isNotEmpty) {
            _urlsToTry.add(response['streamUrl']);
          }

          // Add alternative URLs in order of compatibility
          if (response['alternativeUrls'] != null) {
            final alternatives = response['alternativeUrls'] as Map;

            // Add most compatible URLs first
            final compatibilityOrder = [
              'compatible', // H.264 baseline
              'mobile', // Mobile optimized
              'lowQuality', // Very low quality
              'simple', // Minimal transformations
              'direct', // No transformations
              'original', // Original upload
              'httpFallback', // HTTP fallback
            ];

            for (final key in compatibilityOrder) {
              final url = alternatives[key];
              if (url != null &&
                  url.toString().isNotEmpty &&
                  !_urlsToTry.contains(url)) {
                _urlsToTry.add(url.toString());
              }
            }

            // Add any remaining URLs
            for (final url in alternatives.values) {
              if (url != null &&
                  url.toString().isNotEmpty &&
                  !_urlsToTry.contains(url)) {
                _urlsToTry.add(url.toString());
              }
            }
          }
        }
      }
    } catch (e) {
      print('Backend streaming URL failed: $e');
    }

    // Add original URL as last fallback if not already added
    if (widget.videoUrl.isNotEmpty && !_urlsToTry.contains(widget.videoUrl)) {
      _urlsToTry.add(widget.videoUrl);
    }

    print('📱 URLs to try (${_urlsToTry.length}):');
    for (int i = 0; i < _urlsToTry.length; i++) {
      print('  ${i + 1}. ${_urlsToTry[i]}');
    }
  }

  List<String> _generateCloudinaryAlternatives(String originalUrl) {
    final alternatives = <String>[];

    try {
      // Parse the URL
      final uri = Uri.parse(originalUrl);
      final path = uri.path;

      if (!path.contains('/video/upload/')) return alternatives;

      // Split to get base and resource
      final parts = path.split('/video/upload/');
      if (parts.length != 2) return alternatives;

      final baseUrl = '${uri.scheme}://${uri.host}${parts[0]}/video/upload';

      // Extract clean resource path
      String resourcePath = parts[1];

      // Remove existing transformations
      final segments = resourcePath.split('/');
      String cleanResourcePath = '';

      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        // Check if this is a version or resource path
        if (segment.startsWith('v') && RegExp(r'^v\d+$').hasMatch(segment)) {
          cleanResourcePath = segments.sublist(i).join('/');
          break;
        } else if (segment.contains('training_videos') ||
            segment.contains('video_') ||
            !segment.contains(',') && !segment.contains('_')) {
          cleanResourcePath = segments.sublist(i).join('/');
          break;
        }
      }

      if (cleanResourcePath.isEmpty) {
        cleanResourcePath = resourcePath;
      }

      // Generate working transformations
      alternatives.addAll([
        // Simple MP4 format
        '$baseUrl/f_mp4/$cleanResourcePath',

        // Lower quality for better compatibility
        '$baseUrl/q_60,f_mp4/$cleanResourcePath',

        // Mobile optimized
        '$baseUrl/c_scale,w_640,f_mp4/$cleanResourcePath',

        // Auto format
        '$baseUrl/f_auto/$cleanResourcePath',

        // Very low quality for testing
        '$baseUrl/q_30,f_mp4/$cleanResourcePath',

        // No transformations
        '$baseUrl/$cleanResourcePath',
      ]);

      // If original had query params, try with them
      if (uri.queryParameters.isNotEmpty) {
        alternatives.add('$baseUrl/f_mp4/$cleanResourcePath?${uri.query}');
      }
    } catch (e) {
      print('⚠️ Error generating alternatives: $e');
    }

    return alternatives;
  }

  Future<void> _tryNextUrl() async {
    if (_currentUrlIndex >= _urlsToTry.length) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Unable to play video after ${_urlsToTry.length} attempts.\n\n'
            'This might be due to:\n'
            '• Device codec compatibility issues\n'
            '• MTK (MediaTek) decoder limitations\n'
            '• H.264 profile not supported\n\n'
            'Try:\n'
            '• Using a different device\n'
            '• Updating your device software\n'
            '• Clearing app cache';
      });
      return;
    }

    final currentUrl = _urlsToTry[_currentUrlIndex];
    print('🎬 Attempting URL ${_currentUrlIndex + 1}/${_urlsToTry.length}');
    print('   $currentUrl');

    // Dispose previous controller
    await _controller?.dispose();
    _controller = null;

    try {
      // Add longer delay between attempts to avoid overwhelming decoder
      if (_currentUrlIndex > 0) {
        await Future.delayed(
          Duration(milliseconds: 2000 + (_currentUrlIndex * 1000)),
        );
      }

      // Create controller with optimized settings for Android
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(currentUrl),
        formatHint: VideoFormat.other, // Let the player decide the best format
        httpHeaders: {
          'User-Agent': 'Flutter-VideoPlayer/1.0 (Mobile App; Android)',
          'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
          'Accept-Encoding': 'identity', // Disable compression
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialize with longer timeout
      await _controller!.initialize().timeout(
        Duration(seconds: 30), // Increased timeout
        onTimeout: () {
          throw Exception('Video loading timeout after 30 seconds');
        },
      );

      if (!mounted) return;

      // Verify initialization success
      if (_controller!.value.hasError || !_controller!.value.isInitialized) {
        throw Exception(
          'Video initialization failed: ${_controller!.value.errorDescription}',
        );
      }

      // Additional validation - check if video duration is available
      if (_controller!.value.duration == Duration.zero) {
        print(
          '⚠️ Warning: Video duration is zero, might indicate codec issues',
        );
      }

      // Success!
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      _controller!.addListener(_videoPlayerListener);
      print('✅ Video loaded successfully with URL ${_currentUrlIndex + 1}');
      print('   Duration: ${_controller!.value.duration}');
      print('   Size: ${_controller!.value.size}');
      print('   Aspect Ratio: ${_controller!.value.aspectRatio}');
    } catch (e) {
      print('❌ URL ${_currentUrlIndex + 1} failed: $e');

      // Log specific error types for debugging
      if (e.toString().contains('PlatformException')) {
        print('🔍 Platform-specific error detected');
      }
      if (e.toString().contains('ExoPlayer')) {
        print('🔍 ExoPlayer error - likely codec incompatibility');
      }
      if (e.toString().contains('OMX')) {
        print('🔍 Hardware decoder error - trying software decoder');
      }

      _currentUrlIndex++;

      // Try next URL
      if (_currentUrlIndex < _urlsToTry.length) {
        await _tryNextUrl();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Unable to play video after ${_urlsToTry.length} attempts.\n\n'
              'Last error: ${e.toString()}\n\n'
              'Your device may not support the video codec used. '
              'This is common on MediaTek (MTK) devices with older Android versions.';
        });
      }
    }
  }

  void _videoPlayerListener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;

    // Handle playback errors
    if (value.hasError && !_hasError) {
      final errorDesc = value.errorDescription ?? 'Unknown playback error';
      print('🔄 Playback error detected: $errorDesc');

      // Try next URL on playback error
      _currentUrlIndex++;
      if (_currentUrlIndex < _urlsToTry.length) {
        print('🔄 Trying next URL due to playback error...');
        _tryNextUrl();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Playback failed: $errorDesc\n\nTried all available video sources.';
        });
      }
      return;
    }

    // Update playing state
    setState(() {
      _isPlaying = value.isPlaying;
    });
  }

  Future<void> _retryInitialization() async {
    _currentUrlIndex = 0;
    await _initializeVideo();
  }

  void _startControlsTimer() {
    _controlsAnimationController.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        _controlsAnimationController.reverse();
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        _startControlsTimer();
      }
    });
  }

  void _toggleControls() {
    if (_showControls) {
      _controlsAnimationController.reverse();
    } else {
      _controlsAnimationController.forward();
      if (_isPlaying) {
        _startControlsTimer();
      }
    }
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  // ... rest of your build method remains the same ...

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar:
            _isFullscreen
                ? null
                : AppBar(
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

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar:
            _isFullscreen
                ? null
                : AppBar(
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
      appBar:
          _isFullscreen
              ? null
              : AppBar(
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
          // Video Player
          Expanded(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Video
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),

                  // Controls Overlay
                  AnimatedBuilder(
                    animation: _controlsAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _controlsAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Top Controls
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    if (_isFullscreen)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    Expanded(
                                      child: Text(
                                        widget.videoTitle,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isFullscreen
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                        color: Colors.white,
                                      ),
                                      onPressed: _toggleFullscreen,
                                    ),
                                  ],
                                ),
                              ),

                              // Center Play/Pause Button
                              Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Bottom Controls
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Progress Bar
                                    VideoProgressIndicator(
                                      _controller!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Color(0xFFB8FF00),
                                        bufferedColor: Colors.white38,
                                        backgroundColor: Colors.white24,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Time and Actions
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(
                                            _controller!.value.position,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Text(
                                          ' / ',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(
                                            _controller!.value.duration,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          if (!_isFullscreen)
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
                        widget.isLiked
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
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
