import 'package:flutter/material.dart';
import 'package:the_factory/models/user.dart';

class UserProvider extends ChangeNotifier {
  // Private variable to store the user
  User _user = User(id: '', name: '', email: '', token: '', password: '');
  bool _isLoading = true;

  // Getters
  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user.token.isNotEmpty;

  // Set user from JSON string
  void setUser(String userJson) {
    _user = User.fromJson(userJson);
    _isLoading = false;
    notifyListeners();
  }

  // Set user from User model directly
  void setUserFromModel(User user) {
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  // Clear user data (for logout)
  void clearUser() {
    _user = User(id: '', name: '', email: '', token: '', password: '');
    _isLoading = false;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool value) {
    print("🔄 UserProvider: Setting loading to $value");
    _isLoading = value;
    notifyListeners();
  }
}
