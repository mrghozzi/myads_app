# Member ID Privacy & Anti-Enumeration

To protect users against user ID enumeration, scraping bots, and targeted brute-force attacks, the MYADS mobile app adheres strictly to the backend's **Member ID Privacy System** (`public_member_ids_enabled`).

---

## 1. The Anti-Enumeration Architecture

In standard systems, numeric auto-incrementing IDs (`1, 2, 3...`) expose total user counts and allow automated scrapers to iterate across all user profiles.

With `public_member_ids_enabled` active:
* Numeric database IDs are never exposed in public API responses.
* The API returns randomized, collision-resistant alphanumeric identifiers (`public_uid`, e.g. `usr_8f7b2c9a`).
* In `myads_app`, user `id` fields in `UserModel` and `UserProfileModel` are typed as `String` to seamlessly handle both representations:

```dart
class UserModel {
  final String id; // Handles numeric string '123' or public_uid 'usr_xyz'
  final String username;
  final String name;
  ...
}
```

---

## 2. Username-Based Route Migration

All social interaction endpoints operate on `username` rather than IDs:
* **Follow/Unfollow:** `POST /api/profile/{username}/follow`
* **Block Member:** `POST /api/profile/{username}/block`
* **Report Member:** `POST /api/profile/{username}/report`

---

## 3. User Validity Safeguards (`UserModel.isValid`)

When users delete their accounts or temporary test data is purged, posts may reference orphaned records. To prevent NullPointer and route crashes, `UserModel` encapsulates an immutable validity check:

```dart
bool get isValid => 
    id.isNotEmpty && 
    id != '0' && 
    username.isNotEmpty && 
    username != 'unknown';
```

Widgets inspect `!user.isValid` to disable click-to-profile navigation and display friendly fallback placeholders rather than throwing runtime exceptions.
