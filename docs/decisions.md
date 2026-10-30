# Architecture Decision Log

Record significant project choices here. Add new decisions with date, context,
decision, and consequences; do not silently change a foundational boundary.

## 2026-10-03 — Use replaceable direct-stream playback adapters

- **Context:** The learning screen needs one playback interface for YouTube and
  MIT OCW, with playlist streams loaded only when a lecture is selected.
- **Decision:** Route providers through `VideoSourceAdapter`, select a fresh
  combined stream, and play the direct media URI through `video_player` behind
  `PlaybackController`. Android uses the NewPipe Extractor bridge; other
  platforms lazily use `youtube_explode_dart`.
- **Consequences:** YouTube extraction is reverse-engineered and can break;
  current service terms and the GPL-3.0-or-later Android dependency require
  review before release. Direct streams may be transient, split-track formats
  are unsupported without a mux backend, and stream URLs are not cached.
  Browser codec/CORS support varies.

## 2026-09-28 — Use YouTube's official embedded player (superseded)

- **Context:** The initial prototype used the official IFrame API.
- **Decision:** Superseded by the 2026-10-03 adapter/playback decision above.
- **Consequences:** `youtube_player_iframe` has been removed from the app.

## 2026-09-27 — Local-first, focused boundaries

- **Context:** This is a personal learning app and should work without requiring
  a cloud backend.
- **Decision:** Use SQLite for structured Android data and in-memory
  repositories for mock/Web mode. Keep active persistence and playback behind
  app-owned contracts.
- **Consequences:** Feature/UI logic must not depend directly on SQLite, a media
  extractor, or the concrete player. Device-file storage and cloud sync remain
  deferred; unused prototypes are not kept in the runtime architecture.

## 2026-09-27 — Central repository selection

- **Context:** Web and deterministic tests need an in-memory data backend.
- **Decision:** Register in-memory repository adapters through the GetIt
  composition root for mock/Web mode.
- **Consequences:** Those repositories are not durable. Media playback still
  uses the production player pipeline and requires network/provider access.

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
