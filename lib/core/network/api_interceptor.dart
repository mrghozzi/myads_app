import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart';

class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject API Key (from .env, non-sensitive build config)
    final apiKey = dotenv.env['MOBILE_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers['X-API-KEY'] = apiKey.trim();
    }

    // Security: Inject Bearer Token from secure storage
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['X-Authorization'] = 'Bearer $token'; // Bypass shared hosting header stripping
    }

    // Force Accept JSON
    options.headers['Accept'] = 'application/json';

    // Inject language code (non-sensitive, stays in SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    options.headers['Accept-Language'] = langCode;
    options.headers['X-Locale'] = langCode;

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Instead of logging out silently, we will pass the error to the UI
    // so we can see EXACTLY why the server is rejecting the request (Invalid API Key vs Unauthenticated).
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      debugPrint('=== API ERROR DETAILS ===');
      debugPrint('Status: ${err.response?.statusCode}');
      debugPrint('Response: ${err.response?.data}');
      debugPrint('Headers sent: ${err.requestOptions.headers}');
      debugPrint('========================');
    }
    
    return super.onError(err, handler);
  }
}
