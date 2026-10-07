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
| Structured database | `AppDatabase` | `SqfliteAppDatabase` on Android | Core schema v2 and migration implemented; more migration coverage remains |
| Feature repositories | Feature-specific repository interfaces | SQLite on Android, in-memory on mock/Web | Repository adapters are active for roadmaps, library, notes, settings, and metadata caching |
| File storage | `LocalFileStorage` | `InMemoryFileStorage` | Mock only; device files not implemented |
| Media resolution | `VideoSourceAdapter` / `SourceDetector` | YouTube + MIT OCW adapters | Source adapters resolve, normalize, and stream direct media metadata; no app-owned file extraction yet |
| Player control | `PlaybackController` | `DefaultPlaybackController` + `FlutterMediaPlayer` | Available streams are retained for quality switching; fullscreen and playback controls are in the screen |
| Content filtering | `ContentFilterService` / `ContentFilterEngine` | Disabled no-op engine | Separate MethodChannel adapter contract; Rust engine not packaged |
| Content decisions | `ContentPolicy` | `LearningContentPolicy` | Basic mock; separate from request filtering |
| Search | To be defined | None | Not implemented |
| OCR | To be defined | None | Not implemented |
| Future sync | To be defined | None | Optional and deferred |

## Current implementation checkpoint

The composition root uses SQLite-backed repositories on Android, in-memory
repositories/cache in mock and Web mode, and creates a disposable playback
pipeline per player route. The app shell now reads saved library playlists and
notes from their repository contracts. Media extraction/playback still requires
network access, but quality selection and fullscreen are now part of the player
screen state rather than ad hoc UI logic.

Available domain contracts cover:

- Roadmaps and topics
- Videos, playlists, playlist entries, and stream metadata models
- Study notes with timestamp/video context
- Playback progress and bookmarks
- Learning settings
- Source detection, player control, filtering boundaries, and file storage

Durable device-file handling and native Rust filtering remain deferred. See
[`implementation-status.md`](implementation-status.md) for completion
boundaries and validation evidence.

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

The current startup and mock-mode flow is documented in [`data-flow.md`](data-flow.md).
Player routing is connected; live provider extraction, physical-device playback,
and native filtering remain validation or implementation gaps.

## Why this matters

The architecture prevents any single implementation detail from becoming the default dependency for all business rules. If a future requirement replaces SQLite with a different storage engine, or a new media provider is added for a different platform, the rest of the app continues to work with minimal change.
