# MYADS Mobile App

> **Version:** 1.2.2 | **Platform:** Android | **Framework:** Flutter 3.27+ / Dart

The official first-party mobile client for the [MYADS](https://github.com/mrghozzi/myads) social network & ad exchange platform. Built with Flutter and powered by the MYADS Laravel REST API (Sanctum).

---

## Features

### Navigation & Shell
- Bottom Navigation Bar with easy access to Home, Clips, Explore, Profile, and Settings
- Nested routing with GoRouter's `ShellRoute`
- **Tap-to-Scroll-to-Top:** Re-selecting the Home navigation tab while already viewing the home screen smoothly scrolls the feed back to the top.
- **Localization:** Native support for English and Arabic. App automatically adapts RTL layouts, and injects `Accept-Language` headers for localized server responses.

### Community Feed
- Browse the community feed with pull-to-refresh and smart ranking
- **Infinite Scroll Pagination:** Automatically fetches and appends next pages as the user scrolls near the bottom of the feed.
- **Pulsing Skeleton Loaders:** High-fidelity, pulsing `PostSkeleton` widgets render during initial load and paginated fetches, dynamically adapting to light/dark themes.
- View all post types: text, images, video, audio, music, clips, and file attachments
- **Quote Reposts (Shares):** Renders a beautifully nested original post card inline when a post is a share/repost, showing original creator info (avatar, name, verified status), text, and original media elements/players recursively.
- React with emoji reactions (Like ðŸ‘, Love, Haha, Wow, Sad, Angry) via long-press picker, with dynamic backend syncing to trigger gamification points and notifications natively.
- Comment on posts with inline composer
- Share posts via native share sheet

### Publishing & Content Creation
- **Premium Post Composer:** Redesigned post composer adhering to `.superdesign` styling, featuring rich media previews, interactive attachment chips, and dynamic post-type selection.
- **External Share Intents:** Share text, links, and media (images, videos, files) from any external Android application directly into the MYADS composer as a draft.
- **Promoted Posts (Ads):** Integrated rendering of Promoted Posts injected natively into the community feed with a prominent "Promoted" (Ù…ÙÙ…ÙˆÙ‘Ù„) badge.
- **SafeArea Support:** Global protection to prevent UI elements from overlapping with Android system navigation gestures.

### Clips System
- Native vertical-swipe short-form video experience
- Native video playback via `video_player`
- Full interaction suite: Like, Comment, Share, and Save
- Dedicated 'Saved Clips' grid for users to revisit favorite content

### Multimedia Support
- **Video & Clips** â€” Rich player cards with play overlay, file name, and "Tap to play" hint. Videos display at 16:9, Clips at 9:16. Opens in external player.
- **Audio & Music** â€” Styled player cards with decorative waveform visualization. Green accent for audio, orange for music.
- **Image Gallery** â€” Smart grid layouts: side-by-side for 2 images, hero + row for 3â€“4, with "+N" overflow badge for 5+.
- **File Attachments** â€” Cards with file icon, original name, human-readable size, and download action.
- **Media Badges** â€” Color-coded type indicators on posts (Video ðŸ”µ, Audio ðŸŸ¢, Clips ðŸŸ£, Music ðŸŸ , File ðŸ”˜).

### Social & Member Profiles
- View premium member profiles (`ProfileScreen`) designed matching the Web default theme layout.
- Parallax cover header, vertical hexagonal avatar, active online status, and verified badge. The avatar's border color dynamically updates based on the user's active paid plan or Super-Admin role (e.g. Gold, Diamond tier colors), matching the web's dynamic tier styling.
- Premium subscription badge card with tier colors, and a glassmorphic horizontal-scroll social links strip.
- Detailed stats capsule (posts, followers, following) and follow/unfollow toggle action.
- Earned badges showcase list and user bio/signature display.
- Tabbed layout: **Timeline** (user's post history with infinite scroll), **Photos** (filtered user posts with images in a grid layout), and **About** (comprehensive user bio, keeping user points/PTS private).
- **Click-to-Profile Navigation:** Tap on user avatars or usernames anywhere in feed posts, comments, or clips to navigate directly to that member's profile.
- **Profile Navigation Safeguards:** Automatically validates and disables click-to-profile navigation for deleted or unknown users (e.g. username is 'unknown' or ID is 0) to prevent routing crashes.

### Authentication & Security
- Secure login with two-layer API authentication (API key + Sanctum Bearer token)
- **Encrypted Token Storage:** Auth tokens stored via `flutter_secure_storage` (Android Keystore hardware encryption), replacing plaintext `SharedPreferences`
- **Token Validation on Startup:** Splash screen validates tokens server-side before navigating â€” stale/revoked tokens are automatically cleared
- **HTTPS Enforcement:** `network_security_config.xml` blocks cleartext traffic in production; dev-only exceptions for localhost
- **Error Sanitization:** Server error messages are stripped of hostnames, IPs, and SQL details before display
- **HTML Content Hardening:** `flutter_html` tag blocklist prevents rendering of phishing-capable HTML elements (form, input, script, iframe, etc.)
- **URL Scheme Validation:** `SafeUrlLauncher` utility blocks dangerous URI schemes (file://, intent://, content://) before external launch
- Auto-redirect to login on token expiry (401/403 interceptor)

### Personalization & Communication
- **Settings Hub**: A dedicated settings screen mirroring the web dashboard with nested panels for Account, Privacy, Social, Mail Notifications, Active Sessions, and Badges.
- **Billing Security**: Monetization and subscription buttons safely launch into the system browser via `url_launcher`, ensuring financial data is handled outside the native mobile context.
- **Private Messages**: Full chat interface for 1-on-1 private messaging with unread count badges, encrypted `route_key` conversation navigation, username fallback resolution, and real-time polling via `/api/messages/updates`.
- **Notifications**: Integrated in-app notifications center with dynamic unread indicators.

---

## Architecture

```
lib/
â”œâ”€â”€ core/
â”‚   â”œâ”€â”€ models/              # Data models (StatusModel, UserModel, AttachmentModel, etc.)
â”‚   â”œâ”€â”€ network/             # Dio API client and interceptor
â”‚   â”œâ”€â”€ providers/           # Riverpod state providers (auth, feed, profile)
â”‚   â”œâ”€â”€ services/            # Business logic (ReactionService, SecureStorageService)
â”‚   â”œâ”€â”€ utils/               # Helpers (UrlHelper, SafeUrlLauncher)
â”‚   â””â”€â”€ themes/              # Material 3 light/dark theme definitions
â”œâ”€â”€ features/
â”‚   â”œâ”€â”€ auth/                # Login screen
â”‚   â”œâ”€â”€ home/                # Feed screen, PostCard widget, post details
â”‚   â””â”€â”€ posts/               # Profile screen
â””â”€â”€ main.dart                # App entry point
```

### Key Patterns
| Pattern | Implementation |
|---------|---------------|
| State Management | Riverpod `AsyncNotifier` |
| HTTP Client | Dio with custom interceptor for token/API-key injection |
| Routing | GoRouter with auth guards |
| Theming | Material 3 with Google Fonts (Outfit), dark/light mode |
| Data Layer | Immutable model classes with `fromJson` factories |
| Token Storage | `flutter_secure_storage` (Android Keystore encryption) |
| URL Safety | `SafeUrlLauncher` with scheme whitelist |

---

## Setup

### Prerequisites
- Flutter SDK 3.27+
- Android SDK (API 21+)
- A running MYADS backend instance with API enabled

### Configuration
1. Copy `.env.example` to `.env`:
   ```
   BASE_URL=https://your-site.com/api
   API_KEY=your_admin_generated_api_key
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

> âš ï¸ **Important:** The `flutter_secure_storage` package requires a minimum Android SDK 23 (6.0). Ensure your `minSdkVersion` is set accordingly in `android/app/build.gradle`.
3. Run on device/emulator:
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

The app requires the MYADS backend API (v4.3.4+) with the following:
- Laravel Sanctum enabled
- Admin-generated API key configured in `.env` (sent via `X-API-KEY` header only; query parameter not accepted)
- API rate limiting enabled: `/api/login` (5/min), `/api/register` (3/min)
- `StatusResource` returning `repost_record`, `media`, `gallery`, and `attachments` fields
- `Api\ProfileController::statuses()` and `Api\PortalController::index()` calling `decorateMany()` for related content and repost relation hydration

See `Documents/API_DOCS.md` in the main project for full endpoint documentation.

---

## License

MIT â€” Part of the MYADS v4.3.4 project by mrghozzi.

