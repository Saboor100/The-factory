import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // Replace with your actual backend URL
  static const String baseUrl =
      'https://the-factory-server.onrender.com/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS Simulator
  // static const String baseUrl = 'http://YOUR_IP:3000/api'; // Real Device

  /// Process payment for event booking
  static Future<bool> processEventPayment({
    required String eventId,
    required double amount,
    required String eventName,
    required String userId,
    required String token, // Auth token
  }) async {
    try {
      print('Creating payment intent for event: $eventName');

      // Step 1: Create payment intent on your backend
      final response = await http.post(
        Uri.parse('$baseUrl/payment/event/create-payment'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode({
          'eventId': eventId,
          'amount': amount,
          'userId': userId,
          'eventName': eventName,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to create payment intent: ${response.body}');
        return false;
      }

      final data = json.decode(response.body);
      final clientSecret = data['clientSecret'];

      print('Payment intent created successfully');

      // Ensure publishable key is set (workaround for Android)
      Stripe.publishableKey =
          'pk_test_51RTPwXR23CAa1CnAjXPthRwCOBBkwQfj0QDU30u8jhkygtaqDuDK83LxdQYNJEV9l9ypByvHQVYQ7f7enSmqdwas00HiFBD0lQ';

      // Step 2: Initialize payment sheet with MINIMAL configuration
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'The Factory',
          // Remove style parameter to avoid conflicts
        ),
      );

      print('Payment sheet initialized');

      // Step 3: Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      print('Payment completed successfully!');
      return true;
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');
      print('Stripe error code: ${e.error.code}');
      if (e.error.code == FailureCode.Canceled) {
        print('Payment cancelled by user');
      }
      return false;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }

  /// Process payment for video purchase
  static Future<bool> processVideoPayment({
    required String videoId,
    required double amount,
    required String videoTitle,
    required String userId,
    required String token, // Auth token
  }) async {
    try {
      print('Creating payment intent for video: $videoTitle');

      // Step 1: Create payment intent on your backend
      final response = await http.post(
        Uri.parse('$baseUrl/payment/video/create-payment'),
        headers: {'Content-Type': 'application/json', 'x-auth-token': token},
        body: json.encode({
          'videoId': videoId,
          'amount': amount,
          'userId': userId,
          'videoTitle': videoTitle,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to create payment intent: ${response.body}');
        return false;
      }

      final data = json.decode(response.body);
      final clientSecret = data['clientSecret'];

      print('Payment intent created successfully');

      // Ensure publishable key is set (workaround for Android)
      Stripe.publishableKey =
          'pk_test_51RTPwXR23CAa1CnAjXPthRwCOBBkwQfj0QDU30u8jhkygtaqDuDK83LxdQYNJEV9l9ypByvHQVYQ7f7enSmqdwas00HiFBD0lQ';

      // Step 2: Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'The Factory',
        ),
      );

      print('Payment sheet initialized');

      // Step 3: Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      print('Payment completed successfully!');
      return true;
    } on StripeException catch (e) {
      print('Stripe error: ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) {
        print('Payment cancelled by user');
      }
      return false;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }

  /// Check if user has access to a specific video
  static Future<bool> checkVideoAccess({
    required String videoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/video/$videoId/access'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasAccess'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking video access: $e');
      return false;
    }
  }

  /// Get user's payment history
  static Future<List<dynamic>> getPaymentHistory({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/history'),
        headers: {'x-auth-token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['payments'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }
}
