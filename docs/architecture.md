# Architecture Overview

## Product intent

Voyager Learning is a local-first Android study app built around a strict separation between learning data and media consumption. The product is oriented around roadmap-based study, not content discovery.

## Core architectural principles

1. Local-first by default. Structured learning data lives in SQLite on Android; Web uses in-memory repositories.
2. Small replaceable boundaries where the application currently needs them.
3. Study-oriented workflow. The app should guide the user from roadmap selection to topic completion with minimal distraction.
4. Strict module isolation. Feature code depends on interfaces, not concrete implementations.
5. Testability. Business logic and repository interfaces are unit-testable without wiring to UI or platform APIs.

## High-level layers

- Presentation: screens, widgets, navigation, theming, state handling
- Domain: entities, use cases, value objects, feature rules
- Data: repositories and persistence adapters
- Infrastructure: SQLite and platform-specific media extraction/playback
- Application shell: dependency injection, app composition root, bootstrapping

## Replaceability map

| Concern | Current implementation | Status |
| --- | --- | --- |
| Structured data | `AppDatabase`; SQLite repositories on Android, in-memory repositories on Web/mock | Schema v3; migration and repository tests exist |
| Active learning data | Roadmap, library, and note repositories | Used by app screens and player save flows |
| Progress and settings data | SQLite and in-memory repositories | Data adapters exist; screens do not yet read or write these repositories |
| YouTube extraction | Native NewPipe adapter on Android; lazily created `youtube_explode_dart` fallback elsewhere | Platform-specific extractor paths; no duplicate Android extractor instance |
| MIT OCW extraction | `MitOcwAdapter` | Supports recognized pages and direct media only |
| Playback | `PlaybackController` → `AndroidMediaPlayer` (Media3) on Android or `FlutterMediaPlayer` elsewhere | One controller pipeline; Android merges adaptive video-only and audio tracks |

## Current implementation checkpoint

The composition root uses SQLite-backed repositories on Android, in-memory
repositories/cache in mock and Web mode, and creates one disposable playback
pipeline per player route. Media extraction/playback requires network access.

Available domain contracts cover:

- Roadmaps and topics
- Videos, playlists, and playlist entries, plus source/stream metadata models
- Study notes
- Playback progress and settings data models/repositories
- Source extraction, stream selection, and player control

Durable attachment storage, progress/resume wiring, and settings persistence
remain out of the active app flow. Experimental content filtering and mock
media/player abstractions were removed. See
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

### Features

Each feature is isolated. Current domain modules include roadmaps, the learning library, notes, progress, and settings. Feature code depends on domain contracts and models, not on SQLite classes or media-provider implementations.

## Data flow

The current startup and mock-mode flow is documented in
[`data-flow.md`](data-flow.md).
Player routing is connected; live provider extraction and physical-device
playback remain validation gaps.

## Why this matters

The architecture keeps the active UI independent from SQLite and provider SDK
types, without shipping unused abstractions for features that are not wired into
the app.
