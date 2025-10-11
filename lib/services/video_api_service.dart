import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoApiService {
  static const String baseUrl = 'http://192.168.100.16:3000/api';

  // UPDATED: Enhanced streaming URL method with multiple quality options
  static Future<Map<String, dynamic>> getStreamingUrl(String videoId) async {
    try {
      print('Getting streaming URL for video: $videoId');

      final headers = await _getHeaders();
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App; Android)';
      headers['Accept'] = 'application/json';

      // Request Android-compatible streams
      final response = await http.get(
        Uri.parse(
          '$baseUrl/videos/$videoId/stream?quality=compatible&format=mp4&profile=baseline',
        ),
        headers: headers,
      );

      print('Stream URL response status: ${response.statusCode}');
      print('Stream URL response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(
            'Invalid response: ${data['message'] ?? 'No stream URL'}',
          );
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get streaming URL');
      }
    } catch (e) {
      print('Get streaming URL error: $e');
      throw Exception('Failed to get video streaming URL: $e');
    }
  }

  // NEW: Test video URL accessibility
  static Future<Map<String, dynamic>> testVideoUrl(String url) async {
    try {
      print('Testing video URL: $url');

      final headers = await _getHeaders();
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App; Android)';
      headers['Accept'] = 'video/mp4,video/*;q=0.9,*/*;q=0.8';

      final response = await http.post(
        Uri.parse('$baseUrl/videos/test-url'),
        headers: headers,
        body: json.encode({
          'url': url,
          'userAgent': 'Flutter-VideoPlayer/1.0 (Mobile App; Android)',
          'platform': 'android',
          'device': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return {
        'success': false,
        'accessible': false,
        'error': 'Test failed with status: ${response.statusCode}',
      };
    } catch (e) {
      print('URL test error: $e');
      return {'success': false, 'accessible': false, 'error': e.toString()};
    }
  }

  // NEW: Get multiple streaming URLs with quality options
  static Future<Map<String, dynamic>> getStreamingUrls(String videoId) async {
    try {
      print('Getting all streaming URLs for video: $videoId');

      final headers = await _getHeaders();
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App)';

      // Try to get the streaming response with all quality options
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId/stream'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'primary': data['streamUrl'],
            'alternatives': data['alternativeUrls'] ?? {},
            'title': data['title'],
            'duration': data['duration'],
          };
        }
      }

      // Fallback to regular method
      return await getStreamingUrl(videoId);
    } catch (e) {
      print('Get streaming URLs error: $e');
      // Fallback to regular streaming URL
      return await getStreamingUrl(videoId);
    }
  }

  // Add this method to your VideoApiService class

  // Replace the existing deleteComment method in video_api_service.dart with this:

  // Replace the deleteComment method in video_api_service.dart
  static Future<Map<String, dynamic>> deleteComment(
    String videoId,
    String commentId,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication required');

      print('Deleting comment: $commentId from video: $videoId'); // Debug

      final response = await http.delete(
        Uri.parse('$baseUrl/videos/$videoId/comments/$commentId'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );

      print('Delete comment response status: ${response.statusCode}');
      print('Delete comment response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Try to parse JSON, if it fails, return success anyway
        try {
          final data = json.decode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Comment deleted successfully',
          };
        } catch (e) {
          // Response might be empty for 204 or not JSON
          return {'success': true, 'message': 'Comment deleted successfully'};
        }
      } else {
        // Try to parse error message
        try {
          final error = json.decode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Failed to delete comment',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to delete comment: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Delete comment error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // UPDATED: Enhanced mobile compatibility method
  static Future<String> getCompatibleStreamingUrl(String videoId) async {
    try {
      print('Getting mobile-compatible streaming URL for video: $videoId');

      final headers = await _getHeaders();
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App)';
      headers['Accept'] = 'video/mp4,video/*';

      // Request mobile-optimized URL with specific parameters
      final response = await http.get(
        Uri.parse(
          '$baseUrl/videos/$videoId/stream?quality=mobile&format=mp4&codec=h264&profile=baseline',
        ),
        headers: headers,
      );

      print('Compatible stream URL response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Try mobile URL first, then fallback options
          if (data['alternativeUrls'] != null) {
            final alternatives = data['alternativeUrls'] as Map;
            if (alternatives['mobile'] != null) {
              return alternatives['mobile'];
            }
            if (alternatives['standard'] != null) {
              return alternatives['standard'];
            }
          }
          if (data['streamUrl'] != null) {
            return data['streamUrl'];
          }
        }
      }

      // Fallback to regular streaming URL
      final fallbackData = await getStreamingUrl(videoId);
      return fallbackData['streamUrl'] ?? fallbackData.toString();
    } catch (e) {
      print('Get compatible streaming URL error: $e');
      // Final fallback to regular streaming URL
      return await getStreamingUrl(
        videoId,
      ).then((data) => data['streamUrl'] ?? data.toString());
    }
  }

  // NEW: Validate video URL on backend
  static Future<Map<String, dynamic>> validateVideoUrl(String url) async {
    try {
      final headers = await _getHeaders();
      headers['Content-Type'] = 'application/json';
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App)';

      final response = await http.post(
        Uri.parse('$baseUrl/videos/test-url'),
        headers: headers,
        body: json.encode({
          'url': url,
          'userAgent': 'Flutter-VideoPlayer/1.0',
          'platform': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return {
        'success': false,
        'accessible': false,
        'error': 'Validation failed',
      };
    } catch (e) {
      print('URL validation error: $e');
      return {'success': false, 'accessible': false, 'error': e.toString()};
    }
  }

  // Get auth token from shared preferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }

  // UPDATED: Enhanced headers with mobile-specific User-Agent
  static Future<Map<String, String>> _getHeaders({
    bool includeMobileHeaders = true,
  }) async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'x-auth-token': token,
    };

    if (includeMobileHeaders) {
      headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App)';
      headers['Accept'] = 'application/json, video/mp4, video/*';
      headers['Cache-Control'] = 'no-cache';
    }

    return headers;
  }

  // Get all videos with optional filters
  static Future<Map<String, dynamic>> getVideos({
    String? category,
    String? tag,
    bool? isPremium,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (tag != null) queryParams['tag'] = tag;
      if (isPremium != null) queryParams['isPremium'] = isPremium.toString();

      final uri = Uri.parse(
        '$baseUrl/videos',
      ).replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('GET Videos - Status: ${response.statusCode}');
      print('GET Videos - Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load videos: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Get videos error: $e');
      throw Exception('Network error: $e');
    }
  }

  // UPDATED: Enhanced getVideoById with mobile optimization
  static Future<Map<String, dynamic>> getVideoById(String videoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Try to get multiple streaming URL options from backend
        try {
          final streamingData = await getStreamingUrls(videoId);
          data['data']['streamingUrls'] = streamingData;

          // Set primary streaming URL
          if (streamingData['primary'] != null) {
            data['data']['streamingUrl'] = streamingData['primary'];
          }

          // Set alternative URLs
          if (streamingData['alternatives'] != null) {
            data['data']['alternativeUrls'] = streamingData['alternatives'];
          }
        } catch (e) {
          print('Failed to get streaming URLs: $e');
          // Continue with original URL
        }

        return data;
      } else {
        throw Exception('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Upload video with progress tracking - FIXED VERSION
  static Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required File thumbnailFile,
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    required bool isPremium,
    double? price,
    Function(double)? onProgress,
  }) async {
    try {
      print('=== Starting Video Upload ===');

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required - please login again');
      }

      // Validate files exist
      if (!await videoFile.exists()) {
        throw Exception('Video file not found');
      }
      if (!await thumbnailFile.exists()) {
        throw Exception('Thumbnail file not found');
      }

      print('Video file size: ${await videoFile.length()} bytes');
      print('Thumbnail file size: ${await thumbnailFile.length()} bytes');

      final uri = Uri.parse('$baseUrl/videos/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['x-auth-token'] = token;
      request.headers['User-Agent'] = 'Flutter-VideoPlayer/1.0 (Mobile App)';

      // Add video file with explicit content type
      final videoFileName = videoFile.path.split('/').last.toLowerCase();
      String videoContentType = 'video/mp4'; // Default to mp4

      // Determine content type based on file extension
      if (videoFileName.endsWith('.mp4')) {
        videoContentType = 'video/mp4';
      } else if (videoFileName.endsWith('.mov')) {
        videoContentType = 'video/quicktime';
      } else if (videoFileName.endsWith('.avi')) {
        videoContentType = 'video/x-msvideo';
      } else if (videoFileName.endsWith('.webm')) {
        videoContentType = 'video/webm';
      } else if (videoFileName.endsWith('.wmv')) {
        videoContentType = 'video/x-ms-wmv';
      } else if (videoFileName.endsWith('.flv')) {
        videoContentType = 'video/x-flv';
      } else if (videoFileName.endsWith('.mpeg') ||
          videoFileName.endsWith('.mpg')) {
        videoContentType = 'video/mpeg';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          await videoFile.readAsBytes(),
          filename: videoFile.path.split('/').last,
          contentType: MediaType.parse(videoContentType),
        ),
      );

      // Add thumbnail file with explicit content type
      final thumbnailFileName =
          thumbnailFile.path.split('/').last.toLowerCase();
      String thumbnailContentType = 'image/jpeg'; // Default

      if (thumbnailFileName.endsWith('.png')) {
        thumbnailContentType = 'image/png';
      } else if (thumbnailFileName.endsWith('.jpg') ||
          thumbnailFileName.endsWith('.jpeg')) {
        thumbnailContentType = 'image/jpeg';
      } else if (thumbnailFileName.endsWith('.gif')) {
        thumbnailContentType = 'image/gif';
      } else if (thumbnailFileName.endsWith('.webp')) {
        thumbnailContentType = 'image/webp';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'thumbnail',
          await thumbnailFile.readAsBytes(),
          filename: thumbnailFile.path.split('/').last,
          contentType: MediaType.parse(thumbnailContentType),
        ),
      );

      // Add form fields - matching your backend expectations
      request.fields['title'] = title.trim();
      request.fields['description'] = description.trim();
      request.fields['category'] = category;

      // Send tags as comma-separated string (not JSON)
      request.fields['tags'] = tags.join(',');

      request.fields['isPremium'] = isPremium.toString();

      if (price != null && price > 0) {
        request.fields['price'] = price.toString();
      }

      print('Request fields: ${request.fields}');
      print('Video content type: $videoContentType');
      print('Thumbnail content type: $thumbnailContentType');
      print(
        'Request files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.contentType})')}',
      );

      // Send request and get response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Failed to parse response as JSON: ${response.body}');
        throw Exception('Invalid response format from server');
      }

      if (response.statusCode == 201) {
        print('✅ Video uploaded successfully');
        // Call progress callback to indicate completion
        if (onProgress != null) {
          onProgress(1.0);
        }
        return responseData;
      } else {
        final errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            'Upload failed with status ${response.statusCode}';
        print('❌ Upload failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Upload error details: $e');
      rethrow;
    }
  }

  // Like video
  static Future<Map<String, dynamic>> likeVideo(String videoId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/like'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to like video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Dislike video
  static Future<Map<String, dynamic>> dislikeVideo(String videoId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/dislike'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to dislike video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get video comments
  static Future<Map<String, dynamic>> getComments(
    String videoId, {
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId/comments?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add comment
  static Future<Map<String, dynamic>> addComment(
    String videoId,
    String comment,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/comments'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode({'comment': comment}),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get user's videos
  static Future<Map<String, dynamic>> getMyVideos({int page = 1}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.get(
        Uri.parse('$baseUrl/videos/my-videos?page=$page'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load my videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Search videos
  static Future<Map<String, dynamic>> searchVideos(
    String query, {
    int page = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/videos/search?q=${Uri.encodeComponent(query)}&page=$page',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
