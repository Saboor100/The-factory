class Constants {
  static const String uri = 'http://192.168.100.16:3000';
}

class ApiConstants {
  // Profile API endpoints
  static const String profileBaseUrl = '${Constants.uri}/api/profile';
  static const String getMyProfile = '$profileBaseUrl/me';
  static const String updateProfile = '$profileBaseUrl';
  static const String updateAvatar = '$profileBaseUrl/avatar';
  static const String deleteAvatar = '$profileBaseUrl/avatar';
}
