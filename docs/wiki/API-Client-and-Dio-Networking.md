# API Client & Dio Networking

The MYADS Mobile App relies on **Dio** as its primary HTTP networking engine. All network calls are orchestrated through a unified singleton client (`ApiClient`) coupled with an interceptor chain (`ApiInterceptor`).

---

## 1. The `ApiClient` Singleton

The `ApiClient` class encapsulates the global `Dio` instance with standardized connection parameters:

```dart
class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost/myads/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(ApiInterceptor());

  static Dio get instance => _dio;
}
```

### 1.1 Timeout Configurations
* **`connectTimeout: Duration(seconds: 30)`**: Guarantees that requests fail fast if the host is unreachable or DNS resolution fails.
* **`receiveTimeout: Duration(seconds: 30)`**: Prevents hanging requests during heavy operations (e.g. uploading large media attachments or video processing).

---

## 2. The `ApiInterceptor` Request Pipeline

The `ApiInterceptor` intercepts every outgoing HTTP request before it hits the wire:

```dart
class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Inject Mobile API Key
    final apiKey = dotenv.env['MOBILE_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers['X-API-KEY'] = apiKey.trim();
    }

    // 2. Inject Hardware-Stored Bearer Token
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['X-Authorization'] = 'Bearer $token'; // Header stripping bypass
      options.headers['X-Api-Token'] = 'Bearer $token';    // ModSecurity fallback
    }

    // 3. Force JSON Responses
    options.headers['Accept'] = 'application/json';

    // 4. Inject Active Locale Code
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    options.headers['Accept-Language'] = langCode;
    options.headers['X-Locale'] = langCode;

    return super.onRequest(options, handler);
  }
}
```

---

## 3. Global Error Handling & Diagnostic Logging

The `onError` interceptor intercepts HTTP error responses (specifically 401 Unauthorized and 403 Forbidden) and outputs diagnostic logs to Flutter debug console:

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
    debugPrint('=== API ERROR DETAILS ===');
    debugPrint('Status: ${err.response?.statusCode}');
    debugPrint('Response: ${err.response?.data}');
    debugPrint('Headers sent: ${err.requestOptions.headers}');
    debugPrint('========================');
  }
  return super.onError(err, handler);
}
```

This prevents silent login failure loops and provides developers with immediate insight into whether a failure is due to an invalid `MOBILE_API_KEY` or an expired Sanctum token.

---

## 4. Best Practices for Network Calls

1. **Always use `try-catch` with `DioException`:**
   ```dart
   try {
     final response = await ApiClient.instance.get('/feed');
     return FeedResponse.fromJson(response.data);
   } on DioException catch (e) {
     final message = e.response?.data['message'] ?? 'Network error occurred';
     throw Exception(message);
   }
   ```
2. **Never hardcode Base URLs in feature code:** Always call relative endpoints (e.g. `/profile`, `/video/feed`).
