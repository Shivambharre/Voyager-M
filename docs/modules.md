# Module Boundaries

## Application shell

`lib/main.dart` bootstraps the Flutter application. `lib/core/di/service_locator.dart`
is the composition root and registers application-scoped interfaces to mock
implementations for development.

## Core

| Module | Responsibility | Current implementation |
| --- | --- | --- |
| `core/design` | Presentation tokens, themes, reusable controls, showcase | Implemented |
| `core/di` | Central interface-to-implementation registration | Mock registrations implemented |
| `core/database` | Structured local database boundary | SQLite schema v2 and migration are implemented |
| `core/storage` | Large device-file boundary | In-memory mock only |
| `core/media` | Source adapters, stream selection, playback state, platform player bridge | Active in player flow; quality switching and fullscreen built in |
| `core/filtering` | Content decision contract | Basic mock policy only |

## Features

| Feature | Domain/data boundary | Presentation state |
| --- | --- | --- |
| `features/roadmap` | Roadmap/topic models and repository interface/mock | Screen reads the roadmap repository; create/edit/delete flows are active |
| `features/library` | Video, playlist, playlist-entry models and repository implementations | Home and Library display saved playlists/videos; save and reopen actions are connected |
| `features/notes` | Study note model and repository implementations | Notes tab and player note actions both persist data |
| `features/progress` | Progress/bookmark models and repository implementations | Repository-backed progress/bookmarks exist but resume integration remains separate work |
| `features/settings` | Settings model and repository implementations | Theme toggle is wired through app state and persisted through the repository layer |
| `features/home` | Main shell and primary navigation | Home reads saved playlists and note totals from repositories |
| `features/player` | Learning player presentation | Quality selector, fullscreen, save playlist, and save-note flows are active |

## Dependency direction

Presentation may use feature contracts passed through the app composition root.
Feature domain code must not import Flutter widgets, SQLite APIs, file-system
APIs, or provider/player SDK classes. Infrastructure implementations are selected
centrally and should not leak concrete types across these boundaries.

## Future feature layout

When adding persistence, keep adapters in feature `data/` modules (or a shared
infrastructure module where appropriate), implement the existing contracts, and
register them centrally. Avoid a feature-to-feature dependency where a shared
domain value or use case can express the relationship instead.
