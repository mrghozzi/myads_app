# Troubleshooting, FAQ & Testing

A reference guide for diagnosing common build errors, runtime exceptions, push notification issues, and executing automated test suites.

---

## 1. Common Build & Runtime Issues

### 1.1 "flutter_secure_storage requires minSdkVersion >= 23"
* **Cause:** `minSdk` in `android/app/build.gradle.kts` is set below 23.
* **Fix:** Open `android/app/build.gradle.kts` and ensure `minSdk = 23`.

### 1.2 "Android Gradle Plugin / Kotlin version mismatch"
* **Cause:** Outdated Kotlin version in Gradle settings.
* **Fix:** Verify `android/settings.gradle.kts` contains:
  ```kotlin
  id("org.jetbrains.kotlin.android") version "2.2.20" apply false
  ```

### 1.3 "SocketException: OS Error: Connection refused"
* **Cause:** Connecting to `http://localhost` from an Android Emulator.
* **Fix:** The Android emulator loopback IP for the host machine is `10.0.2.2`. In `.env`, set:
  ```env
  BASE_URL=http://10.0.2.2/myads/api
  ```
  On a physical device over Wi-Fi, use your machine's LAN IP (e.g. `http://192.168.1.100/myads/api`).

### 1.4 "401 Unauthorized" Loop on Fresh App Launch
* **Cause:** Invalid or missing `MOBILE_API_KEY` in `.env`.
* **Fix:** Ensure `MOBILE_API_KEY` in `.env` exactly matches the key generated in **MYADS Admin Panel ➔ Mobile App Settings**.

### 1.5 "Firebase initialization error (Missing google-services.json?)"
* **Cause:** Firebase Core cannot locate the configuration file.
* **Fix:** Ensure `google-services.json` is located directly in `myads_app/android/app/google-services.json`. The app is designed to catch this gracefully during development so non-push features continue operating.

### 1.6 "Push notifications not appearing or tapping does nothing"
* **Check Device Token Registration:** Verify via debug console that `POST /api/settings/device-token` returns `{"success": true}`.
* **Check Notification Permission:** Android 13+ requires runtime permission (`POST_NOTIFICATIONS`). Ensure the user granted permission.
* **Check Backend Credentials:** In Laravel `.env`, ensure `FIREBASE_PROJECT_ID` and `FIREBASE_CREDENTIALS` (or `FCM_SERVER_KEY`) are set.
* **Check Deep Link Route:** Verify the payload includes `'target_route': '/post?id=...'`. If missing, GoRouter defaults to `/notifications`.

---

## 2. Automated Testing Suites

### 2.1 Running Flutter Unit & Widget Tests
```bash
flutter test
```

### 2.2 Formatted Expandable Post Tests
Verify that long post truncation, formatted Markdown/HTML parsing, and localized "See more" triggers pass:
```bash
flutter test test/formatted_content_widget_test.dart
```

### 2.3 Running Flutter Static Code Analysis
Ensure the codebase adheres to strict linting rules without errors or unhandled deprecations:
```bash
flutter analyze --no-fatal-infos
```

### 2.4 Running Backend Notification API Tests
Verify that the Laravel API for categorized notifications, unread counts, and deep routes passes 100%:
```bash
php artisan test tests/Feature/MobileNotificationApiTest.php
```

Expected output:
```text
PASS  Tests\Feature\MobileNotificationApiTest
✓ can fetch notifications with rich metadata and filtering (3.68s)

Tests: 1 passed (19 assertions)
```

---

## 3. Performance & Memory Profiling

To ensure smooth 60/120 FPS scrolling across feeds with media:
1. Run in profile mode on a physical phone:
   ```bash
   flutter run --profile
   ```
2. Open **Flutter DevTools** (press `v` in the terminal).
3. Inspect the **Performance** timeline for raster jank.
4. Verify memory allocation in the **Memory** tab during video playback to ensure disposed Chewie/VideoPlayer controllers are cleanly garbage collected.
