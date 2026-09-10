# Mobile Security & Hardening

The MYADS Mobile App integrates comprehensive security hardening across network protocols, HTML rendering engines, and external URI handlers.

---

## 1. Network Security Configuration (`network_security_config.xml`)

Located in `android/app/src/main/res/xml/network_security_config.xml`, this file strictly enforces HTTPS and blocks cleartext HTTP traffic in production builds:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Strict HTTPS Enforcement in Production -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>

    <!-- Development-Only Cleartext Exceptions -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

---

## 2. HTML Content Hardening & Tag Blocklists

User posts may contain rich formatted HTML. The `flutter_html` rendering widget implements an aggressive tag blocklist to prevent HTML injection, clickjacking, and form phishing:

```dart
Html(
  data: cleanHtmlString,
  tagsList: Html.tags..removeWhere((tag) => [
    'form',
    'input',
    'button',
    'select',
    'textarea',
    'script',
    'iframe',
    'object',
    'embed',
    'applet',
  ].contains(tag.toLowerCase())),
)
```

---

## 3. Safe URL Launching (`SafeUrlLauncher`)

To guard against malicious URI handlers (such as `file://`, `intent://`, or `content://` schemes), all outgoing links pass through `SafeUrlLauncher`:

```dart
class SafeUrlLauncher {
  static const _allowedSchemes = ['http', 'https', 'mailto', 'tel'];

  static Future<bool> launchSafely(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      debugPrint('Blocked unsafe URI scheme: $urlString');
      return false;
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

---

## 4. Server Error Message Sanitization

When backend exceptions occur, raw database stack traces or server IP addresses are stripped before displaying messages to users:
* Replaces SQL error strings (`SQLSTATE[...]`) with friendly localized messages.
* Removes local file paths (`/var/www/myads/...`).
