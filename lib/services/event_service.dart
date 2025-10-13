import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/user_registration_model.dart';

class EventService {
  static const String baseUrl = 'http://192.168.100.16:3000/api';

  // Get user token from SharedPreferences (set by AuthService)
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('x-auth-token');
  }

  // Proper headers function that ensures token is sent for all protected routes
  Future<Map<String, String>> headers() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'x-auth-token': token,
    };
  }

  // Get all events with optional filters - token optional
  Future<ApiResponse<List<Event>>> getEvents({
    int page = 1,
    int limit = 20,
    String? category,
    bool? featured,
    String? search,
    bool upcoming = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'upcoming': upcoming.toString(),
      };
      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }
      if (featured != null) {
        queryParams['featured'] = featured.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/events',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await headers());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<Event> events =
              (data['data'] as List)
                  .map((eventJson) => Event.fromJson(eventJson))
                  .toList();

          return ApiResponse.success(
            data: events,
            pagination:
                data['pagination'] != null
                    ? PaginationInfo.fromJson(data['pagination'])
                    : null,
          );
        } else {
          return ApiResponse.error(data['message'] ?? 'Failed to fetch events');
        }
      } else {
        return ApiResponse.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getEvents: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Get single event details (token optional)
  Future<ApiResponse<Event>> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final event = Event.fromJson(data['data']);
          return ApiResponse.success(data: event);
        } else {
          return ApiResponse.error(data['message'] ?? 'Event not found');
        }
      } else if (response.statusCode == 404) {
        return ApiResponse.error('Event not found');
      } else {
        return ApiResponse.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getEventById: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Register for event - NOW sends token!
  Future<ApiResponse<RegistrationResponse>> registerForEvent({
    required String eventId,
    required RegistrationData registrationData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/register'),
        headers: await headers(), // <-- token always sent if present!
        body: json.encode(registrationData.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final registration = RegistrationResponse.fromJson(data['data']);
          return ApiResponse.success(data: registration);
        } else {
          return ApiResponse.error(data['message'] ?? 'Registration failed');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Invalid registration data',
        );
      } else if (response.statusCode == 401) {
        return ApiResponse.error('Unauthorized. Please sign in again.');
      } else {
        return ApiResponse.error('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Validate discount code
  Future<ApiResponse<DiscountValidation>> validateDiscountCode({
    required String code,
    required String eventId,
    required String ticketType,
    String? userEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/discounts/validate'),
        headers: await headers(),
        body: json.encode({
          'code': code,
          'eventId': eventId,
          'ticketType': ticketType,
          if (userEmail != null) 'userEmail': userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final discount = DiscountValidation.fromJson(data['data']);
          return ApiResponse.success(data: discount);
        } else {
          return ApiResponse.error(data['message'] ?? 'Invalid discount code');
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Discount validation failed',
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<String> getTicketHtml(String registrationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$registrationId'),
        headers: await headers(),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load ticket');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> getTicketDownloadUrl(String registrationId) async {
    return '$baseUrl/tickets/$registrationId/download';
  }

  // Mark registration as paid - sends token
  Future<ApiResponse<RegistrationResponse>> markRegistrationAsPaid({
    required String registrationId,
    required double paidAmount,
    required String paymentMethod,
    String? paymentTransactionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/registrations/$registrationId/payment'),
        headers: await headers(),
        body: json.encode({
          'paidAmount': paidAmount,
          'paymentMethod': paymentMethod,
          if (paymentTransactionId != null)
            'paymentTransactionId': paymentTransactionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final registration = RegistrationResponse.fromJson(data['data']);
          return ApiResponse.success(data: registration);
        } else {
          return ApiResponse.error(
            data['message'] ?? 'Payment processing failed',
          );
        }
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['message'] ?? 'Payment failed');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Get user's registrations - token always sent
  Future<ApiResponse<List<UserRegistration>>> getUserRegistrations() async {
    try {
      print('🎫 Fetching user registrations...');
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-registrations'),
        headers: await headers(),
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<UserRegistration> registrations =
              (data['data'] as List)
                  .map((json) => UserRegistration.fromJson(json))
                  .toList();

          print('✅ Loaded ${registrations.length} registrations');

          return ApiResponse.success(data: registrations);
        }
      }

      return ApiResponse.error('Failed to load registrations');
    } catch (e) {
      print('❌ Error fetching registrations: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Get single registration details - token sent
  Future<ApiResponse<UserRegistration>> getRegistrationById(
    String registrationId,
  ) async {
    try {
      print('🎫 Fetching registration: $registrationId');

      final response = await http.get(
        Uri.parse('$baseUrl/events/registrations/$registrationId'),
        headers: await headers(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final registration = UserRegistration.fromJson(data['data']);
          return ApiResponse.success(data: registration);
        }
      }

      return ApiResponse.error('Registration not found');
    } catch (e) {
      print('❌ Error fetching registration: $e');
      return ApiResponse.error('Network error: $e');
    }
  }
}

// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final PaginationInfo? pagination;

  ApiResponse.success({required this.data, this.pagination})
    : success = true,
      error = null;

  ApiResponse.error(this.error)
    : success = false,
      data = null,
      pagination = null;
}

// Pagination info
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalEvents;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int limit;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalEvents,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalEvents: json['totalEvents'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
      limit: json['limit'] ?? 20,
    );
  }
}
