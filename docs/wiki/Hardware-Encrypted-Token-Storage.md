# Hardware-Encrypted Token Storage

Plaintext storage of authentication credentials in `SharedPreferences` is a severe mobile security vulnerability. The MYADS Mobile App uses **`flutter_secure_storage`** to safeguard tokens using hardware-backed cryptographic modules.

---

## 1. Cryptographic Architecture (Android Keystore)

On Android, `flutter_secure_storage` uses the **Android Keystore Provider**:
* Sensitive values are encrypted with **AES-256 GCM**.
* The AES encryption key is sealed inside the hardware-isolated Keystore (TEE / Secure Element / StrongBox).
* Even if an attacker gains root access or inspects the file system, encrypted payloads cannot be decrypted without physical access to the device's hardware cryptographic coprocessor.

```
┌────────────────────────────────────────────────────────┐
│                   Flutter Application                  │
│             SecureStorageService.getToken()            │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│              flutter_secure_storage Plugin             │
└───────────────────────────┬────────────────────────────┘
                            │ Requests Decryption
┌───────────────────────────▼────────────────────────────┐
│               Android Keystore System                  │
│       (Hardware TEE / Secure Element AES-256)          │
└────────────────────────────────────────────────────────┘
```

---

## 2. The `SecureStorageService` Implementation

All token operations are encapsulated inside `lib/core/services/secure_storage_service.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String _keyToken = 'auth_token';

  /// Save token with hardware-backed encryption
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Retrieve decrypted token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Remove token on logout
  static Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
  }
}
```

### 2.1 Android Options
* `encryptedSharedPreferences: true`: Uses Android Jetpack Security's `MasterKey` and `EncryptedSharedPreferences`.
* `resetOnError: true`: Automatically recovers and resets storage if hardware key corruption occurs (e.g. after major OS upgrades).

---

## 3. Storage Separation Policy

| Data Type | Storage Mechanism | Rationale |
| :--- | :--- | :--- |
| **Sanctum Bearer Token** | `FlutterSecureStorage` | Sensitive credential, requires hardware encryption. |
| **Locale Preference (`language_code`)** | `SharedPreferences` | Non-sensitive, requires synchronous instant read. |
| **Theme Mode (Dark / Light)** | `SharedPreferences` | Non-sensitive UI preference. |
