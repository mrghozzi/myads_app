# Video Hub & Mobile Video Parity

Introduced in **v1.7.5**, the **Video Hub (`/video`)** brings complete mobile parity with the web's Video Hub interface, establishing a YouTube-style video catalog optimized for mobile touchscreens.

---

## 1. Visual Layout & Component Anatomy

```
┌────────────────────────────────────────────────────────┐
│  Glassmorphic Hero Header (Title, Search Bar, Compose) │
├────────────────────────────────────────────────────────┤
│  Category Filter Pills (All, Videos, Shorts, Trending) │
├────────────────────────────────────────────────────────┤
│  Spotlight Hero Video Card (16:9 Aspect Ratio)         │
├────────────────────────────────────────────────────────┤
│  YouTube Shorts Shelf (Horizontal Scrolling 9:16 Cards)│
├────────────────────────────────────────────────────────┤
│  Responsive Video Grid (16:9 Thumbnails, Hex Avatars)  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Key Features

### 2.1 Category Filter Pills
Filter buttons with dynamic active gradient borders allowing users to quickly switch categories:
* `All`: Complete video catalog.
* `Videos`: Long-form 16:9 videos.
* `Shorts Clips`: 9:16 vertical short-form content.
* `Trending`: Highest engagement videos based on view counts and reactions.
* `Latest`: Chronological video uploads.

### 2.2 Spotlight Hero Video Card
When viewing the default or trending feeds, the top-performing video is highlighted in an edge-to-edge 16:9 card with play icon overlay, category tag, and channel metadata.

### 2.3 Horizontal YouTube Shorts Shelf
A horizontally scrolling carousel featuring 9:16 cards with view counts, publisher avatars, and clip badges. Tapping any card opens the full-screen vertical swipe Clips player.

### 2.4 Strict Backend Content Isolation
Video feed requests target `/api/video/feed`, where the backend enforces strict `s_type` scoping:
```php
// Backend VideoApiController.php
$query->whereIn('s_type', [10, 2, 4, 100]); // Long-form videos
$clipsQuery->where('s_type', 14);          // Short-form clips
```
This guarantees non-video items (directory links `s_type = 1`, store products `s_type = 7867`, news articles) are excluded.

---

## 3. Fast Accessibility Shortcuts

* **AppBar Action:** Dedicated `ondemand_video_rounded` icon in `MyAdsScaffold` header next to notifications.
* **Explore Screen:** YouTube-styled action card in `ExploreScreen` discover section.
