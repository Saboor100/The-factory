import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _error;
  String? _cachedAvatarUrl;
  bool _cacheLoaded = false;

  // Cache keys
  static const String _avatarCacheKey = 'cached_avatar_url';
  static const String _profileIdCacheKey = 'cached_profile_id';
  static const String _fullNameCacheKey = 'cached_full_name';

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  String? get cachedAvatarUrl => _cachedAvatarUrl;
  bool get cacheLoaded => _cacheLoaded;

  // Get best available avatar URL
  String? getAvatarUrl() {
    return _profile?.avatar?.url ?? _cachedAvatarUrl;
  }

  // Load profile with instant caching
  Future<void> loadProfile() async {
    // Step 1: Load cached data FIRST (INSTANT)
    await _loadCachedProfile();

    // Step 2: Fetch fresh data from API in background
    await _fetchFreshProfile();
  }

  // Load cached profile data (INSTANT - no network call)
  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAvatarUrl = prefs.getString(_avatarCacheKey);

      // If we have cached data, create a temporary profile object
      if (_cachedAvatarUrl != null) {
        _profile = Profile(
          id: prefs.getString(_profileIdCacheKey),
          fullName: prefs.getString(_fullNameCacheKey),
          avatar: Avatar(url: _cachedAvatarUrl!),
        );
      }

      _cacheLoaded = true;
      notifyListeners(); // This triggers immediate UI update with cached data
    } catch (e) {
      print('Error loading cached profile: $e');
      _cacheLoaded = true;
      notifyListeners();
    }
  }

  // Fetch fresh profile data from API (runs in background)
  Future<void> _fetchFreshProfile() async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading fresh profile...');
      final freshProfile = await ProfileService.getMyProfile();
      print('Fresh profile loaded successfully: ${freshProfile != null}');

      if (freshProfile != null) {
        _profile = freshProfile;

        // Update cache with fresh data
        await _updateCache(freshProfile);
      } else {
        print('No profile found - user needs to create one');
      }

      notifyListeners();
    } catch (e) {
      print('Error loading fresh profile: $e');
      _error = _extractUserFriendlyError(e.toString());
      // Don't clear cached data on error - keep showing cached version
    } finally {
      _setLoading(false);
    }
  }

  // Update cache with fresh profile data
  Future<void> _updateCache(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (profile.avatar?.url != null) {
        await prefs.setString(_avatarCacheKey, profile.avatar!.url!);
        _cachedAvatarUrl = profile.avatar!.url!;
      }

      if (profile.id != null) {
        await prefs.setString(_profileIdCacheKey, profile.id!);
      }

      if (profile.fullName != null) {
        await prefs.setString(_fullNameCacheKey, profile.fullName!);
      }
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  // Update profile method with caching
  Future<void> updateProfile({
    String? fullName,
    DateTime? dob,
    String? street,
    String? city,
    String? state,
    String? zip,
    String? clubTeam,
    String? school,
    int? graduationYear,
    String? position,
    String? instagramHandle,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('Updating profile...');

      // Create address object only if at least one field is provided
      Address? address;
      if (street?.isNotEmpty == true ||
          city?.isNotEmpty == true ||
          state?.isNotEmpty == true ||
          zip?.isNotEmpty == true) {
        address = Address(
          street: street?.isNotEmpty == true ? street : null,
          city: city?.isNotEmpty == true ? city : null,
          state: state?.isNotEmpty == true ? state : null,
          zip: zip?.isNotEmpty == true ? zip : null,
        );
      }

      final updatedProfile = Profile(
        id: _profile?.id,
        userId: _profile?.userId,
        fullName: fullName?.isNotEmpty == true ? fullName : null,
        dob: dob,
        address: address,
        clubTeam: clubTeam?.isNotEmpty == true ? clubTeam : null,
        school: school?.isNotEmpty == true ? school : null,
        graduationYear: graduationYear,
        position: position?.isNotEmpty == true ? position : null,
        instagramHandle:
            instagramHandle?.isNotEmpty == true ? instagramHandle : null,
        avatar: _profile?.avatar, // Keep existing avatar
      );

      print('Profile data to send: ${updatedProfile.toJson()}');

      _profile = await ProfileService.updateProfile(updatedProfile);
      print('Profile updated successfully');

      // Update cache with new profile data
      await _updateCache(_profile!);

      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      _error = _extractUserFriendlyError(e.toString());
      rethrow; // Rethrow so UI can show success/error messages
    } finally {
      _setLoading(false);
    }
  }

  // Upload avatar with caching
  Future<void> uploadAvatar(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      print('Uploading avatar...');

      // Validate image file
      if (!await imageFile.exists()) {
        throw Exception('Selected image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'Image too large. Please select an image smaller than 10MB.',
        );
      }

      final avatar = await ProfileService.uploadAvatar(imageFile);
      print('Avatar uploaded successfully: ${avatar.url}');

      if (_profile != null) {
        _profile = _profile!.copyWith(avatar: avatar);
      } else {
        // Create a basic profile with just the avatar if no profile exists
        _profile = Profile(avatar: avatar);
      }

      // Update cache with new avatar
      await _updateCache(_profile!);

      notifyListeners();
    } catch (e) {
      print('Error uploading avatar: $e');
      _error = _extractUserFriendlyError(e.toString());
      rethrow; // Let UI handle the error message
    } finally {
      _setLoading(false);
    }
  }

  // Delete avatar with cache update
  Future<void> deleteAvatar() async {
    _setLoading(true);
    _clearError();

    try {
      print('Deleting avatar...');
      await ProfileService.deleteAvatar();
      print('Avatar deleted successfully');

      if (_profile != null) {
        _profile = _profile!.copyWith(avatar: null);

        // Clear cached avatar
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_avatarCacheKey);
        _cachedAvatarUrl = null;

        notifyListeners();
      }
    } catch (e) {
      print('Error deleting avatar: $e');
      _error = _extractUserFriendlyError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Clear cache (useful for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_avatarCacheKey);
      await prefs.remove(_profileIdCacheKey);
      await prefs.remove(_fullNameCacheKey);

      _profile = null;
      _cachedAvatarUrl = null;
      _cacheLoaded = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Extract user-friendly error messages
  String _extractUserFriendlyError(String error) {
    // Remove "Exception: " prefix if present
    String cleanError = error.replaceFirst('Exception: ', '');

    // Handle common error patterns
    if (cleanError.contains('FormatException') ||
        cleanError.contains('<!DOCTYPE html>')) {
      return 'Server configuration error. Please contact support.';
    } else if (cleanError.contains('SocketException') ||
        cleanError.contains('Network error')) {
      return 'Please check your internet connection and try again.';
    } else if (cleanError.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (cleanError.contains('authentication') ||
        cleanError.contains('401')) {
      return 'Please login again.';
    } else if (cleanError.contains('validation') ||
        cleanError.contains('400')) {
      return 'Please check your input and try again.';
    } else if (cleanError.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (cleanError.length > 100) {
      // Truncate very long error messages
      return cleanError.substring(0, 100) + '...';
    }

    return cleanError;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
