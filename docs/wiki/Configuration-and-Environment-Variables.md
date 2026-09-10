# Configuration & Environment Variables

The MYADS Mobile App utilizes `flutter_dotenv` to separate environment configurations from source code, enabling safe switching between local development, staging, and production environments.

---

## 1. The `.env` Configuration File

Create a `.env` file in the root directory of `myads_app/` (copy from `.env.example`):

```bash
cp .env.example .env
```

### 1.1 Variable Specifications

```env
# URL to your MYADS Laravel REST API (must end with /api without trailing slash)
BASE_URL=https://your-domain.com/api

# Mobile API Key generated from MYADS Admin Panel -> Mobile App Settings
MOBILE_API_KEY=your_admin_generated_mobile_api_key
```

| Key | Description | Example |
| :--- | :--- | :--- |
| `BASE_URL` | Absolute URL to the MYADS backend API endpoint. | `https://adstn.ovh/api` |
| `MOBILE_API_KEY` | Client-level authentication key validating mobile app access. | `3a9f7b1c8e2d4f5a6b7c8d9e0f1a2b3c` |

> [!WARNING]
> Do NOT commit `.env` containing production secrets to public source control. `.env` is included in `.gitignore`.

---

## 2. Asset Registration in `pubspec.yaml`

To ensure `flutter_dotenv` can bundle and read `.env` during compilation, it must be explicitly declared under `flutter.assets`:

```yaml
flutter:
  assets:
    - .env
    - assets/images/
```

---

## 3. How Configuration is Loaded in Code

During app startup in `main.dart`, the environment file is loaded asynchronously before `runApp()` executes:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MyAdsApp(),
    ),
  );
}
```

The `ApiClient` singleton automatically consumes these values:
```dart
class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost/myads/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ))..interceptors.add(ApiInterceptor());
}
```

---

## 4. Server-Side Compatibility & Reverse Proxies

Some shared hosting providers or web application firewalls (e.g. Cloudflare, ModSecurity, Apache `mod_headers`) strip standard `Authorization` headers.

To guarantee zero connection drops, `ApiInterceptor` sends redundant fallback headers:
* `Authorization: Bearer <token>`
* `X-Authorization: Bearer <token>`
* `X-Api-Token: Bearer <token>`
* `X-API-KEY: <MOBILE_API_KEY>`

On the Laravel backend, `CheckMobileApiKey` middleware inspects these headers automatically.
