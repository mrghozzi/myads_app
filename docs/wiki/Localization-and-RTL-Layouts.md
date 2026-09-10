# Localization & RTL Layouts

The MYADS Mobile App provides native support for **Arabic (العربية)** and **English**, featuring automatic **Right-to-Left (RTL)** layout adaptation.

---

## 1. Architecture of ARB Dictionaries

Localization resources reside in `lib/l10n/`:
* `app_en.arb`: English source dictionary.
* `app_ar.arb`: Arabic target translations.

### Example Dictionary Entry:
```json
{
  "seeMore": "See more",
  "@seeMore": { "description": "Button to expand long post text" },
  "seeLess": "See less",
  "@seeLess": { "description": "Button to collapse long post text" }
}
```

```json
{
  "seeMore": "رؤية المزيد",
  "seeLess": "رؤية أقل"
}
```

---

## 2. Automatic RTL Layout Directionality

When Arabic is selected:
1. Flutter's `Directionality` switches automatically to `TextDirection.rtl`.
2. Navigation animations, icons (back arrows), drawer reveals, and horizontal lists flip automatically.
3. Margin and padding conventions use `EdgeInsetsDirectional` (`start` and `end`) rather than hardcoded `left` and `right`.

---

## 3. Server Header Injection

Whenever the active language is updated, `LocaleProvider` stores the choice:
```dart
prefs.setString('language_code', langCode);
```
In `ApiInterceptor`, all future HTTP requests automatically send:
```http
Accept-Language: ar
X-Locale: ar
```
Ensuring error messages, system announcements, and automated emails are rendered in the member's chosen language.

---

## 4. Adding a New Language

1. Add a new `.arb` file (e.g. `lib/l10n/app_fr.arb` for French).
2. Translate all string keys matching `app_en.arb`.
3. Add the locale in `MaterialApp.supportedLocales`.
4. Run:
   ```bash
   flutter gen-l10n
   ```
