# Design System & Material 3 Theming

The MYADS Mobile App features a sleek, modern visual aesthetic built on **Material 3 (M3)** with custom Vikinger social design tokens, integrating Google Fonts typography, glassmorphism, hexagonal avatars, and dynamic dark/light mode switching.

---

## 1. Color Palette & Brand Tokens

The app's color scheme is configured in `lib/core/theme/app_theme.dart`:

| Token Name | Hex Code | Visual Meaning & Role |
| :--- | :--- | :--- |
| **Vikinger Primary** | `#615DFA` | Primary brand purple/indigo; main action buttons, active navigation, glowing indicators. |
| **Vikinger Cyan** | `#23D2E2` | Secondary accent; comments, highlight chips, watch page elements. |
| **Love / Reaction** | `#E83E8C` | Heart reactions, like badges, floating heart animations. |
| **Success / Follow** | `#10B981` | Follower notifications, completed orders, verified status. |
| **Warning / Store** | `#F59E0B` | Store purchases, orders, milestone delivery alerts. |
| **Gamification Gold** | `#FFB800` | Points (PTS), daily quest trophies, gamification ranks. |
| **Dark Surface Root** | `#0F172A` | Slate 900 root screen canvas in Dark Mode. |
| **Dark Card Surface** | `#1E2338` | Vikinger card surface, bottom sheets, snackbar overlays. |
| **Light Surface Root** | `#FFFFFF` | Clean white canvas in Light Mode. |
| **Light Card Surface** | `#F8FAFC` | Subtle off-white card container background in Light Mode. |

---

## 2. Vikinger Hexagonal Avatars (`HexagonAvatar`)

A signature element of the MYADS ecosystem is the vertical hexagonal profile avatar (`lib/core/widgets/hexagon_avatar.dart`):

```dart
HexagonAvatar(
  avatarUrl: user.avatarUrl,
  size: 44.0,
  isVerified: user.isVerified,
  isOnline: user.isOnline,
  borderColor: isUnread ? const Color(0xFF615DFA) : Colors.grey.withOpacity(0.3),
)
```

### 2.1 Geometry & Drawing
* **Width-to-Height Ratio:** $1 : 1.08$ for vertical hexagon orientation matching the web frontend.
* **Canvas Clip Path:** Drawn with rounded corners using 6 calculated vertices.
* **Badges & Overlays:**
  * **Verified Checkmark Badge:** Embedded at the bottom-left vertex.
  * **Online Status Indicator:** Neon green dot embedded at the top-right vertex.
  * **Interaction Overlay Badge:** 18px circle embedded at the bottom-right for notification types (❤️, 💬, @, 👤, 🏆).

---

## 3. Typography (`Outfit` Font Family)

The app utilizes Google Fonts' **Outfit** typeface:
* High legibility across both Latin and Arabic letterforms.
* Configured directly through `google_fonts: ^8.1.0`:

```dart
TextTheme appTextTheme = GoogleFonts.outfitTextTheme(
  ThemeData(brightness: brightness).textTheme,
);
```

---

## 4. Notifications & Interaction UI Tokens

### 4.1 Filter Chips
* **Unselected:** Bordered chip with subtle background (`#1E2338` in Dark, `#F1F3F9` in Light).
* **Selected:** Filled with `#615DFA` with white bold typography.
* **Unread Counter Pill:** Dynamic badge capsule inside the chip showing unread items count (`99+` max cap).

### 4.2 Social Notification Card
* **Unread State:** Tinted with `#615DFA` (12% opacity in dark mode, 6% in light mode) plus a glowing 10px purple dot with box shadow.
* **Read State:** Transparent background, standard font weights.
* **Dismiss Gesture:** Slides smoothly with red background (`Colors.redAccent`) revealing an animated delete icon.

---

## 5. Dark & Light Theme Switching

Theme preferences are persisted across app sessions via `SharedPreferences`:
* Automatically adapts to system brightness (`ThemeMode.system`).
* Allows manual override in **Settings ➔ Display** (`ThemeMode.light` / `ThemeMode.dark`).
* Smooth micro-transitions between modes with zero flicker.
