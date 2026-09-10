# Development Workflow & CLI Commands

This guide outlines the standard development workflows, common terminal commands, and debugging techniques used when maintaining the **MYADS Mobile Application**.

---

## 1. Essential Flutter CLI Commands

### 1.1 Dependency Management
* **Download packages:**
  ```bash
  flutter pub get
  ```
* **Check for outdated dependencies:**
  ```bash
  flutter pub outdated
  ```
* **Upgrade minor versions:**
  ```bash
  flutter pub upgrade
  ```

### 1.2 Localization Compilation
Whenever modifying strings in `lib/l10n/app_en.arb` or `lib/l10n/app_ar.arb`, regenerate Dart localization accessors:
```bash
flutter gen-l10n
```

### 1.3 Static Code Analysis
Run Flutter linter to catch unused imports, type mismatches, and deprecation warnings:
```bash
flutter analyze
```

### 1.4 Running the Application
* **Debug Mode (with Hot Reload):**
  ```bash
  flutter run
  ```
* **Target a specific device:**
  ```bash
  flutter run -d <device_id>
  ```
* **Profile Mode (Performance analysis on physical hardware):**
  ```bash
  flutter run --profile
  ```

---

## 2. Interactive Terminal Commands During `flutter run`

When running in debug mode, the interactive CLI terminal accepts single-key commands:

| Key | Action | Description |
| :---: | :--- | :--- |
| `r` | **Hot Reload** | Recompiles changed UI widgets in sub-second time without resetting state. |
| `R` | **Hot Restart** | Restarts the Flutter engine and rebuilds state from scratch. |
| `p` | **Toggle Debug Paint** | Displays visual boundaries, padding, and layout constraints on-screen. |
| `o` | **Toggle Platform** | Simulates switching between Android and iOS design behaviors. |
| `v` | **Open DevTools** | Launches Flutter DevTools in your browser for memory and network profiling. |
| `q` | **Quit** | Terminates the running debug session. |

---

## 3. Testing Suites

Execute automated unit and widget tests:
```bash
flutter test
```
To run a specific test suite (e.g. formatted expandable post widget tests):
```bash
flutter test test/formatted_content_widget_test.dart
```

---

## 4. Cleaning the Build Cache

If encountering strange Gradle build errors or stale cached compilation files:
```bash
flutter clean
flutter pub get
flutter gen-l10n
```
