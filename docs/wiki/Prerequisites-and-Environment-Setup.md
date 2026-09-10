# Prerequisites & Environment Setup

This guide walks you through setting up your local workstation to build, run, and debug the **MYADS Mobile Application** from source.

---

## 1. System Requirements

| Tool | Recommended Version | Minimum Required |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.27.x` or later | `3.27.0` |
| **Dart SDK** | `3.10.x` or later | `3.10.1` |
| **Java Development Kit (JDK)** | OpenJDK 17 | JDK 17 (Required by Gradle 8+) |
| **Android SDK** | API 34 (Android 14) | API 23 (Android 6.0) |
| **Android Studio** | Latest Stable (Ladybug / Koala) | Hedgehog |

> [!IMPORTANT]
> **Minimum SDK 23 Requirement:**
> The `flutter_secure_storage` package relies on Android Keystore hardware-backed encryption, which mandates a minimum Android SDK version of **23**. Ensure `minSdk` in `android/app/build.gradle.kts` is >= 23.

---

## 2. Installing Flutter & Dependencies

### 2.1 Verify Flutter Installation
Check your Flutter toolchain by executing:
```bash
flutter doctor -v
```
Ensure that the Android toolchain, Chrome, and your IDE (Android Studio / VS Code) report green checkmarks.

### 2.2 Clone the Repository
```bash
git clone https://github.com/mrghozzi/myads_app.git
cd myads_app
```

### 2.3 Fetch Dependencies
Download all packages declared in `pubspec.yaml`:
```bash
flutter pub get
```

### 2.4 Generate Localization Files
Compile the `.arb` dictionary files into Dart classes:
```bash
flutter gen-l10n
```

---

## 3. Configuring the Android Development Environment

### 3.1 JDK 17 Configuration
Modern Android Gradle Plugins require **Java 17**. Verify your active Java version:
```bash
java -version
```
If using Android Studio, navigate to:
**Settings ➔ Build, Execution, Deployment ➔ Build Tools ➔ Gradle ➔ Gradle JDK**, and select **JDK 17**.

### 3.2 Setting Up an Android Emulator
1. Open Android Studio and launch **Virtual Device Manager**.
2. Click **Create Device**. Select a device definition (e.g., Pixel 7 or Pixel 8).
3. Select a system image running **API 33 or API 34** (Google Play / x86_64).
4. Finish creation and start the emulator.

### 3.3 Physical Device Debugging
1. On your Android device, go to **Settings ➔ About Phone** and tap **Build Number** 7 times to enable **Developer Options**.
2. In **Developer Options**, enable **USB Debugging**.
3. Connect your device via USB. Verify connectivity:
   ```bash
   flutter devices
   ```

---

## 4. Verifying Build Readiness

Run static analysis to confirm there are no syntax or configuration errors:
```bash
flutter analyze
```
Launch the app in debug mode on your connected device or emulator:
```bash
flutter run
```
