# MYADS Mobile App

> **Version:** 1.7.6+18 | **Platform:** Android | **Framework:** Flutter 3.27+ / Dart

The official first-party mobile client for the [MYADS](https://github.com/mrghozzi/myads) social network and ad exchange platform. Built with Flutter and powered by the MYADS Laravel REST API (Sanctum).

---

## Features

### Navigation & Shell
- **Bottom Navigation Bar:** Provides easy access to Home, Clips, Explore, Profile, and Settings.
- **Nested Routing:** Implemented using GoRouter's `ShellRoute`.
- **Tap-to-Scroll-to-Top:** Re-selecting the Home navigation tab while already viewing the home screen smoothly scrolls the feed back to the top.
- **Localization:** Native support for English and Arabic. The app automatically adapts to RTL layouts and injects `Accept-Language` headers for localized server responses.

### Video Hub & Video Parity
- **Dedicated Video Hub Screen (`/video`):** Full mobile parity with the web Video Hub, featuring Glassmorphic Hero Header with search bar, Category Filter Pills (`All`, `Videos`, `Shorts Clips`, `Trending`, `Latest`), 16:9 Spotlight Hero Video Card, horizontal YouTube Shorts Clips shelf, and responsive 16:9 Video Grid.
- **1-Tap Accessibility:** Fast navigation access via a dedicated Video Hub action button (`ondemand_video_rounded`) in `MyAdsScaffold` app bar and a prominent YouTube-styled action card in `ExploreScreen` Discover section.
- **Strict Video Content Isolation:** Powered by `/api/video/feed` (`VideoApiController.php`), enforcing strict `s_type` scoping (`whereIn('s_type', [10, 2, 4, 100])` for main videos and `14` for clips) to guarantee non-video items (directory listings `s_type = 1`, store products `s_type = 7867`, news, etc.) are excluded.

### Clips System
- **Short-form Video:** Native vertical-swipe, short-form video experience.
- **Playback:** Native video playback via the `video_player` plugin.
- **Engagement:** Full interaction suite including Like, Comment, Share, and Save.
- **Saved Clips:** Dedicated 'Saved Clips' grid for users to revisit their favorite content.

### Multimedia Details
- **Video & Clips** — Rich player cards with a play overlay, file name, and a "Tap to play" hint. Videos display at 16:9, Clips at 9:16. Opens in an external player.
- **Audio & Music** — Styled player cards with a decorative waveform visualization. Green accent for audio, orange for music.
- **Image Gallery** — Smart grid layouts: side-by-side for 2 images, hero + row for 3–4, with a "+N" overflow badge for 5 or more images.
- **File Attachments** — Cards with a file icon, original name, human-readable size, and a download action.
- **Media Badges** — Color-coded type indicators on posts (Video 🔵, Audio 🟢, Clips 🟠, Music 🟡, File 🔘).

### Social & Member Profiles
- **Premium Profiles:** View premium member profiles (`ProfileScreen`) designed to match the Web default theme's layout.
- **Visuals:** Parallax cover header, vertical hexagonal avatar, active online status, and verified badge. The avatar's border color dynamically updates based on the user's active paid plan or Super-Admin role (e.g., Gold, Diamond tier colors), matching the web's dynamic tier styling.
- **Badges & Links:** Premium subscription badge card with tier colors, and a glassmorphic horizontal-scroll social links strip.
- **Stats & Actions:** Detailed stats capsule (posts, followers, following) and a follow/unfollow toggle action.
- **Showcase:** Earned badges showcase list and user bio/signature display.
- **Tabbed Layout:** **Timeline** (user's post history with infinite scroll), **Photos** (filtered user posts with images in a grid layout), and **About** (comprehensive user bio, keeping user points/PTS private).
- **Click-to-Profile Navigation:** Tap on user avatars or usernames anywhere in feed posts, comments, or clips to navigate directly to that member's profile.
- **Profile Navigation Safeguards:** Automatically validates and disables click-to-profile navigation for deleted or unknown users via the `UserModel.isValid` getter, preventing routing crashes.
- **Member ID Privacy:** Supports the backend's `public_member_ids_enabled` setting — user `id` fields accept both numeric IDs and opaque `public_uid` strings. All API interactions (follow, block, report) use `username` instead of numeric IDs.

### Authentication & Security
- **API Auth:** Secure login with two-layer API authentication (API key + Sanctum Bearer token).
- **Encrypted Token Storage:** Auth tokens are stored via `flutter_secure_storage` (Android Keystore hardware encryption), replacing plaintext `SharedPreferences`.
- **Token Validation on Startup:** The splash screen validates tokens server-side before navigating — stale or revoked tokens are automatically cleared.
- **HTTPS Enforcement:** `network_security_config.xml` blocks cleartext traffic in production, with dev-only exceptions for localhost.
- **Error Sanitization:** Server error messages are stripped of hostnames, IPs, and SQL details before display.
- **HTML Content Hardening:** `flutter_html` tag blocklist prevents the rendering of phishing-capable HTML elements (form, input, script, iframe, etc.).
- **URL Scheme Validation:** The `SafeUrlLauncher` utility blocks dangerous URI schemes (file://, intent://, content://) before an external launch.
- **Expiry Handling:** Auto-redirects to login upon token expiry (via a 401/403 interceptor).

### Personalization & Communication
- **Settings Hub:** A dedicated settings screen mirroring the web dashboard with nested panels for Account, Privacy, Social, Mail Notifications, Active Sessions, and Badges.
- **Billing Security:** Monetization and subscription buttons safely launch into the system browser via `url_launcher`, ensuring financial data is handled outside the native mobile context.
- **Private Messages:** Full chat interface for 1-on-1 private messaging with unread count badges, encrypted `route_key` conversation navigation, username fallback resolution, and real-time polling via `/api/messages/updates`.
- **Notifications:** Integrated in-app notifications center with dynamic unread indicators.

---

## Architecture

```text
lib/
├── core/
│   ├── models/              # Data models (StatusModel, UserModel, AttachmentModel, etc.)
│   ├── network/             # Dio API client and interceptor
│   ├── providers/           # Riverpod state providers (auth, feed, profile)
│   ├── services/            # Business logic (ReactionService, SecureStorageService)
│   ├── utils/               # Helpers (UrlHelper, SafeUrlLauncher)
│   └── themes/              # Material 3 light/dark theme definitions
├── features/
│   ├── auth/                # Login screen
│   ├── home/                # Feed screen, PostCard widget, post details
│   └── posts/               # Profile screen
└── main.dart                # App entry point
```

### Key Patterns
| Pattern | Implementation |
|---------|---------------|
| State Management | Riverpod `AsyncNotifier` |
| HTTP Client | Dio with a custom interceptor for token/API-key injection |
| Routing | GoRouter with auth guards |
| Theming | Material 3 with Google Fonts (Outfit), dark/light mode |
| Data Layer | Immutable model classes with `fromJson` factories |
| Token Storage | `flutter_secure_storage` (Android Keystore encryption) |
| URL Safety | `SafeUrlLauncher` with a scheme whitelist |

---

## Setup

### Prerequisites
- Flutter SDK 3.27+
- Android SDK (API 21+)
- A running MYADS backend instance with the API enabled

### Configuration
1. Copy `.env.example` to `.env`:
   ```env
   BASE_URL=https://your-site.com/api
   API_KEY=your_admin_generated_api_key
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

> ⚠️ **Important:** The `flutter_secure_storage` package requires a minimum Android SDK 23 (6.0). Ensure your `minSdkVersion` is set accordingly in `android/app/build.gradle`.

3. Run on a device/emulator:
   ```bash
   flutter run
   ```

### Development Commands

Here are the essential commands you will use during development and their purposes:

- **`flutter pub get`**
  Fetches and downloads all the packages and dependencies listed in your `pubspec.yaml` file. Run this command whenever you clone the project or add new packages.

- **`flutter gen-l10n`**
  Generates the localization and translation files (like `app_localizations.dart`) based on the `.arb` files located in `lib/l10n/`. You must run this command whenever you add or modify text in your Arabic (`app_ar.arb`) or English (`app_en.arb`) dictionaries.

- **`flutter analyze`**
  Scans the entire Dart codebase to identify syntax errors, unused imports, or bad coding practices. It helps ensure the code is clean and error-free before running or building the application.

- **`flutter run`**
  Compiles the application and launches it on a connected physical device or emulator in debug mode. It also enables "Hot Reload", allowing you to see UI changes instantly without restarting the app.

### Build APK
```bash
flutter build apk --release
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | Reactive state management |
| `dio` | ^5.9.2 | HTTP networking |
| `shared_preferences` | ^2.5.5 | Non-sensitive preferences storage |
| `flutter_secure_storage` | ^9.2.4 | Encrypted credential storage (Android Keystore) |
| `flutter_dotenv` | ^6.0.1 | Environment variables |
| `go_router` | ^17.2.3 | Declarative navigation |
| `google_fonts` | ^8.1.0 | Custom typography |
| `flutter_html` | ^3.0.0 | HTML content rendering (with tag blocklist) |
| `share_plus` | ^13.1.0 | Native share sheet |
| `url_launcher` | ^6.3.1 | External URL/media playback |

---

## API Requirements

The app requires the MYADS backend API (v4.5.2+) with the following:
- Laravel Sanctum enabled
- Admin-generated API key configured in `.env` (sent via the `X-API-KEY` header only; query parameter not accepted)
- API rate limiting enabled: `/api/login` (5/min), `/api/register` (3/min)
- `StatusResource` returning `repost_record`, `media`, `gallery`, and `attachments` fields
- `UserResource` returning `publicRouteIdentifier()` when `public_member_ids_enabled` is active
- `Api\ProfileController::statuses()` and `Api\PortalController::index()` calling `decorateMany()` for related content and repost relation hydration

See `Documents/API_DOCS.md` in the main project for full endpoint documentation.

---

## License

MIT — Part of the MYADS v4.5.2 project by mrghozzi.
