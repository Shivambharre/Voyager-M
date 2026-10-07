# Architecture Decision Log

Record significant project choices here. Add new decisions with date, context,
decision, and consequences; do not silently change a foundational boundary.

## 2026-10-03 — Use replaceable direct-stream playback adapters

- **Context:** The learning screen needs one playback interface for YouTube and
  MIT OCW, with playlist streams loaded only when a lecture is selected.
- **Decision:** Route providers through `VideoSourceAdapter`, select a fresh
  combined stream, and play the direct media URI through `video_player` behind
  `PlaybackController`. Use `youtube_explode_dart` (BSD-3-Clause); do not add
  NewPipe Extractor (GPL-3.0) without a separate distribution-license review.
- **Consequences:** YouTube extraction is reverse-engineered and can break;
  current service terms/compliance require legal review before release. Direct
  streams may be transient, split-track formats are unsupported without a mux
  backend, and no stream URLs are cached. YouTube ad/player requests are
  explicitly excluded from content filtering. Browser codec/CORS support varies.

## 2026-09-28 — Use YouTube's official embedded player (superseded)

- **Context:** The initial prototype used the official IFrame API.
- **Decision:** Superseded by the 2026-10-03 adapter/playback decision above.
- **Consequences:** `youtube_player_iframe` has been removed from the app.

## 2026-09-27 — Local-first, replaceable boundaries

- **Context:** This is a personal learning app and should work without requiring
  a cloud backend.
- **Decision:** Use SQLite for structured local data, device storage for large
  files, and interfaces for persistence, media, player, and content policy.
- **Consequences:** Feature/UI logic must not depend directly on SQLite, a media
  extractor, or a concrete player. Cloud sync remains optional and deferred.

## 2026-09-27 — Central mock-mode dependency injection

- **Context:** UI and architecture work need to run before production
  persistence/media exists.
- **Decision:** Register in-memory repositories and mock media/player/storage
  implementations through the GetIt composition root.
- **Consequences:** The app can start without network or production services.
  Mock behavior is not durable and must not be represented as completed
  persistence/playback.

## 2026-09-27 — Android first, Chrome for UI iteration

- **Context:** Android is the target platform, while responsive UI iteration is
  useful in a desktop browser.
- **Decision:** Keep Android as the primary target and enable Flutter Web for
  local Chrome previews.
- **Consequences:** Web builds validate Flutter UI compatibility only; Android
  plugins, persistence drivers, and platform playback still require Android
  builds/device testing.

## 2026-09-27 — Neo-Brutalist visual system

- **Context:** The supplied design prompt requires high contrast and focused
  learning UX rather than a generic material appearance.
- **Decision:** Centralize warm paper/ink, yellow/blue accents, bold borders,
  hard shadows, shared components, and separate light/dark themes.
- **Consequences:** Screens should use shared tokens/components; a later visual
  redesign should not require domain or persistence changes.
