# MYADS Mobile App

> **Version:** 1.8.3+25 | **Platform:** Android | **Framework:** Flutter 3.27+ / Dart 3.10+

The official first-party mobile client for the [MYADS](https://github.com/mrghozzi/myads) social network, marketplace, and ad exchange platform. Built with Flutter and powered by the MYADS Laravel REST API (Sanctum).

---

## Features

### Navigation & Shell
- **Bottom Navigation Bar:** Provides seamless access to Home, Clips, Explore, Profile, and Settings.
- **Nested Routing:** Implemented using GoRouter's `ShellRoute`.
- **Tap-to-Scroll-to-Top:** Re-selecting the Home navigation tab while already viewing the home screen smoothly scrolls the feed back to the top.
- **Localization:** Native support for English and Arabic. The app automatically adapts to RTL layouts and injects `Accept-Language` headers for localized server responses.
- **Expandable Long Posts:** Intelligent truncation with smooth in-place expansion for long posts and reposts with localized "See more" / "See less" ("رؤية المزيد" / "رؤية أقل") toggle buttons and gradient fade.

### Feed & Bookmarks
- **Universal Bookmarks (Saved Posts):** Save/bookmark any post across feeds with instant optimistic UI feedback. Dedicated `SavedPostsScreen` (`/saved-posts`) with infinite scroll pagination.
- **Smart Mentions & Hashtags Autocomplete:** Real-time `@` user and `#` tag suggestion overlay when composing posts in `ComposerScreen`.
- **Rich Reactions & Engagement:** Multi-reaction picker, threaded comments, quote reposting, and content sharing via native share sheets.

### Video Hub & Clips
- **Dedicated Video Hub Screen (`/video`):** Full mobile parity with the web Video Hub, featuring Glassmorphic Hero Header with search bar, Category Filter Pills (`All`, `Videos`, `Shorts Clips`, `Trending`, `Latest`), 16:9 Spotlight Hero Video Card, horizontal YouTube Shorts Clips shelf, and responsive 16:9 Video Grid.
- **1-Tap Accessibility:** Fast navigation access via a dedicated Video Hub action button (`ondemand_video_rounded`) in `MyAdsScaffold` app bar and a prominent YouTube-styled action card in `ExploreScreen` Discover section.
- **Strict Video Content Isolation:** Powered by `/api/video/feed` (`VideoApiController.php`), enforcing strict `s_type` scoping (`whereIn('s_type', [10, 2, 4, 100])` for main videos and `14` for clips) to guarantee non-video items are excluded.
- **Short-form Clips:** Native vertical-swipe, short-form video experience with full interaction suite (Like, Comment, Share, Save) and dedicated saved clips library.

### Multimedia Details
- **Video & Clips** — Rich player cards with a play overlay, file name, and a "Tap to play" hint. Videos display at 16:9, Clips at 9:16.
- **Audio & Music** — Styled player cards with a decorative waveform visualization. Green accent for audio, orange for music.
- **Image Gallery** — Smart grid layouts: side-by-side for 2 images, hero + row for 3–4, with a "+N" overflow badge for 5 or more images. Full-screen zoomable lightbox viewer.
- **File Attachments** — Cards with a file icon, original name, human-readable size, and a download action.
- **Media Badges** — Color-coded type indicators on posts (Video 🔵, Audio 🟢, Clips 🟠, Music 🟡, File 🔘).

### Social & Member Profiles
- **Profile Privacy & About Dossier (v1.8.3):** 3-tier privacy engine (`public`, `followers`, `private`) matching MYADS core v4.6.3. Protected About section displays a locked container with privacy lock icon when restricted, preventing unauthorized bio leaks. Direct `about_visibility` selector dropdown in Profile Settings.
- **Premium Profiles:** View member profiles (`ProfileScreen`) designed to match the Web default theme layout.
- **Visuals:** Parallax cover header, vertical hexagonal avatar, active online status, and verified badge. The avatar's border color dynamically updates based on the user's active paid plan or Super-Admin role (Gold, Diamond tier colors).
- **Badges & Links:** Premium subscription badge card with tier colors, and a glassmorphic horizontal-scroll social links strip.
- **Stats & Actions:** Detailed stats capsule (posts, followers, following) and follow/unfollow toggle actions.
- **Showcase:** Earned badges showcase list and user bio/signature display.
- **Tabbed Layout:** **Timeline** (user's post history with infinite scroll), **Photos** (filtered user posts with images in a grid layout), and **About** (privacy-governed user bio & dossier).
- **Click-to-Profile Navigation:** Tap on user avatars or usernames anywhere in feed posts, comments, or clips to navigate directly to that member's profile.
- **Profile Navigation Safeguards:** Automatically validates and disables click-to-profile navigation for deleted or unknown users via `UserModel.isValid`, preventing routing crashes.
- **Member ID Privacy:** Full support for `public_member_ids_enabled` — user `id` fields accept both numeric IDs and opaque `public_uid` strings. All API interactions (follow, block, report) use `username` instead of numeric IDs.

### Store Marketplace & Digital Goods
- **Product Catalog (`/store`):** Responsive grid displaying digital products with category filter pills, price tags, and creator info.
- **Ratings & Customer Reviews:** 5-star customer ratings summary card, rating breakdown progress bars, and customer review feed with Verified Buyer badges (`is_verified_buyer`).
- **Interactive Screenshot Lightbox:** Screenshots carousel with tap-to-expand full-screen modal lightbox.
- **Live Demo & Video Walkthroughs:** One-click launcher buttons for testing live web/SaaS demos and viewing video previews.

### Service Orders Marketplace (Freelance Hub)
- **Peer-to-Peer Services (`/orders`):** Comprehensive marketplace matching clients and service providers.
- **P2P Disclaimer Banner:** Prominent platform disclaimer on both list and detail views highlighting direct peer-to-peer accountability.
- **5-Step Milestone Tracking:** Visual milestone stepper (Matching → Awarded → In Progress → Delivered → Completed) with due dates and overdue badges.
- **Requirements & Deliverables:** Interactive file attachments, requirements brief, and deliverable file downloads.
- **Contract Lifecycle:** Riverpod-powered operations for awarding proposals, submitting deliverables, requesting revisions, completing with reviews, and cancelling orders.

### Gamification & Community Forums
- **Quests & Rewards (`/gamification`):** Daily and weekly quest progression tracking, points balance card, and one-tap quest reward claims.
- **Discussion Forums (`/forums`):** Community categories, forum topics, and topic discussion threads.

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
- **Settings Hub:** Dedicated settings screen mirroring the web dashboard with nested panels for Profile, Privacy, Social, Mail Notifications, Active Sessions, Apps, Badges, History, and Ads Analytics.
- **Billing Security:** In-app secure billing and subscription handling (`BillingScreen`).
- **Private Messages:** Full chat interface for 1-on-1 private messaging with unread count badges, encrypted `route_key` conversation navigation, username fallback resolution, and real-time polling via `/api/messages/updates`.
- **Notifications:** Integrated in-app notifications center with dynamic unread indicators and mark-all-read support.

---

## Architecture

```text
lib/
├── core/
│   ├── models/              # Data models (StatusModel, UserModel, OrderModel, ProductModel, etc.)
│   ├── network/             # Dio API client, interceptors, and error handlers
│   ├── providers/           # Riverpod global state providers (auth, feed, theme)
│   ├── routes/              # Declarative GoRouter routing definitions
│   ├── services/            # Business logic (SecureStorageService, ReactionService, Notifications)
│   ├── theme/               # Material 3 light/dark theme definitions & tokens
│   ├── utils/               # Helpers (UrlHelper, SafeUrlLauncher, DateFormatters)
│   └── widgets/             # Reusable UI widgets (cards, avatars, overlays)
├── features/
│   ├── auth/                # Login & registration screens
│   ├── billing/             # Billing & subscription webview
│   ├── clips/               # Short-form video player & feed
│   ├── explore/             # Search, trending tags, and category discovery
│   ├── forums/              # Forums categories, topics, and thread discussions
│   ├── gamification/        # Quests, achievements, and PTS balance
│   ├── home/                # Feed screen, PostCard, comments, and post details
│   ├── messages/            # Conversations list and real-time chat screen
│   ├── notifications/       # Push notifications & in-app activity center
│   ├── orders/              # Service orders marketplace, milestones, and lifecycle
│   ├── posts/               # Composer screen, saved bookmarks, autocomplete
│   ├── profile/             # Profile screen, About privacy dossier, badges
│   ├── settings/            # Settings Hub & 9 sub-screens (Privacy, Profile, Social, etc.)
│   ├── shell/               # Bottom navigation bar & scaffold shell
│   ├── splash/              # Token verification & startup routing
│   ├── store/               # Digital products store, customer reviews, screenshot viewer
│   └── video/               # Dedicated Video Hub, YouTube Shorts shelf, video grid
└── main.dart                # App entry point & dependency injection
```

### Key Patterns
| Pattern | Implementation |
|---------|---------------|
| State Management | Riverpod `AsyncNotifier` & `StateNotifier` |
| HTTP Client | Dio with custom interceptors for token/API-key injection |
| Routing | GoRouter with auth guards and `ShellRoute` |
| Theming | Material 3 with Google Fonts (Outfit), dark/light mode |
| Data Layer | Immutable model classes with `fromJson` factories & `copyWith` |
| Token Storage | `flutter_secure_storage` (Android Keystore encryption) |
| URL Safety | `SafeUrlLauncher` with scheme whitelisting |

---

## Setup

### Prerequisites
- Flutter SDK 3.27+
- Android SDK (API 21+)
- A running MYADS backend instance (v4.6.3+) with the API enabled

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
  Fetches and downloads all the packages and dependencies listed in your `pubspec.yaml` file.

- **`flutter gen-l10n`**  
  Generates localization and translation files based on the `.arb` files in `lib/l10n/` (Arabic & English).

- **`flutter analyze`**  
  Scans the entire Dart codebase to identify syntax errors, unused imports, or bad coding practices.

- **`flutter test`**  
  Executes unit and widget tests across models, state notifiers, and UI components.

- **`flutter run`**  
  Compiles the application and launches it on a connected device/emulator in debug mode with Hot Reload.

### Build APK
```bash
flutter build apk --release
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^3.3.1 | Reactive state management |
| `dio` | ^5.9.2 | HTTP networking & API client |
| `go_router` | ^17.2.3 | Declarative routing & nested navigation |
| `flutter_secure_storage` | ^9.2.4 | Encrypted credential storage (Android Keystore) |
| `shared_preferences` | ^2.5.5 | Non-sensitive preferences storage |
| `flutter_dotenv` | ^6.0.1 | Environment variables configuration |
| `google_fonts` | ^8.1.0 | Custom typography (Outfit) |
| `flutter_html` | ^3.0.0 | HTML content rendering with security tag blocklist |
| `video_player` / `chewie` | ^2.9.6 / ^1.10.0 | Native video and clips playback |
| `just_audio` | ^0.9.46 | Native audio and music playback |
| `cached_network_image` | ^3.3.1 | High-performance image caching |
| `webview_flutter` | ^4.14.1 | Secure in-app webview integration |
| `share_plus` | ^12.0.2 | Native share sheet |
| `url_launcher` | ^6.3.1 | External URL & safe link launcher |

---

## API Requirements

The app requires the MYADS backend API (v4.6.3+) with the following:
- Laravel Sanctum enabled
- Admin-generated API key configured in `.env` (sent via the `X-API-KEY` header only)
- API rate limiting enabled: `/api/login` (5/min), `/api/register` (3/min)
- `StatusResource` returning `repost_record`, `media`, `gallery`, `has_saved`, and `attachments`
- `UserResource` returning `publicRouteIdentifier()` when `public_member_ids_enabled` is active
- 3-Tier Profile Privacy engine returning `can_view_about` and `about_visibility`
- Store Marketplace API supporting product ratings, reviews (`is_verified_buyer`), and screenshot galleries
- Service Orders API supporting milestone progress, attachments, deliverables, and revision workflows
- Full Gamification Quests API support (`/api/gamification/quests` and claim endpoints)
- Enhanced Settings API with dual-schema support (Profile, Privacy, Social, Notifications, Badges)

See `Documents/API_DOCS.md` in the main project for full endpoint documentation.

---

## License

MIT — Part of the MYADS v4.6.3 project by mrghozzi.

