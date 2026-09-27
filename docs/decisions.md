# Architecture Decision Log

Record significant project choices here. Add new decisions with date, context,
decision, and consequences; do not silently change a foundational boundary.

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
