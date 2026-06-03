import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_router.dart';
import '../services/secure_storage_service.dart';

class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject API Key (from .env, non-sensitive build config)
    final apiKey = dotenv.env['MOBILE_API_KEY'];
    if (apiKey != null) {
      options.headers['X-API-KEY'] = apiKey;
    }

    // Security: Inject Bearer Token from encrypted secure storage
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
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
    // Handle 401 Unauthorized globally
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Security: Clear token from encrypted secure storage
      await SecureStorageService.deleteToken();
      // Navigate to login
      appRouter.go('/login');
    }
    
    return super.onError(err, handler);
  }
}
