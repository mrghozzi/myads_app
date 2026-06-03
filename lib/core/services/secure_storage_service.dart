import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage service for sensitive credentials.
///
/// Uses Android Keystore (hardware-backed encryption) via flutter_secure_storage
/// instead of plaintext SharedPreferences XML files.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _authTokenKey = 'auth_token';

  /// Store the authentication token securely.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Retrieve the stored authentication token.
  static Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Delete the stored authentication token (logout).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Check if an auth token exists.
  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Clear all secure storage (full reset).
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
