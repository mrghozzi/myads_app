# Rich Multimedia Layouts & Audio

The MYADS Mobile App offers rich presentation cards for varied multimedia types, matching the web platform's visual design.

---

## 1. Adaptive Photo Gallery Grids

Images attached to posts automatically adopt optimized layout grids depending on photo counts:

| Image Count | Layout Design | Behavior |
| :---: | :--- | :--- |
| **1 Image** | Full-width 16:9 or native aspect ratio | Rounded border, tap-to-fullscreen. |
| **2 Images** | 50% / 50% Side-by-side columns | Synchronized height matching. |
| **3–4 Images**| 1 Hero Image (Top) + 2 Small Images (Bottom) | Dynamic visual hierarchy. |
| **5+ Images** | 4-Grid + **"+N" Overflow Overlay** on 4th photo | Displays remaining count (e.g. `+3`). |

---

## 2. Audio & Music Player Cards

* **Audio Attachments (`s_type = 5`):** Styled green card with animated waveform decoration, duration indicator, and Play/Pause control via `just_audio`.
* **Music Attachments (`s_type = 6`):** Vibrant orange card highlighting track title, artist name, and album artwork.

---

## 3. File Attachments & Downloads

Documents and downloadable files (ZIP, PDF, APK, etc.) are rendered in dedicated attachment cards:
* Displays file type icon (`FontAwesome` / `CupertinoIcons`).
* Shows original filename and human-readable size (e.g., `4.2 MB`).
* Tapping the download action retrieves the file to the app's cache directory via `path_provider` and opens it in the default system viewer using `open_filex`.

---

## 4. Media Badges Legend

Posts on the feed display color-coded media indicator pills:
* 🔵 **Video:** 16:9 streaming video.
* 🟠 **Clips:** 9:16 vertical short-form.
* 🟢 **Audio:** Voice note or speech recording.
* 🟡 **Music:** Song or music track.
* 🔘 **File:** Document or archive download.
