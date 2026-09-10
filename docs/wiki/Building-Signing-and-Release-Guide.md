# Building, Signing & Release Guide

This guide covers the complete procedure for building, digitally signing, and packaging the MYADS Mobile App for production distribution on Android.

---

## 1. Android Keystore Generation

Generate a release signing key using Java `keytool`:

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias myads-app-key
```

Save `release-keystore.jks` in a secure location outside the repository or in `android/app/`.

---

## 2. Configuring `key.properties`

Create `android/key.properties` (ignored by git):

```properties
storePassword=YourStorePassword
keyPassword=YourKeyPassword
keyAlias=myads-app-key
storeFile=release-keystore.jks
```

In `android/app/build.gradle.kts`, load signing configuration:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 3. Building Release Packages

### 3.1 Production APK (Direct Download / Sideloading)
```bash
flutter build apk --release
```
* **Output:** `build/app/outputs/flutter-apk/app-release.apk`

### 3.2 Production App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
* **Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## 4. Modern Android Toolchain Verification

* **Kotlin Gradle Plugin:** Configured at **`2.2.20`** in `settings.gradle.kts` to meet modern Flutter 3.27+ engine requirements.
* **JVM Target:** Configured for **Java 17**.
* **minSdkVersion:** Set to **23** (Android 6.0 Marshmallow) for Keystore compatibility.
