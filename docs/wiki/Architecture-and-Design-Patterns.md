# Architecture & Design Patterns

The **MYADS Mobile Application** is engineered following modern Flutter best practices, emphasizing **Clean Architecture**, **Single Responsibility Principle (SRP)**, and **Unidirectional Data Flow**.

---

## 1. High-Level Architectural Layers

The codebase is partitioned into three distinct vertical layers:

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                    │
│   (Screens, Widgets, ShellRoute, Material 3 Theme)      │
└────────────────────────────┬────────────────────────────┘
                             │ Watches / Dispatches
┌────────────────────────────▼────────────────────────────┐
│                    Application Layer                    │
│   (Riverpod Notifiers, State Management, Controllers)   │
└────────────────────────────┬────────────────────────────┘
                             │ Calls
┌────────────────────────────▼────────────────────────────┐
│                  Data & Network Layer                   │
│   (Dio Client, ApiInterceptor, Models, SecureStorage)   │
└─────────────────────────────────────────────────────────┘
```

### 1.1 Presentation Layer
- Built with Flutter Material 3 widgets with custom Vikinger/Superdesign tokens.
- Separated into **Screens** (top-level route targets) and reusable **Widgets** (dumb presentation components).
- Relies on GoRouter for declarative navigation and nested shell layouts.
- Consumes state via `ConsumerWidget` or `ConsumerStatefulWidget` without embedding raw business logic.

### 1.2 Application Layer (State Management)
- Powered exclusively by **Riverpod 3**.
- Employs modern `Notifier<T>` and `NotifierProvider<Notifier, State>` architecture.
- State mutations trigger immutable updates (`state = state.copyWith(...)`), guaranteeing zero UI race conditions.
- Optimistic updates provide instant UI feedback during social interactions (likes, read status, dismiss gestures).

### 1.3 Data & Network Layer
- **Dio Client:** Encapsulates network transport with connection and receive timeout configurations.
- **Interceptors:** Automatically injects security headers (`X-API-KEY`, `Authorization: Bearer <token>`) and language headers (`Accept-Language`, `X-Locale`).
- **Data Models:** Immutable Dart classes featuring explicit `fromJson` and `toJson` serialization factories.
- **Hardware-Backed Storage:** Tokens are encrypted on-device via `flutter_secure_storage` backed by Android Keystore / iOS Keychain.

---

## 2. Unidirectional Data Flow Pattern

```mermaid
sequenceDiagram
    participant User as User Interaction
    participant Widget as View (ConsumerWidget)
    participant Provider as Riverpod Notifier
    participant Dio as ApiClient / Interceptor
    participant Backend as Laravel REST API

    User->>Widget: Taps "Like" or "Follow"
    Widget->>Provider: Calls provider.toggleLike(postId)
    Note over Provider: Optimistic UI Update (Immediate response)
    Provider->>Dio: POST /api/statuses/{id}/like
    Dio->>Backend: Request with Sanctum Token & X-API-KEY
    Backend-->>Dio: 200 OK (updated status)
    Dio-->>Provider: Parsed StatusModel
    Provider-->>Widget: Emits state change to subscribers
```

---

## 3. Key Design Patterns Implemented

### 3.1 Singleton Pattern (`ApiClient`, `PushNotificationService`)
Critical services that manage persistent connection pools or external SDK instances are implemented as thread-safe singletons:
```dart
class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost/myads/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ))..interceptors.add(ApiInterceptor());

  static Dio get instance => _dio;
}
```

### 3.2 Interceptor Pattern (`ApiInterceptor`)
All outgoing HTTP requests and incoming responses pass through `ApiInterceptor`, centralizing authentication, header injection, localization headers, and error logging in one place.

### 3.3 Modern Riverpod Notifier Pattern (`notificationProvider`, `feedProvider`)
Stateful business logic uses Riverpod 3's `Notifier<T>` pattern:
```dart
class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => fetchUnreadCount());
    return const NotificationState();
  }

  Future<void> markAsRead(int id) async {
    // Optimistic local state update
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.id == id ? n.copyWith(isUnread: false) : n).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
    await ApiClient.instance.post('/notifications/$id/read');
  }
}
```

### 3.4 Deep-Linking & Shell Navigation (`GoRouter`)
The root navigator coordinates full-screen dialogs and modal screens while child routes mount inside `ShellRoute` (`MainShellScreen`):
* Deep-linking maps incoming paths (`/post?id=123`, `/clips/:id`, `/messages/:username`) directly to target components.
* `rootNavigatorKey` enables services (such as FCM foreground notifications) to display global overlays and navigate without BuildContext passing.

### 3.5 Defensive Data Model Pattern
To guard against deleted users or partially corrupted database records, models provide validation getters rather than raw property checks:
```dart
bool get isValid => id.isNotEmpty && id != '0' && username.isNotEmpty && username != 'unknown';
```

---

## 4. Architectural Best Practices

1. **Zero Raw HTTP in Widgets:** Screens must never call `Dio` directly. All network requests must flow through dedicated providers or services.
2. **Immutable State:** Avoid in-place mutations of lists or model instances. Always create new collections using `.map()`, `copyWith()`, or list spreads `[...items]`.
3. **Graceful Degradation:** When optional relations are missing (e.g. `repost_record`, `attachments`), models safely fallback to null or empty collections without throwing exceptions.
4. **Optimistic Operations with Safe Rollback:** Update UI immediately, then revert if server responds with error.
