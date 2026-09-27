# Architecture Overview

## Product intent

Voyager Learning is a local-first Android study app built around a strict separation between learning data and media consumption. The product is oriented around roadmap-based study, not content discovery.

## Core architectural principles

1. Local-first by default. Structured learning data lives in SQLite, media files on device storage, and any cloud dependency remains optional.
2. Replaceable components. Every major subsystem exposes an interface and is implemented behind a contract.
3. Study-oriented workflow. The app should guide the user from roadmap selection to topic completion with minimal distraction.
4. Strict module isolation. Feature code depends on interfaces, not concrete implementations.
5. Testability. Business logic and repository interfaces are unit-testable without wiring to UI or platform APIs.

## High-level layers

- Presentation: screens, widgets, navigation, theming, state handling
- Domain: entities, use cases, value objects, feature rules
- Data: repositories, persistence adapters, file storage adapters
- Infrastructure: SQLite, media provider adapters, device storage, filtering policies
- Application shell: dependency injection, app composition root, bootstrapping

## Replaceability map

| Concern | Interface | Current selection | Status |
| --- | --- | --- | --- |
| Structured database | `AppDatabase` | `SqfliteAppDatabase` placeholder | No open/schema/migrations yet |
| Feature repositories | Feature-specific repository interfaces | In-memory implementations | Mock mode |
| File storage | `LocalFileStorage` | `InMemoryFileStorage` | Mock only; device files not implemented |
| Media resolution | `MediaProvider` | `MockMediaProvider` | Mock only; no extraction |
| Player control | `PlayerEngine` | `MockPlayerEngine` | Contract/mock; UI is not wired to it |
| Content decisions | `ContentPolicy` | `LearningContentPolicy` | Basic mock; not connected to import/playback |
| Search | To be defined | None | Not implemented |
| OCR | To be defined | None | Not implemented |
| Future sync | To be defined | None | Optional and deferred |

## Current implementation checkpoint

Phase 0.1 project and documentation foundation, Phase 0.2 mock contracts/DI,
and Phase 1 UI prototypes are established. The dependency-injection composition
root currently selects in-memory repositories, a mock media provider/player, a
sample content policy, and in-memory attachment storage. This lets the UI run
without internet, SQLite, or production media services.

Available domain contracts cover:

- Roadmaps and topics
- Videos, playlists, and playlist entries
- Study notes
- Playback progress and bookmarks
- Learning settings
- Media resolution, player control, content policy, and file storage

SQLite persistence, durable device-file handling, and production provider/player
implementations are intentionally subsequent roadmap steps, not fallbacks inside
these mocks. See [`implementation-status.md`](implementation-status.md) for
completion boundaries and validation evidence.

## Module boundaries

### App shell

Responsible for dependency registration and composition root setup. This layer wires interfaces to implementations without leaking storage or platform details into feature logic.

### Core module

Holds cross-cutting abstractions:

- database
- design
- di
- media
- storage
- filtering

### Features

Each feature is isolated. Current domain modules include roadmaps, the learning library, notes, progress, and settings. Feature code depends on domain contracts and models, not on SQLite classes or media-provider implementations.

## Data flow

The current concrete startup and mock-mode flow is documented in
[`data-flow.md`](data-flow.md). The repository-to-SQLite and player-to-platform
flows there are target architecture, not yet production-connected paths.

## Why this matters

The architecture prevents any single implementation detail from becoming the default dependency for all business rules. If a future requirement replaces SQLite with a different storage engine, or a new media provider is added for a different platform, the rest of the app continues to work with minimal change.
