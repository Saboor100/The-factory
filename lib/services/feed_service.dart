import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedService {
  static const String baseUrl = '${Constants.uri}/api';

  // Get auth token from shared preferences
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('x-auth-token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Create post with optional multiple images
  Future<Map<String, dynamic>> createPost({
    required String caption,
    List<File>? images, // Changed from File? image to List<File>? images
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('No auth token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('Creating post with caption: $caption');
      print('Images provided: ${images?.length ?? 0}');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/posts'));

      // Add auth header
      request.headers['x-auth-token'] = token;

      // Add caption
      request.fields['caption'] = caption;

      // Add multiple images if provided
      if (images != null && images.isNotEmpty) {
        print('Adding ${images.length} images to request...');
        for (var i = 0; i < images.length; i++) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'images', // Changed field name to 'images' for multiple files
              images[i].path,
            ),
          );
        }
      }

      print('Sending request to: $baseUrl/posts');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Post response status: ${response.statusCode}');
      print('Post response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create post',
        };
      }
    } catch (e) {
      print('Error creating post: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Toggle like on a post
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('No auth token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('Toggling like for post: $postId');

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );

      print('Toggle like response status: ${response.statusCode}');
      print('Toggle like response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to toggle like',
        };
      }
    } catch (e) {
      print('Error toggling like: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Delete a post
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('No auth token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('Deleting post: $postId');

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
      );

      print('Delete post response status: ${response.statusCode}');
      print('Delete post response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete post',
        };
      }
    } catch (e) {
      print('Error deleting post: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Add comment to a post
  Future<Map<String, dynamic>> addComment(String postId, String comment) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        print('No auth token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('Adding comment to post: $postId');

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode({'comment': comment}),
      );

      print('Add comment response status: ${response.statusCode}');
      print('Add comment response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to add comment',
        };
      }
    } catch (e) {
      print('Error adding comment: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get comments for a post
  Future<Map<String, dynamic>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('Fetching comments for post: $postId');

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments?page=$page&limit=$limit'),
      );

      print('Get comments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {'success': false, 'data': [], 'pagination': {}};
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return {'success': false, 'data': [], 'pagination': {}};
    }
  }

  // Get featured videos
  Future<List<Map<String, dynamic>>> getFeaturedVideos({int limit = 3}) async {
    try {
      print(
        'Fetching featured videos from: $baseUrl/videos/featured?limit=$limit',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/videos/featured?limit=$limit'),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Featured videos data: ${data['data']?.length ?? 0} videos');
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching featured videos: $e');
      return [];
    }
  }

  // Get featured events
  Future<List<Map<String, dynamic>>> getFeaturedEvents({int limit = 2}) async {
    try {
      print(
        'Fetching featured events from: $baseUrl/events/featured?limit=$limit',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/events/featured?limit=$limit'),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Featured events data: ${data['data']?.length ?? 0} events');
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching featured events: $e');
      return [];
    }
  }

  // Get user posts feed
  Future<Map<String, dynamic>> getFeed({int page = 1, int limit = 10}) async {
    try {
      print('Fetching feed from: $baseUrl/posts/feed?page=$page&limit=$limit');

      // Get token if available
      final token = await _getToken();

      // Add auth header if token exists
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (token != null && token.isNotEmpty) {
        headers['x-auth-token'] = token;
        print('✅ Sending feed request with auth token');
      } else {
        print('⚠️ Fetching feed as guest (no token)');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/posts/feed?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Feed data: ${data['data']?.length ?? 0} posts');
        return data;
      }
      return {
        'success': false,
        'data': [],
        'pagination': {
          'currentPage': 1,
          'totalPages': 0,
          'totalPosts': 0,
          'hasNextPage': false,
          'hasPrevPage': false,
          'limit': limit,
        },
      };
    } catch (e) {
      print('Error fetching feed: $e');
      return {'success': false, 'data': [], 'pagination': {}};
    }
  }

  // Get likes for a post
  Future<Map<String, dynamic>> getLikes(
    String postId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      print('Fetching likes for post: $postId');

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/likes?page=$page&limit=$limit'),
      );

      print('Get likes response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Likes data: ${data['data']?.length ?? 0} likes');
        return data;
      } else {
        return {'success': false, 'data': [], 'pagination': {}};
      }
    } catch (e) {
      print('Error fetching likes: $e');
      return {'success': false, 'data': [], 'pagination': {}};
    }
  }
}
