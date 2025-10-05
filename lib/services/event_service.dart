// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class EventService {
  // Replace with your actual backend URL
  static const String baseUrl = 'http://192.168.100.16:3000/api';

  // You might want to get this from your existing auth_service
  String? get authToken => null; // Add your auth token logic here

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // Get all events with optional filters
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
      final response = await http.get(
        uri,
        headers: headers,
      ); // ✅ DECLARED EARLY

      if (response.statusCode == 200) {
        print('🌐 API Response Status: ${response.statusCode}');
        print('📄 Raw Response Body: ${response.body}');

        final data = json.decode(response.body);
        print('🔍 Parsed Data: $data');
        print('📊 Events Array Length: ${(data['data'] as List).length}');

        // Print each event
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          for (int i = 0; i < (data['data'] as List).length; i++) {
            print('Event $i: ${(data['data'] as List)[i]}');
          }
        }

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

  // Get single event details
  Future<ApiResponse<Event>> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ADD THIS DEBUG LOGGING
        print('🔍 Raw API Response Data: $data');
        print('🔍 Event Data: ${data['data']}');
        print('🔍 Organizer Name: ${data['data']['organizerName']}');
        print('🔍 Organizer Email: ${data['data']['organizerEmail']}');
        print('🔍 Organizer Phone: ${data['data']['organizerPhone']}');

        if (data['success'] == true) {
          final event = Event.fromJson(data['data']);

          // ADD THIS DEBUG LOGGING
          print('🔍 Parsed Event Organizer Name: ${event.organizerName}');
          print('🔍 Parsed Event Organizer Email: ${event.organizerEmail}');
          print('🔍 Parsed Event Organizer Phone: ${event.organizerPhone}');

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

  // Register for event
  Future<ApiResponse<RegistrationResponse>> registerForEvent({
    required String eventId,
    required RegistrationData registrationData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/register'),
        headers: headers,
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
        headers: headers,
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

  // Add this to event_service.dart

  Future<String> getTicketHtml(String registrationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets/$registrationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body; // Returns HTML
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

  // Mark registration as paid (after payment processing)
  Future<ApiResponse<RegistrationResponse>> markRegistrationAsPaid({
    required String registrationId,
    required double paidAmount,
    required String paymentMethod,
    String? paymentTransactionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/registrations/$registrationId/payment'),
        headers: headers,
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
