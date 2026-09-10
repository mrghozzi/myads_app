# Member Profiles & Subscriber Tiers

The **Member Profile (`ProfileScreen`)** presents a comprehensive overview of user identities, social connections, post history, and earned badges.

---

## 1. Visual Anatomy & Theme Parity

The profile screen is styled to match the MYADS default web theme:
* **Parallax Cover Header:** High-resolution cover photo with parallax scroll physics.
* **Vertical Hexagonal Avatar:** Custom clip path rendering avatars in a distinct hexagon shape.
* **Online Presence Dot:** Real-time green indicator when the member has active sessions.
* **Verified Badge:** Blue checkmark icon for verified community members.
* **Stats Capsule:** Compact row displaying total Posts, Followers count, and Following count.

---

## 2. Dynamic Subscriber Tier Avatar Borders

Subscribed members display dynamic, color-coded glowing borders around their avatars based on active paid plan tiers:

| Tier Level | Border Styling | Glow Color |
| :--- | :--- | :--- |
| **Free / Standard** | Subtle border | Grey / Transparent |
| **Silver Tier** | Metallic silver | `#C0C0C0` |
| **Gold Tier** | Vibrant gold gradient | `#FFD700` |
| **Diamond Tier** | Cyan / Diamond gradient | `#00E5FF` |
| **Super Admin** | Emerald royal gradient | `#10B981` |

These dynamic colors are synchronized with the web's subscription engine, ensuring seamless visual continuity across mobile and desktop.

---

## 3. Tabbed Profile Layout

1. **Timeline Tab:** Infinite-scroll stream of posts published by the user.
2. **Photos Tab:** Image-only gallery grid filtering media from the user's timeline.
3. **About Tab:** Extended user bio, join date, website links, and social accounts strip. User points (PTS) are kept private to protect member wallet balances.

---

## 4. Click-to-Profile Navigation

Tapping avatars or usernames anywhere in the app (feed posts, comments, chat headers, clips) initiates GoRouter navigation:
```dart
context.push('/profile?username=${user.username}');
```
