import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../utils/constants.dart';
import 'package:http_parser/http_parser.dart';

class ProfileService {
  // Get authentication token
  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token');
      print(
        'Retrieved token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}',
      );
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Convert any decoded JSON value into a Map<String, dynamic>
  static Map<String, dynamic> _toStringKeyedMap(
    dynamic value, {
    String what = 'response',
  }) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException(
      'Expected a JSON object for $what but got ${value.runtimeType}',
    );
  }

  // Check if response is HTML (error page)
  static bool _isHtmlResponse(String body) {
    final trimmed = body.trim().toLowerCase();
    return trimmed.startsWith('<!doctype html') || trimmed.startsWith('<html');
  }

  // Parse error response safely
  static String _parseErrorMessage(http.Response response) {
    try {
      if (_isHtmlResponse(response.body)) {
        return 'Server returned HTML error page. Check if server is running and API endpoint is correct.';
      }
      if (response.body.isEmpty) {
        return 'Empty response from server';
      }
      final decoded = json.decode(response.body);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        return (map['message'] ?? 'Unknown error occurred').toString();
      }
      return 'Unknown error occurred';
    } catch (e) {
      final preview =
          response.body.length > 100
              ? response.body.substring(0, 100)
              : response.body;
      return 'Failed to parse error response: $preview...';
    }
  }

  // Get current user's profile
  static Future<Profile?> getMyProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      print('Fetching profile from: ${Constants.uri}/api/profile/me');

      final response = await http
          .get(
            Uri.parse('${Constants.uri}/api/profile/me'),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Profile fetch response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (_isHtmlResponse(response.body)) {
          throw Exception(
            'Server returned HTML instead of JSON. Check server configuration.',
          );
        }

        final decoded = json.decode(response.body);

        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map.isEmpty) return null;
          return Profile.fromJson(map); // FIX: now Map<String, dynamic>
        }

        // If server returns empty string or non-object
        return null;
      } else if (response.statusCode == 404) {
        print('No profile found for user');
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception(
          'Failed to load profile (${response.statusCode}): $errorMessage',
        );
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Server returned invalid response format.');
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  // Update profile
  static Future<Profile> updateProfile(Profile profile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final requestBody = profile.toJson();
      print('Updating profile at: ${Constants.uri}/api/profile');
      print('Request body: ${json.encode(requestBody)}');

      final response = await http
          .put(
            Uri.parse('${Constants.uri}/api/profile'),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      print('Profile update response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_isHtmlResponse(response.body)) {
          throw Exception(
            'Server returned HTML instead of JSON. Check server configuration.',
          );
        }

        final map = _toStringKeyedMap(json.decode(response.body)); // FIX
        return Profile.fromJson(map);
      } else if (response.statusCode == 400) {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Validation error: $errorMessage');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 500) {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Server error: $errorMessage');
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception(
          'Failed to update profile (${response.statusCode}): $errorMessage',
        );
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw Exception('Server returned invalid response format.');
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Upload profile avatar
  static Future<Avatar> uploadAvatar(File imageFile) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      print('Image file size: $fileSize bytes');

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file too large. Please choose a smaller image.');
      }
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      // Get file extension to determine MIME type
      String fileName = imageFile.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();

      // Determine MIME type based on extension
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // fallback
      }

      print('Uploading avatar to: ${Constants.uri}/api/profile/avatar');
      print('File path: ${imageFile.path}');
      print('File name: $fileName');
      print('MIME type: $mimeType');

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${Constants.uri}/api/profile/avatar'),
      );

      request.headers.addAll({
        'x-auth-token': token,
        // Don't set Content-Type here - let it be set automatically with boundary
      });

      // Add file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar', // Field name - must match backend
          imageFile.path,
          contentType: MediaType.parse(mimeType), // Explicit MIME type
        ),
      );

      print('Sending multipart request with MIME type: $mimeType');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('Avatar upload response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (_isHtmlResponse(response.body)) {
          throw Exception(
            'Server returned HTML instead of JSON. Check server configuration.',
          );
        }

        final map = _toStringKeyedMap(
          json.decode(response.body),
          what: 'avatar upload',
        );

        if (map['avatar'] != null) {
          final avatarMap = _toStringKeyedMap(map['avatar'], what: 'avatar');
          return Avatar.fromJson(avatarMap);
        } else if (map['url'] != null) {
          return Avatar.fromJson(map);
        } else {
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 400) {
        final errorMessage = _parseErrorMessage(response);
        throw Exception('Invalid image file: $errorMessage');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception(
          'Failed to upload avatar (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }

  // Delete profile avatar
  static Future<void> deleteAvatar() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      print('Deleting avatar from: ${Constants.uri}/api/profile/avatar');

      final response = await http
          .delete(
            Uri.parse('${Constants.uri}/api/profile/avatar'),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Avatar delete response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Avatar deleted successfully');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('No avatar found to delete.');
      } else {
        final errorMessage = _parseErrorMessage(response);
        throw Exception(
          'Failed to delete avatar (${response.statusCode}): $errorMessage',
        );
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('Error deleting avatar: $e');
      rethrow;
    }
  }
}
