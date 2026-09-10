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
│   └── widgets/           # Global shared UI components (MyAdsScaffold, etc.)
├── features/              # Feature modules containing screens and feature widgets
│   ├── auth/              # Login & registration screens
│   ├── billing/           # Paid subscriptions & billing screens
│   ├── clips/             # Short-form vertical video clips feed
│   ├── explore/           # Discovery, search, and action cards
│   ├── forums/            # Discussion forums, categories, and topics
│   ├── gamification/      # Points (PTS), quests, and badges
│   ├── home/              # Main community feed, PostCard, post details
│   ├── messages/          # 1-on-1 private messaging and chat screen
│   ├── notifications/     # In-app notifications center
│   ├── orders/            # Digital marketplace order tracking
│   ├── posts/             # Post composer and multimedia upload
│   ├── profile/           # User profile, cover header, subscriber tier borders
│   ├── settings/          # Account, security, sessions, and preferences
│   ├── shell/             # Bottom navigation shell layout
│   ├── splash/            # Startup splash screen & token verification
│   ├── store/             # Product catalog and digital store
│   └── video/             # Dedicated Video Hub (/video)
├── l10n/                  # Localization ARB dictionaries and generated classes
│   ├── app_ar.arb         # Arabic translations
│   ├── app_en.arb         # English translations
│   └── app_localizations.dart # Generated localization accessors
└── main.dart              # Application entry point
```

---

## 3. Directory Breakdown & Responsibilities

### 3.1 `lib/core/models/`
Encapsulates all domain and data transfer models. Key models include:
* `status_model.dart`: Core feed post entity, supporting quote reposts, rich media, and engagement counters.
* `user_model.dart`: Profile entity with support for `public_uid` strings, online status, and subscription tier indicators.
* `attachment_model.dart`: Encapsulates attached media (images, videos, music, files).

### 3.2 `lib/core/network/`
* `api_client.dart`: Dio singleton instance initialized with `BaseOptions`.
* `api_interceptor.dart`: Intercepts every outgoing request to attach `X-API-KEY`, Bearer tokens, and localization headers.

### 3.3 `lib/core/services/`
* `secure_storage_service.dart`: Interacts with Android Keystore via `flutter_secure_storage` to persist tokens safely.
* `push_notification_service.dart`: Firebase Cloud Messaging lifecycle management.
* `reaction_service.dart`: Reusable reactions and like dispatchers.

### 3.4 `lib/features/`
Each feature directory contains:
* **Screens:** Stateful or stateless widgets representing complete pages (e.g. `video_hub_screen.dart`).
* **Widgets:** Sub-components specific to that feature (e.g. `post_card.dart` in `home/`).
* **Providers (optional):** Feature-specific Riverpod providers (e.g. `video_hub_provider.dart`).

---

## 4. Coding Standards & Conventions

1. **File Naming:** Always use `snake_case.dart` for all file names.
2. **Class Naming:** Use `PascalCase` for classes, widgets, and models.
3. **Variable & Function Naming:** Use `camelCase`.
4. **Const Constructors:** Use `const` whenever possible to optimize Flutter's widget rebuild tree.
5. **Private Members:** Prefix internal implementation details with `_` (e.g. `_dio`, `_rootNavigatorKey`).
