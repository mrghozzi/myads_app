# In-App Notifications & Badge Counters

In addition to system push notifications, the MYADS Mobile App provides a dedicated **In-App Notification Center (`/notifications`)** and dynamic unread badge indicators.

---

## 1. Unread Badge Indicators

The top app bar in `MyAdsScaffold` features real-time badge counters:
* **Bell Icon:** Displays unread notification count.
* **Envelope Icon:** Displays unread private message count.

Badges update automatically whenever feed data refreshes or when receiving foreground FCM messages.

---

## 2. Notification Types & Icons

| Notification Action | Icon / Color | Tap Destination |
| :--- | :--- | :--- |
| **Post Liked / Reacted** | ❤️ Red Heart | Opens `PostDetailsScreen` (`/post/:id`) |
| **New Comment** | 💬 Blue Bubble | Opens `PostDetailsScreen` scrolled to comments |
| **New Follower** | 👤 Green User | Opens `ProfileScreen` (`/profile?username=...`) |
| **Quote Repost** | 🔁 Purple Repost | Opens `PostDetailsScreen` |
| **System Announcement** | 📢 Amber Megaphone | Opens notification details dialog |

---

## 3. Mark All as Read Action

Tapping the checkmark icon in the notification screen header triggers:
```dart
await ApiClient.instance.post('/notifications/mark-read');
```
Instantly clearing all unread badge counts across the app.
