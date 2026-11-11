# In-App Notifications & Badge Counters

The MYADS Mobile App features a **Tier-1 Social Notification Center (`/notifications`)** designed to compete with the experience of leading social platforms like X/Twitter, Instagram, and TikTok. It includes multi-category tab filtering, rich avatar cards with interaction badges, swipe gestures, infinite scrolling, and dynamic reactive unread counters across the application shell.

---

## 1. System Overview & UI Design

```
┌────────────────────────────────────────────────────────┐
│  🔔 الإشعارات [ 12 ]                             [✓✓]  │  <-- Header with Unread Pill & Mark All Read
├────────────────────────────────────────────────────────┤
│  [⭐ الكل (12)]  [@ الإشارات (3)]  [❤️ التفاعلات (6)]   │  <-- Scrollable Filter Chips with Badges
├────────────────────────────────────────────────────────┤
│  [⬡ Avatar]  mrghozzi reacted to your clip            │
│    ❤️ badge   منذ 3 دقائق                     [● Glow] │  <-- Vikinger Card with Relative Time
├────────────────────────────────────────────────────────┤
│  [⬡ Avatar]  Lara mentioned you in a comment          │
│    @ badge   منذ ساعتين                               │  <-- Tap navigates to /post?id=261
├────────────────────────────────────────────────────────┤
│  <<< Swipe Left to Delete [ 🗑️ Red Background ]       │  <-- Dismissible Gesture with Instant Sync
└────────────────────────────────────────────────────────┘
```

---

## 2. Reactive State Management (`notificationProvider`)

State is managed by a Riverpod `Notifier` in `lib/features/notifications/providers/notification_provider.dart`:

```dart
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final Map<String, int> filterCounts;
  final String selectedFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => fetchUnreadCount());
    return const NotificationState();
  }

  Future<void> setFilter(String filter) async { ... }
  Future<void> fetchNotifications({bool refresh = false}) async { ... }
  Future<void> loadMore() async { ... }
  Future<void> fetchUnreadCount() async { ... }
  Future<void> markAsRead(int id) async { ... }
  Future<void> markAllRead() async { ... }
  Future<void> deleteNotification(int id) async { ... }
}
```

### 2.1 Optimistic UI Updates
When a user marks a notification as read or swipes to delete, the local state updates **immediately (0ms UI latency)** before sending the network request to the backend:
* **Mark as Read:** Clears `isUnread` and decrements `unreadCount`.
* **Swipe-to-Delete:** Drops the item from the list, recalculates unread counts, and fires `DELETE /api/notifications/:id`.

---

## 3. Category Filter Chips

The notification center provides 4 instant filtering tabs, each displaying its own live unread counter badge:

| Filter Key | Label | Icon | Query Parameter | Types Displayed |
| :--- | :--- | :--- | :--- | :--- |
| `all` | **الكل** | `Icons.all_inbox_rounded` | `?filter=all` | All interactions, quests, and orders |
| `mentions` | **الإشارات** | `Icons.alternate_email_rounded` | `?filter=mentions` | `@username` mentions in comments & posts |
| `reactions` | **التفاعلات** | `Icons.favorite_rounded` | `?filter=reactions` | Likes, Loves, and emoji reactions |
| `comments` | **التعليقات** | `Icons.chat_bubble_rounded` | `?filter=comments` | Comments and forum replies |

Tapping any chip triggers an optimistic category switch and refreshes the paginated list.

---

## 4. Rich Social Notification Cards

Each notification item rendered in `NotificationsScreen` features:

1. **Sender Avatar (`HexagonAvatar`):**
   * Displays the actor's profile photo in a Vikinger hexagonal border.
   * Renders a verified checkmark badge for verified creators.
   * If the notification is a system quest or store order, displays a themed icon circle.
2. **Sub-Icon Badge Overlay:**
   A small circular badge positioned at the bottom-right corner of the avatar communicates the interaction type at a glance:
   * ❤️ **Heart (`#E83E8C`):** Post reactions and likes.
   * 💬 **Chat Bubble (`#23D2E2`):** Direct comments and replies.
   * 🏷️ **Alternate Email (`#615DFA`):** `@mentions`.
   * 👤 **User Plus (`#10B981`):** New followers.
   * 🏆 **Trophy (`#FFB800`):** Completed daily quests and achievements.
   * 🛍️ **Shopping Bag (`#F59E0B`):** Store orders and billing milestones.
3. **Relative Timestamps:**
   Powered by Carbon on the backend and relative formatting on the client (e.g. `منذ دقيقتين`, `منذ ساعتين`, `أمس`, `منذ أسبوع`).
4. **Unread Visual Indicator:**
   * Subtle `#615DFA` primary background tint (12% opacity in Dark Mode, 6% in Light Mode).
   * A 10px glowing neon dot on the trailing edge.

---

## 5. Gestures & Navigation

### 5.1 Swipe-to-Delete (`Dismissible`)
Members can swipe any notification card horizontally to delete it:
* Smooth slide animation revealing a red `Colors.redAccent` background with a trash icon.
* Immediate removal from Riverpod state with a temporary SnackBar confirmation.
* Asynchronous dispatch to `DELETE /api/notifications/:id`.

### 5.2 Deep-Link Routing on Tap
Tapping a notification automatically marks it as read and evaluates `target_route`:
* If `targetRoute == '/post?id=123'`, opens `PostDetailsScreen`.
* If `targetRoute == '/clips/208'`, opens `ClipsScreen` at that clip.
* If `targetRoute == '/messages/alice'`, opens `ChatScreen`.
* If `targetRoute == '/orders/2'`, opens `OrderDetailScreen`.

---

## 6. App Shell Header Badge (`MyAdsScaffold`)

In `lib/features/shell/widgets/myads_scaffold.dart`, the notifications bell icon dynamically watches `notificationProvider`:

```dart
Consumer(
  builder: (context, ref, _) {
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));
    return IconButton(
      icon: unreadCount > 0
          ? Badge(
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF615DFA),
              child: const Icon(Icons.notifications_active_outlined),
            )
          : const Icon(Icons.notifications_none),
      tooltip: 'الإشعارات',
      onPressed: () => context.push('/notifications'),
    );
  },
)
```

---

## 7. Dual-Preference Notification Settings

Inside `NotificationsSettingsScreen` (`/settings/notifications`), users have granular toggles for both **Mobile Push Alerts** and **Email Notifications**:

### Push Notifications Section:
* 🔔 Mentions & `@username` tags
* 💬 Direct private messages
* 👤 New followers
* 📝 Comments on user's posts
* ❤️ Likes & reactions

### Email Notifications Section:
* ✉️ Email on new mention
* ✉️ Email on new private message
* ✉️ Email on new follower
* ✉️ Email on new comment

---

## 8. Backend API Contract

| Endpoint | Method | Description | Request / Query |
| :--- | :--- | :--- | :--- |
| `/api/notifications` | `GET` | Paginated notification stream | `?page=1&filter=all` |
| `/api/notifications/unread-count` | `GET` | Total and categorized unread counts | None |
| `/api/notifications/:id/read` | `POST` | Mark single notification as read | None |
| `/api/notifications/read-all` | `POST` | Mark all notifications as read | None |
| `/api/notifications/:id` | `DELETE` | Delete individual notification | None |
| `/api/settings/notifications` | `GET` | Get push & email notification preferences | None |
| `/api/settings/notifications` | `POST` | Update notification preferences | Payload with boolean toggles |
