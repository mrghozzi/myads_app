# MYADS Mobile App — Changelog

---

## v1.4.6+6
> **Bug Fixes & Security Enhancements** — Fixed critical authentication and API communication issues.

### Bug Fixes
* **Authentication Flow**: Replaced `flutter_secure_storage` with `shared_preferences` to bypass widespread Android Keystore initialization bugs on specific OEM devices (e.g., Xiaomi/MIUI), ensuring reliable token persistence.
* **Splash Screen Token Validation**: Updated `splash_screen.dart` to validate tokens against the standard `/user` API endpoint instead of the obsolete `/settings/account` endpoint, ensuring correct startup routing.
* **Aggressive WAF Evasion**: Modified `ApiInterceptor` to inject `X-Authorization` and `X-Api-Token` headers alongside the standard `Authorization` header, successfully bypassing strict ModSecurity and Cloudflare rules on shared hosting environments (e.g., adstn.ovh) that strip standard auth headers.
* **JSON Parsing Fix (BOM Removal)**: Diagnosed and resolved a critical issue where the server returned invisible UTF-8 BOM characters (`\xef\xbb\xbf`) before JSON responses when non-English localization (e.g., French) was active. This prevented `Dio` from parsing the successful 200 OK login response, causing a false "Login failed" error in the app. Cleaned BOM from all PHP translation files.


## v1.4.5+5
> **Feature & Bug Fixes** — Explore Screen Redesign, Store & Forums API integration.

### Core Features
* **Explore Screen (Superdesign)**: Redesigned the explore screen using the `.superdesign` styling, featuring premium grid layouts for Stores (Products), Forums (Categories & Topics), and dynamic search functionality.

### Bug Fixes
* **Store Integration**: Fixed `TypeError` (`type 'String' is not a subtype of type 'int'`) in `store_provider.dart` caused by incorrect JSON list mapping, allowing products and categories to load seamlessly.
* **Store Data Mapping**: Updated product item mappings in Flutter to use `thumbnail` and `title` keys instead of legacy `img` and `name` to correctly match `ProductResource` API output.
* **Store Knowledgebase Fix**: Fixed `knowledgebaseProvider` to correctly access nested data arrays in the paginated response, preventing infinite loading on product detail screens.
* **Forums Integration**: Resolved an issue where selecting a Forum category hung indefinitely. The backend API was returning `403 Unauthorized` due to a mismatch in `visibility` logic. The app now correctly handles and displays public, member, and moderator categories and topics.


## v1.4.4+4
> **Bug Fix** — Fixed an issue where the user object was missing in the API responses.

### Bug Fixes
* **Missing User in Feed:** The backend has been updated to correctly retrieve and include the user relation in the `/portal` and `/profile` APIs, resolving the "unknown" display name and missing profile pictures issue in the mobile app.

---

## v1.4.3
> **Stability & UI Rendering Fixes** — Provider migrations and User data hydration.

### Critical Fixes
* **Riverpod 3 Migration**: Migrated state management providers from `StateNotifier` to `AsyncNotifier` / `Notifier` to ensure compatibility with Riverpod 3.0+ and resolve compilation errors.
* **Community Feed User Hydration**: Fixed a backend serialization issue where the API failed to load the post creator's data (`user`) for community feed responses, which caused the Mobile App to display "unknown" for all names and default avatars. The app now correctly displays the user's name, username, verified badge, and custom hexagon avatar.
* **Firebase Initialization Guard**: Wrapped `Firebase.initializeApp()` in a `try-catch` block within `main.dart` to prevent the app from hard-crashing on startup when Firebase configuration is missing.

---

## v1.4.2
> **Authentication Stability Update** — Bypassed Android Keystore bugs and Shared Hosting header stripping.

### Critical Fixes
* **Keystore Bug Bypass**: Replaced `flutter_secure_storage` with `shared_preferences` to fix a major issue where the Sanctum Token was silently dropped by MIUI/Xiaomi devices, causing immediate logouts.
* **Shared Hosting Header Fix**: Implemented a fallback `X-Authorization` header sent by the app, which the backend `index.php` dynamically maps back to `Authorization`. This permanently solves issues with `Bearer` tokens being stripped by LiteSpeed, FastCGI, or cPanel security rules, preventing `401 Unauthenticated` errors.

---

## v1.4.1
> **Private Messages Fix** — Resolved a critical red-screen crash on the Messages page caused by API response format mismatches and null safety violations.

### Critical Fixes
* **Red Screen Crash**: Fixed a fatal error on `MessagesListScreen` where the API returned a `message` object and an `unread` boolean, but the Flutter client expected a `last_message` object and an `unread_count` integer. The backend now returns the correct field names.
* **HexagonAvatar Null Crash**: Fixed a `type 'Null' is not a subtype of type 'String'` error in both `MessagesListScreen` and `ChatScreen` when a partner's avatar (`img`) was `null`. Added a `?? ''` fallback for null-safe string coercion.

### API Enhancements
* **Conversation Route Keys**: The `/api/messages` response now includes a `route_key` for each conversation, enabling the mobile app to navigate using encrypted conversation identifiers instead of plain usernames (which had caused 404 errors on the backend).
* **Updates Endpoint**: Added the `GET /api/messages/updates` endpoint for real-time polling of new messages and global unread counts.
* **Mark As Read**: Added `POST /api/messages/{identifier}/read` for marking conversations as read.
* **Username Fallback**: `MessageConversationService::resolvePartner` now accepts both encrypted route keys and plain usernames, enabling direct profile-to-message navigation.

### Bug Fixes
* **Chat Sender Detection**: Updated `ChatScreen` to handle both nested `sender` objects and flat `us_env` fields from the API response to prevent incorrect message bubble alignment.

---

## v1.2.2
> **Security Hardening** — Comprehensive security audit and remediation across the authentication, network transport, content rendering, and data storage layers.

### Critical Fixes
* **Encrypted Token Storage**: Migrated authentication token storage from plaintext `SharedPreferences` (unencrypted XML) to `flutter_secure_storage` backed by Android Keystore (hardware-level encryption). Created a centralized `SecureStorageService` (`core/services/secure_storage_service.dart`) with save, read, delete, and clear operations.
* **API Key Git Protection**: Added `.env` to `.gitignore` to prevent API keys from being committed to version control. Created an `.env.example` template with placeholder values for safe onboarding.

### High Fixes
* **HTTPS Enforcement**: Replaced blanket `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` with a dedicated `network_security_config.xml` that enforces HTTPS globally, while allowing cleartext only for `localhost` and `10.0.2.2` (emulator) during development.
* **Error Message Sanitization**: Rewrote `AuthNotifier` error handling to strip server hostnames, IP addresses, SQL state strings, and file paths from user-facing error messages. Added dedicated handling for HTTP 429 (rate limit) responses.
* **Debug Output Guarding**: Wrapped all `debugPrint()` calls in `kDebugMode` checks across `main.dart` and `auth_provider.dart` to prevent information leakage via logcat in release builds.

### Medium Fixes
* **Token Validation on Startup**: Enhanced `SplashScreen` to validate the stored token against the server (`GET /api/settings/account`) before navigating to the home screen. Stale or revoked tokens are now automatically cleared.
* **HTML Content Hardening**: Added a tag blocklist to both `Html` widgets in `PostCard` (main content and repost embed), blocking 12 dangerous HTML tags: `form`, `input`, `textarea`, `select`, `button`, `script`, `iframe`, `object`, `embed`, `meta`, `link`, and `base`.
* **URL Scheme Validation**: Created a `SafeUrlLauncher` utility (`core/utils/safe_url_launcher.dart`) that validates URL schemes (`http`, `https`, `mailto`, `tel` only) before launching, blocking dangerous schemes like `file://`, `intent://`, and `content://`. Applied to `SettingsHubScreen` and `NotificationsScreen`.

### New Files
| File | Purpose |
|------|---------|
| `core/services/secure_storage_service.dart` | Encrypted credential storage via Android Keystore |
| `core/utils/safe_url_launcher.dart` | URL scheme validation before external launch |
| `android/app/src/main/res/xml/network_security_config.xml` | HTTPS enforcement with dev-only exceptions |
| `.env.example` | Safe environment template without real credentials |

### Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_secure_storage` | ^9.2.4 | Encrypted key-value storage (Android Keystore) |

---

## v1.4.0
> **Settings Hub, Messaging, Notifications & Localization** — Added a comprehensive Settings Hub with external billing support, full private messaging, in-app notifications, and complete English/Arabic localization with RTL support.

### Core Features
* **Localization & RTL**: Implemented full `flutter_localizations` support for English and Arabic. Added `LocaleNotifier` for dynamic language switching. The app dynamically adapts to RTL layouts based on the selected language and injects `Accept-Language` headers into API requests for localized backend responses.
* **Settings Hub**: Built a premium Settings screen mimicking the web dashboard, providing access to Account, Privacy, Social Links, Mail Notifications, Active Sessions, Authorized Apps, Badges, and the Points Ledger. 
* **External Billing Integration**: Implemented a secure redirect flow for Monetization and Subscriptions. Tapping these options safely opens the external web browser using `url_launcher`, strictly keeping payment flows outside the native app.
* **Private Messages**: Implemented the `MessagesListScreen` and `ChatScreen` with real-time-like polling, interactive message bubbles, and unread badge counters. Replaced the `authProvider` with `profileDetailProvider('me')` to safely resolve the active user session.
* **Notifications Center**: Added a dedicated `NotificationsScreen` with visual indicators for unread items and click-to-read functionality, ensuring parity with the web's alert system.

### Bug Fixes & Refactoring
* **GoRouter Crash Fix**: Resolved a critical startup crash (`Failed assertion: route.parentNavigatorKey == null`) by moving the Settings sub-screens out of the `ShellRoute` into the root-level routing array, ensuring full-screen modal behavior without conflicting with the bottom navigation shell.
* **UI Deprecations**: Cleaned up deprecated properties (e.g., `activeColor` replaced with `activeThumbColor` in Switches) across the Settings Hub.

---

## v1.3.0
> **Premium Composer, External Intents & Promoted Posts** — Fully redesigned the post composer to match the web's `.superdesign`, added support for sharing text/media from external apps into the composer, introduced global `SafeArea` protections, and implemented full Promoted Posts visibility.

### Core Features
* **Premium Composer UI**: Overhauled the `ComposerScreen` utilizing `.superdesign` guidelines. Added modern inputs, gallery previews, rounded attachment chips, and improved bottom bar controls.
* **External Share Intent**: Integrated `receive_sharing_intent` to allow users to share texts, links, and media (images, videos, files) from external Android applications directly into the MYADS composer as a draft.
* **Promoted Posts Feed Integration**: Upgraded `StatusModel` and `PostCard` to parse and render `isPromotedAd`. Promoted campaigns injected by the server now display beautifully with a dedicated "Promoted" badge alongside the timestamp.

### Bug Fixes & Refactoring
* **Media Upload Payload Fix**: Corrected a bug where multipart uploads for videos, audio, and files were not binding properly to Laravel's request array brackets (`[]`), ensuring reliable multimedia creation from the mobile app.
* **Global SafeArea**: Implemented bottom `SafeArea` padding across all primary screens (`home_screen.dart`, `explore_screen.dart`, `profile_screen.dart`) preventing bottom navigation UI from being obscured by Android system navigation bars.
* **Code Maintenance**: Cleaned up deprecated syntax in `main.dart`, explicitly mapped intent streams, and properly isolated logic blocks in the composer screen to resolve compiler warnings.

---

## v1.2.1
> **Repost & Share Rendering System** — Added inline rendering of shared posts (quote reposts) including original author details, nested text content, and original media elements/players.

### Core Features
* **Quote Repost Rendering**: Updated `PostCard` to parse `repost_record` and render a beautifully nested original post card, supporting the original creator's avatar, name, verification badge, and timestamp.
* **Repost Multimedia Support**: Enabled nested video, clips, audio, music, and file attachments from the original post to render dynamically inside the shared card, matching the web platform's layout and functionality.

---

## v1.2.0
> **Infinite Scrolling & Scroll-to-Top Navigation** — Implemented infinite scroll pagination with pulsing skeletons, home tab double-tap scroll-to-top, and profile click safeguards.

### Core Features
* **Infinite Scroll Pagination**: Integrated automatic loading of next pages when scrolling near the bottom of the community feed.
* **Pulsing Post Skeletons**: Created a beautiful `PostSkeleton` placeholder using custom Flutter animations to render pulsing cards during initial loading and paginated fetches (adapts to light/dark themes).
* **Tap-to-Scroll-to-Top**: Intercepted tab taps on the `MainShellScreen` to allow re-selecting the active Home tab to scroll the community feed smoothly to the top.
* **Profile Click Safeguards**: Added validation in `PostCard`, `ClipsScreen`, and `PostDetailsScreen` (comments) to prevent navigation clicks for deleted or unknown users (where the username is 'unknown' or the ID is 0), resolving potential UI glitches.
* **Riverpod 3.0+ Compliance**: Migrated `homeScrollToTopProvider` from `StateProvider` to a modern `NotifierProvider` subclass to maintain alignment with Riverpod 3.x specifications.

---

## v1.1.0
> **Clips & Navigation Upgrade** — Added a native vertical-swipe Clips system and a unified Bottom Navigation shell.

### Core Features
* **Member Profiles**: Implemented a premium `ProfileScreen` matching the default Web layout using cover photos, stats cards, subscription badges, a glassmorphic social icons strip, a bio, and a badges showcase.
* **Hexagon Avatars**: Created a `HexagonAvatar` custom clipper and border painter to render all member avatars as vertical hexagons across the app (Feed, Comments, Clips, and Profile), featuring dynamic border colors that update automatically to represent the user's active paid subscription plan or Super Admin rank.
* **Navigation**: Integrated click-to-profile routing. Clicking any username or avatar in community feed posts, comments, or clips creator rows navigates directly to that member's profile.
* **Url Helper**: Developed `UrlHelper` to dynamically rewrite localhost asset URLs (from Laravel config) to match the host and port of the configured app API, resolving loading errors on physical devices/emulators.
* **Privacy**: Restricted PTS points balance visibility in the profile's "About" tab to preserve point privacy.
* **Clips**: Implemented full `ClipsScreen` and `SavedClipsScreen` with a native `PageView.builder` for seamless vertical swiping.
* **Navigation (Shell)**: Migrated from simple push routes to a `ShellRoute` with a persistent `BottomNavigationBar` (Home, Clips, Explore, Profile, Settings).
* **UI**: Upgraded `MyAdsScaffold` to natively support Avatar fetching and Verified Badges based on `hasVerifiedBadge()` logic.
* **Video**: Integrated the `video_player` plugin for native playback of clips.

### Bug Fixes & Refactoring
* **Notifications**: Fixed an issue where the post/reel owner was not receiving notifications for reactions because the API could not resolve the true owner ID from the polymorphic subject relationships.
* **Reactions**: Fixed a state mismatch issue where reactions on community posts and clips would reset upon refresh. `StatusModel` now explicitly decodes `interaction_subject_id` and `reaction_type` directly from the API (instead of hardcoding), ensuring that the backend correctly correlates UI interactions with the exact database models (e.g., `type 14` for Clips, `type 2` for posts).
* **Dependencies**: Replaced deprecated `SharePlus.share()` and `.withOpacity()` syntax to clear out Dart analyzer warnings.

---

## v1.0.0+1 (Initial Release)
> **Foundation Release** — Community Feed with full multimedia support, social interactions, and profile viewing.

### Core Features
* **Auth**: Token-based authentication via Laravel Sanctum with two-layer security (API key + Bearer token).
* **Feed**: Community feed with hybrid ranking, pull-to-refresh, and infinite scroll.
* **Reactions**: Full emoji reaction system (Like, Love, Haha, Wow, Sad, Angry) with a long-press picker and optimistic UI updates.
* **Comments**: Post detail screen with an inline comment list and composer.
* **Share**: Native share sheet integration via `share_plus`.
* **Profile**: User profile viewing with a follow/unfollow toggle and profile statuses feed.

### Multimedia Posts
* **Video/Clips**: Rich player cards with a play button overlay, a gradient info bar, and aspect ratio detection (16:9 for video, 9:16 for clips). Tapping opens an external player.
* **Audio/Music**: Accent-colored player cards with a decorative waveform visualization, file name display, and tap-to-play via an external app. Green accent for audio, orange for music.
* **Image Gallery**: Smart grid layout — side-by-side for 2 images, hero image + row for 3-4, with a "+N" overflow badge for 5 or more images.
* **File Attachments**: Styled file cards with an icon, name, human-readable size (B/KB/MB/GB), and download action.
* **Media Badges**: Color-coded post-type indicators (Video 🔵, Audio 🟢, Clips 🟠, Music 🟡, File 🔘) for quick content-type identification.

### Architecture
* **Models**: `StatusModel` with `MediaInfo` and `AttachmentModel` for structured API data parsing.
* **API Client**: Dio-based HTTP client with an interceptor for automatic token injection and API key headers.
* **State**: Riverpod async notifiers for feed state, auth state, and profile state management.
* **Routing**: GoRouter with route guards for authenticated/guest screens.
* **Theming**: Material 3 design with dark and light mode support using Google Fonts (Outfit).

### Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | State management |
| `dio` | ^5.9.2 | HTTP client |
| `shared_preferences` | ^2.5.5 | Token persistence |
| `flutter_dotenv` | ^6.0.1 | Environment configuration |
| `go_router` | ^17.2.3 | Declarative routing |
| `google_fonts` | ^8.1.0 | Typography |
| `flutter_html` | ^3.0.0 | HTML content rendering |
| `share_plus` | ^13.1.0 | Native sharing |
| `url_launcher` | ^6.3.1 | External media playback |
