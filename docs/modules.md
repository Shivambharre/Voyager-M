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
| `core/database` | Structured local database boundary | Placeholder only |
| `core/storage` | Large device-file boundary | In-memory mock only |
| `core/media` | Provider asset and player engine contracts | Mock provider/player only |
| `core/filtering` | Content decision contract | Basic mock policy only |

## Features

| Feature | Domain/data boundary | Presentation state |
| --- | --- | --- |
| `features/roadmap` | Roadmap/topic models and repository interface/mock | Screen in app shell reads roadmap repository |
| `features/library` | Video, playlist, playlist-entry models and mock repository | Sample rows and local-only filtering |
| `features/notes` | Study note model and mock repository | Sample/editable screen state, not repository-backed yet |
| `features/progress` | Progress/bookmark models and mock repository | Sample progress values; not connected to player |
| `features/settings` | Settings model and mock repository | Theme toggle is current shell state, not durable settings |
| `features/home` | Main shell and primary navigation | Implemented for prototype |
| `features/player` | Learning player presentation | Mock UI; not connected to `PlayerEngine` |

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
