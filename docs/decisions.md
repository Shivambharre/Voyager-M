# Decision Log

Record a decision here when it changes an important app boundary. Include the
date, reason, choice, and effects. Do not change an earlier decision without
recording the new choice.

## 2026-10-03 - Use direct media streams

- **Reason:** The player needs one path for YouTube and MIT OpenCourseWare.
- **Choice:** Use `VideoSourceAdapter` to resolve source data and streams.
  Android uses NewPipe for YouTube and Media3 for playback. Other platforms
  use `youtube_explode_dart` and `video_player`.
- **Effects:** YouTube extraction uses reverse-engineered behavior and can
  stop working. Stream URLs can expire, so the app does not cache them.
  Android can pair separate audio and video tracks. The Dart player cannot.
  Review service terms and the NewPipe Extractor GPL-3.0-or-later license
  before release.

## 2026-09-28 - Remove the YouTube IFrame player

- **Reason:** The first player design used the official YouTube IFrame API.
- **Choice:** Replace it with the direct-stream adapters recorded above.
- **Effects:** The app removed `youtube_player_iframe`. Saved YouTube page
  links remain inputs to the new player.

## 2026-09-27 - Keep study data local

- **Reason:** The app must work without a cloud account.
- **Choice:** Use SQLite repositories on Android and in-memory repositories
  for Web and mock mode. Keep storage behind repository contracts.
- **Effects:** The app has no cloud sync or device-file storage.

## 2026-09-27 - Select repositories in one place

- **Reason:** Web builds and tests need in-memory data stores.
- **Choice:** Register repository implementations in
  `lib/core/di/service_locator.dart`.
- **Effects:** Web uses in-memory repositories by default. Tests can request
  them explicitly. In-memory data does not survive an app restart.

## 2026-09-27 - Target Android and support Web previews

- **Reason:** Android is the main target. Web previews help with UI work.
- **Choice:** Keep Android as the primary platform and allow Flutter Web
  builds.
- **Effects:** A Web build does not test Android plugins, SQLite, or native
  playback.

## 2026-09-27 - Use the Classical Archive design

- **Reason:** The app needs a clear, study-focused visual system.
- **Choice:** Use parchment and dark surfaces, restrained antique colors,
  Cormorant Garamond headings, and Inter interface text.
- **Effects:** Keep palette and type choices in shared design tokens. Keep
  screen styling separate from data and player logic.
