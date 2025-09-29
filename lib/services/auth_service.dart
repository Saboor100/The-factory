import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_factory/utils/constants.dart';
import 'package:the_factory/utils/utils.dart';
import 'package:the_factory/providers/user_provider.dart';
import 'package:the_factory/models/user.dart';
import 'package:provider/provider.dart';
import '../pages/Home_screen/home_screen.dart';

class AuthService {
  void signupUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      Map<String, String> requestBody = {
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': password,
      };

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: jsonEncode(requestBody),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Account Created Successfully!');
          Navigator.pop(context);
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error: ${e.toString()}');
    }
  }

  void signInUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      print("🔄 Starting sign in process...");
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("📱 Sign in response status: ${res.statusCode}");
      print("📱 Sign in response body: ${res.body}");

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          print("✅ Sign in successful, processing response...");
          SharedPreferences prefs = await SharedPreferences.getInstance();

          // Parse the response
          var responseData = jsonDecode(res.body);
          print("📊 Parsed response data: $responseData");

          // Set user data
          userProvider.setUser(res.body);
          print("👤 User set in provider");

          // Store token
          String token = responseData['token'];
          await prefs.setString('x-auth-token', token);
          print("💾 Token stored: ${token.substring(0, 20)}...");

          // ✅ Save avatar URL for instant load
          String? avatarUrl = responseData['avatar']?['url'];
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            await prefs.setString('user-avatar-url', avatarUrl);
            print("💾 Avatar cached: $avatarUrl");
          }

          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => FactoryFeedScreen()),
            (route) => false,
          );
        },
      );
    } catch (e) {
      print("❌ Sign in error: $e");
      showSnackBar(context, e.toString());
    }
  }

  // FORGOT PASSWORD METHODS

  Future<bool> sendForgotPasswordOTP({
    required BuildContext context,
    required String email,
  }) async {
    try {
      print("🔄 Sending forgot password OTP for: $email");

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/forgot-password'),
        body: jsonEncode({'email': email}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("📱 Forgot password response status: ${res.statusCode}");
      print("📱 Forgot password response body: ${res.body}");

      if (res.statusCode == 200) {
        showSnackBar(context, 'OTP sent successfully! Check your email.');
        return true;
      } else {
        var errorData = jsonDecode(res.body);
        showSnackBar(context, errorData['message'] ?? 'Failed to send OTP');
        return false;
      }
    } catch (e) {
      print("❌ Send OTP error: $e");
      showSnackBar(context, 'Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> verifyOTP({
    required BuildContext context,
    required String email,
    required String otp,
  }) async {
    try {
      print("🔄 Verifying OTP for: $email with OTP: $otp");

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/verify-otp'),
        body: jsonEncode({'email': email, 'otp': otp}),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("📱 Verify OTP response status: ${res.statusCode}");
      print("📱 Verify OTP response body: ${res.body}");

      if (res.statusCode == 200) {
        showSnackBar(context, 'OTP verified successfully!');
        return true;
      } else {
        var errorData = jsonDecode(res.body);
        showSnackBar(context, errorData['message'] ?? 'Invalid OTP');
        return false;
      }
    } catch (e) {
      print("❌ Verify OTP error: $e");
      showSnackBar(context, 'Error: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resetPassword({
    required BuildContext context,
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print("🔄 Resetting password for: $email");

      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/reset-password'),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("📱 Reset password response status: ${res.statusCode}");
      print("📱 Reset password response body: ${res.body}");

      if (res.statusCode == 200) {
        showSnackBar(
          context,
          'Password reset successfully! Please login with your new password.',
        );
        return true;
      } else {
        var errorData = jsonDecode(res.body);
        showSnackBar(
          context,
          errorData['message'] ?? 'Failed to reset password',
        );
        return false;
      }
    } catch (e) {
      print("❌ Reset password error: $e");
      showSnackBar(context, 'Error: ${e.toString()}');
      return false;
    }
  }

  Future<void> getUserData(BuildContext context) async {
    print("🔄 getUserData: Starting...");

    if (!context.mounted) {
      print("❌ getUserData: Context not mounted, returning");
      return;
    }

    var userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      print("🔄 getUserData: Setting loading to true");
      userProvider.setLoading(true);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      print(
        "🔑 getUserData: Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}",
      );

      if (token == null || token.isEmpty) {
        print("❌ getUserData: No token found, setting loading to false");
        userProvider.setLoading(false);
        return;
      }

      print("🔍 getUserData: Validating token...");

      var tokenRes = await http.post(
        Uri.parse('${Constants.uri}/api/tokenIsValid'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      print("📱 getUserData: Token validation status: ${tokenRes.statusCode}");
      print("📱 getUserData: Token validation body: ${tokenRes.body}");

      if (tokenRes.statusCode != 200) {
        print("❌ Token invalid — logging out...");
        await _clearTokenAndLogout(prefs, userProvider);
        return;
      }

      var tokenResponse = jsonDecode(tokenRes.body);

      if (tokenResponse == true) {
        print("✅ Token is valid, fetching user data...");

        http.Response userRes = await http.get(
          Uri.parse('${Constants.uri}/api/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'x-auth-token': token,
          },
        );

        print("📱 User data response - Status: ${userRes.statusCode}");
        print("📱 User data response body: ${userRes.body}");

        if (userRes.statusCode == 200) {
          print("✅ User data fetched successfully");
          userProvider.setUser(userRes.body);
        } else {
          print("❌ Failed to fetch user data");
          await _clearTokenAndLogout(prefs, userProvider);
        }
      } else {
        print("❌ Token validation returned false");
        await _clearTokenAndLogout(prefs, userProvider);
      }
    } catch (e) {
      print("❌ getUserData: Error: $e");
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await _clearTokenAndLogout(prefs, userProvider);
      } catch (clearError) {
        print("❌ Error clearing token: $clearError");
        userProvider.setLoading(false);
      }
      if (context.mounted) {
        showSnackBar(context, 'Session expired. Please login again.');
      }
    }
  }

  Future<void> _clearTokenAndLogout(
    SharedPreferences prefs,
    UserProvider userProvider,
  ) async {
    print("🗑️ Clearing token and user...");
    try {
      await prefs.remove('x-auth-token');
      await prefs.remove('user-avatar-url'); // ✅ Also clear avatar cache here
      userProvider.clearUser();
      print("✅ Cleared token and avatar cache");
    } catch (e) {
      print("❌ Error in logout cleanup: $e");
      userProvider.setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      print("🚪 Logging out...");
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove('x-auth-token');
      await prefs.remove('user-avatar-url'); // ✅ Also clear on full logout
      userProvider.clearUser();

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      showSnackBar(context, 'Logged out successfully');
    } catch (e) {
      showSnackBar(context, 'Error logging out: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('x-auth-token');
    bool loggedIn = token != null && token.isNotEmpty;
    print(
      "🔍 isLoggedIn: $loggedIn (token: ${token != null ? 'exists' : 'null'})",
    );
    return loggedIn;
  }
}
