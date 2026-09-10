# Design System & Material 3 Theming

The MYADS Mobile App features a sleek, modern visual aesthetic built on **Material 3 (M3)**, integrating Google Fonts typography, glassmorphism, and dynamic dark/light mode switching.

---

## 1. Color Palette & Surface Tokens

The app's color scheme is configured in `lib/core/theme/`:

| Token Name | Light Mode Hex | Dark Mode Hex | Usage |
| :--- | :--- | :--- | :--- |
| **Primary Color** | `#6366F1` (Indigo) | `#818CF8` | Main action buttons, active navigation indicators. |
| **Accent Color** | `#F43F5E` (Rose) | `#FB7185` | Heart reactions, notification badges. |
| **Background** | `#F8FAFC` | `#0F172A` (Slate 900) | Root screen canvas. |
| **Surface** | `#FFFFFF` | `#1E293B` (Slate 800) | Post cards, sheets, dialog backgrounds. |
| **Border / Divider**| `#E2E8F0` | `#334155` | Subtle borders, separating lines. |

---

## 2. Typography (`Outfit` Font Family)

The app utilizes Google Fonts' **Outfit** typeface:
* High legibility across both Latin and Arabic letterforms.
* Configured directly through `google_fonts: ^8.1.0`:

```dart
TextTheme appTextTheme = GoogleFonts.outfitTextTheme(
  ThemeData(brightness: brightness).textTheme,
);
```

---

## 3. Dark & Light Theme Switching

Theme preferences are persisted across app sessions via `SharedPreferences`:
* Automatically adapts to system brightness (`ThemeMode.system`).
* Allows manual override in **Settings ➔ Display** (`ThemeMode.light` / `ThemeMode.dark`).

---

## 4. Glassmorphism & Reusable Components

* **`MyAdsScaffold`:** Global top-level layout wrapper with sticky glassmorphic app bar.
* **`CustomButton`:** Accessible buttons with loading spinners and disabled states.
* **`AvatarWidget`:** Hexagonal clipped member avatar with online indicator and tiered subscription glow borders.
