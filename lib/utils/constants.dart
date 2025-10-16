class Constants {
  static const String uri = 'https://the-factory-server.onrender.com';
}

class ApiConstants {
  // Profile API endpoints
  static const String profileBaseUrl = '${Constants.uri}/api/profile';
  static const String getMyProfile = '$profileBaseUrl/me';
  static const String updateProfile = '$profileBaseUrl';
  static const String updateAvatar = '$profileBaseUrl/avatar';
  static const String deleteAvatar = '$profileBaseUrl/avatar';
}
