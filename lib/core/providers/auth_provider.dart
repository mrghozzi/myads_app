import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../services/secure_storage_service.dart';

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<bool> login(String loginType, String password) async {
    state = const AsyncLoading();
    try {
      final response = await ApiClient.instance.post(
        '/login',
        data: {
          'login': loginType, // Email or username
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map) {
        state = AsyncError('Unable to connect to server. Please check your configuration.', StackTrace.current);
        return false;
      }

      if (data['status'] == 'success') {
        final token = data['token'];
        // Security: Store token in encrypted secure storage (Android Keystore)
        await SecureStorageService.saveToken(token);
        
        state = const AsyncData(null);
        return true;
      } else {
        // Security: Only show safe user-facing messages, never raw server details
        final message = data['message'];
        state = AsyncError(
          _sanitizeErrorMessage(message ?? 'Login failed'),
          StackTrace.current,
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMsg = 'Connection failed. Please check your network.';
      } else if (e.response?.statusCode == 429) {
        errorMsg = 'Too many login attempts. Please wait a moment.';
      } else if (e.response?.statusCode == 401) {
        errorMsg = 'Invalid credentials. Please try again.';
      } else if (e.response?.data is Map) {
        errorMsg = _sanitizeErrorMessage(
          e.response?.data['message'] ?? 'Login failed. Please try again.',
        );
      } else {
        errorMsg = 'Login failed. Please try again.';
      }

      // Log detailed error only in debug mode
      if (kDebugMode) {
        debugPrint('Login error: ${e.message}');
      }

      state = AsyncError(errorMsg, e.stackTrace);
      return false;
    } catch (e, st) {
      state = AsyncError('An unexpected error occurred.', st);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/logout');
    } catch (_) {}
    
    // Security: Remove token from secure storage
    await SecureStorageService.deleteToken();
    state = const AsyncData(null);
  }

  /// Sanitize error messages to prevent leaking server internals to the UI.
  String _sanitizeErrorMessage(String message) {
    // Strip any server hostnames, IPs, or paths from error messages
    final sanitized = message
        .replaceAll(RegExp(r'https?://[^\s]+'), '[server]')
        .replaceAll(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '[server]')
        .replaceAll(RegExp(r'SQLSTATE\[.*?\]'), '')
        .replaceAll(RegExp(r'at\s+/.*?:\d+'), '');
    
    // If the message became mostly empty after sanitization, use a generic one
    if (sanitized.trim().isEmpty) {
      return 'An error occurred. Please try again.';
    }
    return sanitized.trim();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
