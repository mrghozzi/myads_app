# Project Structure & Directory Guide

This document details the organization of the **MYADS Flutter Mobile Application** repository, explaining directory conventions, file responsibilities, and coding standards.

---

## 1. Top-Level Directory Layout

```
myads_app/
├── android/               # Android native project files, Gradle scripts, manifests
├── assets/                # Static assets (brand icons, splash images)
│   └── images/            # PNG/SVG graphics (icon.png, etc.)
├── build/                 # Generated compilation artifacts (git-ignored)
├── docs/                  # Project documentation & GitHub Wiki repository
│   └── wiki/              # Markdown wiki documentation files
├── lib/                   # Dart source code root
├── test/                  # Unit and widget test suites
├── .env.example           # Template for environment configuration
├── analysis_options.yaml  # Linting rules and static analysis config
├── l10n.yaml              # Flutter localization generator configuration
└── pubspec.yaml           # Project metadata, dependencies, asset declarations
```

---

## 2. Dart Source Organization (`lib/`)

The application code inside `lib/` follows a **Feature-First** modular structure:

```
lib/
├── core/                  # Shared infrastructure used across multiple features
│   ├── models/            # Core data transfer objects (StatusModel, UserModel, etc.)
│   ├── network/           # HTTP client, interceptors, error handling
│   ├── providers/         # Global Riverpod state providers (auth, locale, feed)
│   ├── routes/            # GoRouter configuration and route definitions
│   ├── services/          # Low-level platform services (FCM, secure storage)
│   ├── theme/             # Material 3 colors, typography, theme data
│   ├── utils/             # Reusable utility functions (SafeUrlLauncher, helpers)
│   └── widgets/           # Global shared UI components (HexagonAvatar, MyAdsScaffold)
├── features/              # Feature modules containing screens and feature widgets
│   ├── auth/              # Login & registration screens
│   ├── billing/           # Paid subscriptions & billing screens
│   ├── clips/             # Short-form vertical video clips feed
│   ├── explore/           # Discovery, search, and action cards
│   ├── forums/            # Discussion forums, categories, and topics
│   ├── gamification/      # Points (PTS), quests, and badges
│   ├── home/              # Main community feed, PostCard, post details
│   ├── messages/          # 1-on-1 private messaging and chat screen
│   ├── notifications/     # Notifications center (models, providers, screens)
│   │   ├── models/        # NotificationModel & NotificationSender
│   │   ├── providers/     # Riverpod notificationProvider
│   │   └── screens/       # NotificationsScreen with category chips & swipe-to-delete
│   ├── orders/            # Digital marketplace order tracking
│   ├── posts/             # Post composer and multimedia upload
│   ├── profile/           # User profile, cover header, subscriber tier borders
│   ├── settings/          # Account, security, sessions, and notification preferences
│   ├── shell/             # Bottom navigation shell layout & header badge
│   ├── splash/            # Startup splash screen & token verification
│   ├── store/             # Product catalog and digital store
│   └── video/             # Dedicated Video Hub (/video) & Shorts shelf
├── l10n/                  # Localization ARB dictionaries and generated classes
│   ├── app_ar.arb         # Arabic translations
│   ├── app_en.arb         # English translations
│   └── app_localizations.dart # Generated localization accessors
└── main.dart              # Application entry point, Firebase init & intent listeners
```

---

## 3. Directory Breakdown & Responsibilities

### 3.1 `lib/core/models/`
Encapsulates all domain and data transfer models. Key models include:
* `status_model.dart`: Core feed post entity, supporting quote reposts, rich media, and engagement counters.
* `user_model.dart`: Profile entity with support for `public_uid` strings, online status, and subscription tier indicators.
* `attachment_model.dart`: Encapsulates attached media (images, videos, music, files).

### 3.2 `lib/core/network/`
* `api_client.dart`: Dio singleton instance initialized with `BaseOptions`, connection timeouts, and standard headers.
* `api_interceptor.dart`: Intercepts every outgoing request to attach `X-API-KEY`, Bearer tokens, and localization headers.

### 3.3 `lib/core/services/`
* `secure_storage_service.dart`: Interacts with Android Keystore / iOS Keychain via `flutter_secure_storage` to persist tokens safely.
* `push_notification_service.dart`: Firebase Cloud Messaging lifecycle management, background handlers, foreground floating banners, and deep-link routing.

### 3.4 `lib/core/widgets/`
* `hexagon_avatar.dart`: Reusable Vikinger-style hexagonal avatar with online indicators and verified badges.
* `myads_scaffold.dart`: Universal app shell containing the logo, Video Hub shortcut, reactive unread notification badge, messages shortcut, and user avatar.

### 3.5 `lib/features/notifications/`
* `models/notification_model.dart`: `NotificationModel` and `NotificationSender` with JSON serialization.
* `providers/notification_provider.dart`: Riverpod `Notifier` managing unread counts, category filters, infinite scroll pagination, and optimistic updates.
* `screens/notifications_screen.dart`: Complete screen featuring category chips (**الكل**, **الإشارات**, **التفاعلات**, **التعليقات**), `Dismissible` swipe-to-delete, and pull-to-refresh.

---

## 4. Coding Standards & Conventions

1. **File Naming:** Always use `snake_case.dart` for all file names.
2. **Class Naming:** Use `PascalCase` for classes, widgets, and models.
3. **Variable & Function Naming:** Use `camelCase`.
4. **Const Constructors:** Use `const` whenever possible to optimize Flutter's widget rebuild tree.
5. **Private Members:** Prefix internal implementation details with `_` (e.g. `_dio`, `_rootNavigatorKey`).
6. **State Management:** Prefer modern Riverpod `Notifier<T>` and `NotifierProvider<Notifier, State>` over legacy `StateNotifier`.
