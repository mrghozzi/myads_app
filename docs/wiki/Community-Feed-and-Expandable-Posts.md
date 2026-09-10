# Community Feed & Expandable Posts

The **Community Feed (`HomeScreen`)** is the primary social hub of the application. It streams real-time updates, multimedia posts, quote reposts, and social interactions from followed members.

---

## 1. The `PostCard` Architecture

Each item in the feed is rendered by `PostCard`:
* **Header:** Hexagonal avatar, username, verified badge, creation timestamp, and privacy pill (Public, Followers, Private).
* **Body Content:** Expandable formatted text with link highlighting, hashtags, and @mentions.
* **Embedded Attachments:** Rendered by specialized sub-widgets (galleries, video cards, audio cards, files).
* **Quote Repost Embed:** If the post is a repost, embeds the nested original status inside a bounded card.
* **Footer Actions:** Like/Reaction counter, Comment trigger, Repost dialog, and Share sheet.

---

## 2. Expandable Long Posts (`FormattedContentWidget`)

Added in **v1.7.7**, long posts are intelligently truncated to preserve screen real estate and prevent feed fatigue.

### 2.1 Technical Mechanism
* Collapses posts exceeding **5 lines** when displayed in feed lists.
* Renders a smooth bottom gradient fade-out mask (`ShaderMask`).
* Features localized toggle buttons:
  * English: **"See more"** / **"See less"**
  * Arabic: **"رؤية المزيد"** / **"رؤية أقل"**
* Smooth animated height expansion using `AnimatedSize` with `Curves.easeInOutCubic`:

```dart
AnimatedSize(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOutCubic,
  child: ConstrainedBox(
    constraints: isExpanded
        ? const BoxConstraints()
        : BoxConstraints(maxHeight: collapsedHeight),
    child: ShaderMask(
      shaderCallback: (bounds) => isExpanded ? null : gradientFade,
      child: textWidget,
    ),
  ),
)
```

### 2.2 Intelligent Overflow Measurement
Short posts never show unnecessary "See more" buttons. The widget uses a two-pass text layout painter to verify if the text actually overflows 5 lines before rendering expansion controls.

---

## 3. Tap-to-Scroll-to-Top

When the user is scrolling deep down the home feed and taps the **Home tab icon** in the bottom navigation bar:
* Detects that `HomeScreen` is already active.
* Automatically scrolls the feed smoothly to the top (`animateTo(0, curve: Curves.easeOut)`).
* Triggers an automatic silent refresh to fetch new incoming posts.
