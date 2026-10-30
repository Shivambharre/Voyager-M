# Module Boundaries

## Application shell

`lib/main.dart` bootstraps the Flutter application.
`lib/core/di/service_locator.dart` selects SQLite repositories on Android and
in-memory repositories in mock/Web mode.

## Core

| Module | Responsibility | Current implementation |
| --- | --- | --- |
| `core/design` | Presentation tokens, themes, reusable controls, showcase | Implemented |
| `core/di` | Repository and playback composition | Platform-specific wiring |
| `core/database` | Structured local database boundary | SQLite schema v3 and migrations are implemented |
| `core/media` | Source adapters, stream selection, playback state, platform player | One active player pipeline |

## Features

| Feature | Domain/data boundary | Presentation state |
| --- | --- | --- |
| `features/roadmap` | Roadmap/topic models and repository interface/mock | Screen reads the roadmap repository; create/edit/delete flows are active |
| `features/library` | Video, playlist, playlist-entry models and repository implementations | Home and Library display saved playlists/videos; save and reopen actions are connected |
| `features/notes` | Study note model and repository implementations | Notes tab and player note actions both persist data |
| `features/progress` | Progress model and repository implementations | Data adapters exist; player and screens do not use them |
| `features/settings` | Settings model and repository implementations | Data adapters exist; theme selection is session-local |
| `features/home` | Main shell and primary navigation | Home reads saved playlists and note totals from repositories |
| `features/player` | Learning player presentation | Quality selector, fullscreen, save playlist, and save-note flows are active |

## Dependency direction

Presentation may use feature contracts passed through the app composition root.
Feature domain code must not import SQLite APIs or provider/player SDK classes.
Infrastructure implementations are selected centrally and should not leak
concrete types across these boundaries.

Experimental content-filtering, content-policy, mock media-provider, mock
player-engine, and in-memory file-storage modules were removed because no
shipping screen or workflow used them.

## Future feature layout

When adding persistence, keep adapters in feature `data/` modules (or a shared
infrastructure module where appropriate), implement the existing contracts, and
register them centrally. Avoid a feature-to-feature dependency where a shared
domain value or use case can express the relationship instead.
