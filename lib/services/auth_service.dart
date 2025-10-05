import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_factory/utils/constants.dart';
import 'package:the_factory/utils/utils.dart';
import 'package:the_factory/providers/user_provider.dart';
import 'package:the_factory/models/user.dart';
import 'package:provider/provider.dart';
import '../pages/Home_screen/home_screen.dart';
import '../pages/login_screens/login.dart';
import 'package:the_factory/providers/profile_provider.dart';

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

      // ✅ CRITICAL: Clear ALL caches BEFORE signin
      imageCache.clear();
      imageCache.clearLiveImages();
      await CachedNetworkImage.evictFromCache(''); // Clear all
      print("🗑️ All image caches cleared before signin");

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

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          print("✅ Sign in successful, processing response...");
          SharedPreferences prefs = await SharedPreferences.getInstance();

          // Parse the response
          var responseData = jsonDecode(res.body);
          print("📊 Parsed response data: $responseData");

          // Store token
          String token = responseData['token'];
          await prefs.setString('x-auth-token', token);
          print("💾 Token stored: ${token.substring(0, 20)}...");

          // ✅ CRITICAL: Remove old avatar URL completely
          await prefs.remove('user-avatar-url');
          print("🗑️ Old avatar URL removed");

          // Store NEW avatar URL only if it exists
          String? avatarUrl = responseData['avatar']?['url'];
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            await prefs.setString('user-avatar-url', avatarUrl);
            print("💾 New avatar cached: $avatarUrl");
          } else {
            print("⚠️ No avatar in response - user needs to create profile");
          }

          // Store user data
          await prefs.setString('user-data', res.body);

          // Set user in provider
          userProvider.setUser(res.body);
          print("👤 User set in provider");

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

  // ✅ FIXED: More resilient getUserData with better error handling
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

      // ✅ CRITICAL FIX: Load cached user data FIRST (instant UI)
      String? cachedUserData = prefs.getString('user-data');
      if (cachedUserData != null) {
        print("✅ Loading cached user data immediately");
        userProvider.setUser(cachedUserData);
      }

      print("🔍 getUserData: Validating token...");

      // ✅ FIXED: Better error handling for token validation
      http.Response? tokenRes;
      try {
        tokenRes = await http
            .post(
              Uri.parse('${Constants.uri}/api/tokenIsValid'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'x-auth-token': token,
              },
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print("⏰ Token validation timeout - using cached data");
                throw Exception('Request timeout');
              },
            );
      } catch (e) {
        print("⚠️ Token validation failed: $e");
        // If we have cached data, keep the user logged in
        if (cachedUserData != null) {
          print("✅ Using cached data, keeping user logged in");
          userProvider.setLoading(false);
          return;
        } else {
          // No cached data, must logout
          await _clearTokenAndLogout(prefs, userProvider);
          return;
        }
      }

      print("📱 getUserData: Token validation status: ${tokenRes.statusCode}");
      print("📱 getUserData: Token validation body: ${tokenRes.body}");

      // ✅ FIXED: Handle non-200 responses gracefully
      if (tokenRes.statusCode != 200) {
        print("❌ Token validation failed with status ${tokenRes.statusCode}");
        // Keep cached data if available, otherwise logout
        if (cachedUserData == null) {
          await _clearTokenAndLogout(prefs, userProvider);
        } else {
          print("✅ Keeping cached user data");
          userProvider.setLoading(false);
        }
        return;
      }

      var tokenResponse = jsonDecode(tokenRes.body);

      if (tokenResponse == true) {
        print("✅ Token is valid, fetching fresh user data...");

        try {
          http.Response userRes = await http
              .get(
                Uri.parse('${Constants.uri}/api/'),
                headers: {
                  'Content-Type': 'application/json; charset=UTF-8',
                  'x-auth-token': token,
                },
              )
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  print("⏰ User data fetch timeout - using cached data");
                  throw Exception('Request timeout');
                },
              );

          print("📱 User data response - Status: ${userRes.statusCode}");
          print("📱 User data response body: ${userRes.body}");

          if (userRes.statusCode == 200) {
            print("✅ User data fetched successfully");
            // Update both provider and cache
            userProvider.setUser(userRes.body);
            await prefs.setString('user-data', userRes.body);
            print("💾 User data cache updated");
          } else {
            print("⚠️ Failed to fetch user data - using cached data");
            // Keep using cached data if available
            if (cachedUserData == null) {
              await _clearTokenAndLogout(prefs, userProvider);
            }
          }
        } catch (e) {
          print("⚠️ Error fetching user data: $e - using cached data");
          // Keep using cached data
          if (cachedUserData == null) {
            await _clearTokenAndLogout(prefs, userProvider);
          } else {
            userProvider.setLoading(false);
          }
        }
      } else {
        print("❌ Token validation returned false");
        await _clearTokenAndLogout(prefs, userProvider);
      }
    } catch (e) {
      print("❌ getUserData: Critical error: $e");

      // ✅ CRITICAL: Don't logout on network errors if we have cached data
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? cachedUserData = prefs.getString('user-data');

        if (cachedUserData != null) {
          print(
            "✅ Network error but cached data exists - keeping user logged in",
          );
          userProvider.setUser(cachedUserData);
          userProvider.setLoading(false);
        } else {
          print("❌ Network error and no cache - logging out");
          await _clearTokenAndLogout(prefs, userProvider);
        }
      } catch (clearError) {
        print("❌ Error in error handling: $clearError");
        userProvider.setLoading(false);
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
      await prefs.remove('user-avatar-url');
      await prefs.remove('user-data'); // ✅ Clear cached data too
      userProvider.clearUser();
      print("✅ Cleared all auth data");
    } catch (e) {
      print("❌ Error in logout cleanup: $e");
      userProvider.setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      print("🚪 LOGOUT STARTED");

      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Clear everything
      await prefs.clear();
      print("✅ SharedPreferences cleared");

      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();
      print("✅ Image cache cleared");

      // Clear user
      userProvider.clearUser();
      print("✅ UserProvider cleared");

      // FORCE NAVIGATION TO LOGIN SCREEN
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FactoryLoginScreen()),
          (route) => false,
        );
        print("✅ Navigated to login screen");
      }

      print("🚪 LOGOUT COMPLETED");
    } catch (e) {
      print("❌ Error logging out: $e");
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

  // ✅ NEW: Manual token refresh if needed
  Future<bool> refreshUserData(BuildContext context) async {
    try {
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('x-auth-token');

      if (token == null) return false;

      http.Response userRes = await http.get(
        Uri.parse('${Constants.uri}/api/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (userRes.statusCode == 200) {
        userProvider.setUser(userRes.body);
        await prefs.setString('user-data', userRes.body);
        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error refreshing user data: $e");
      return false;
    }
  }
}
