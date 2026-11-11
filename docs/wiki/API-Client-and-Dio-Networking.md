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
     final response = await ApiClient.instance.get('/notifications');
     return response.data;
   } on DioException catch (e) {
     final message = e.response?.data['message'] ?? 'Network error occurred';
     throw Exception(message);
   }
   ```
2. **Handle Cancellation Tokens for Disposed Views:** Use `CancelToken` when navigating away from high-bandwidth screens like video feeds to avoid memory leaks.
3. **Use FormData for Media Uploads:** Multi-part file uploads (images, avatars, clips) should be passed via `FormData.fromMap({'media': await MultipartFile.fromFile(path)})`.

---

## 5. Core API Endpoints Catalog

| Domain | Method | Endpoint | Description |
| :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/login` | Email/password login with Sanctum token issuance |
| **Auth** | `POST` | `/api/logout` | Revokes current Sanctum API token |
| **Feed** | `GET` | `/api/portal/feed` | Paginated community statuses with media embeds |
| **Video Hub** | `GET` | `/api/video/feed` | Dedicated 16:9 main video grid and Shorts clips shelf |
| **Clips** | `GET` | `/api/clips` | Vertical 9:16 short-form video reels |
| **Notifications** | `GET` | `/api/notifications` | Paginated notifications (`?filter=all/mentions/reactions/comments`) |
| **Notifications** | `GET` | `/api/notifications/unread-count` | Real-time total and categorized unread counters |
| **Notifications** | `POST` | `/api/notifications/:id/read` | Mark single notification as read |
| **Notifications** | `POST` | `/api/notifications/read-all` | Mark all notifications as read |
| **Notifications** | `DELETE` | `/api/notifications/:id` | Delete notification item permanently |
| **FCM Push** | `POST` | `/api/settings/device-token` | Register or update FCM registration token |
| **Preferences** | `GET` | `/api/settings/notifications` | Fetch Push and Email notification preferences |
| **Preferences** | `POST` | `/api/settings/notifications` | Update granular Push and Email preferences |
| **Messages** | `GET` | `/api/messages` | Active conversations list |
| **Messages** | `GET` | `/api/messages/:identifier` | 1-on-1 chat history with messages |
| **Messages** | `POST` | `/api/messages/:identifier` | Send text or attachment message |
| **Profile** | `GET` | `/api/profile/:username` | User profile, stats, badges, and VIP status |
