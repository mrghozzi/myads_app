# Troubleshooting, FAQ & Testing

A reference guide for diagnosing common build errors, runtime exceptions, and performance issues.

---

## 1. Common Build & Runtime Issues

### 1.1 "flutter_secure_storage requires minSdkVersion >= 23"
* **Cause:** `minSdk` in `android/app/build.gradle.kts` is set to 21.
* **Fix:** Open `android/app/build.gradle.kts` and set `minSdk = 23`.

### 1.2 "Android Gradle Plugin / Kotlin version mismatch"
* **Cause:** Outdated Kotlin version in Gradle settings.
* **Fix:** Verify `android/settings.gradle.kts` contains:
  ```kotlin
  id("org.jetbrains.kotlin.android") version "2.2.20" apply false
  ```

### 1.3 "SocketException: OS Error: Connection refused"
* **Cause:** Connecting to `http://localhost` from an Android Emulator.
* **Fix:** The Android emulator loopback IP is `10.0.2.2`. In `.env`, set:
  ```env
  BASE_URL=http://10.0.2.2/myads/api
  ```

### 1.4 "401 Unauthorized" Loop on Fresh App Launch
* **Cause:** Invalid or missing `MOBILE_API_KEY` in `.env`.
* **Fix:** Ensure `MOBILE_API_KEY` in `.env` exactly matches the key generated in **MYADS Admin Panel ➔ Mobile App Settings**.

---

## 2. Automated Testing Suite

### 2.1 Running Unit & Widget Tests
```bash
flutter test
```

### 2.2 Formatted Expandable Post Tests
Verify that long post truncation and localized "See more" triggers pass 100%:
```bash
flutter test test/formatted_content_widget_test.dart
```

---

## 3. Performance & Memory Profiling

To ensure 60/120 FPS scrolling on heavy video and image feeds:
1. Run in profile mode on a physical phone:
   ```bash
   flutter run --profile
   ```
2. Open **Flutter DevTools** (press `v` in the terminal).
3. Inspect the **Performance** timeline for raster jank.
4. Verify memory allocation in the **Memory** tab during video playback to ensure disposed controllers are cleanly garbage collected.
