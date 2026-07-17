import 'package:shared_preferences/shared_preferences.dart';

/// Centralized storage service for credentials.
/// Switched to SharedPreferences to bypass Android Keystore bugs on Xiaomi/MIUI.
class SecureStorageService {
  static const _authTokenKey = 'auth_token';

  /// Store the authentication token.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  /// Retrieve the stored authentication token.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Delete the stored authentication token (logout).
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  /// Check if an auth token exists.
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Clear all secure storage (full reset).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
