# Current Data Flow

## Startup and environment selection

1. `main()` initializes Flutter and boots the app shell.
2. `configureDependencies()` registers interfaces in GetIt.
3. On Android, the app selects SQLite-backed repositories and a metadata cache.
4. In mock/Web builds, the same composition root selects in-memory repositories,
   `LearningContentPolicy`, and `InMemoryFileStorage`.
5. `VoyagerApp` receives the roadmap repository and passes the app shell and
   feature screens whatever domain contracts they need.

The app is local-first by design, with a mock mode that works without a backend
or real media service. The app shell now reads saved playlist and note data from
real repository implementations instead of hidden sample state.

## Player and persistence flow

```text
Player screen
  -> `PlaybackController`
  -> selected `VideoSourceAdapter`
  -> direct media stream selection
  -> `FlutterMediaPlayer` / platform player
```

Library and notes use the repository path:

```text
Screen action
  -> feature repository interface
  -> SQLite adapter or in-memory adapter
  -> saved playlist/video/note rows
```

Library playlist saves persist playlist metadata, ordered entries, and nested
video records. Player notes save an authored note plus optional video ID and
playback timestamp. These flows are in the current code path, not only the
intended target architecture.

## Content and provider boundaries

Source resolution flows through `SourceDetector` and `VideoSourceAdapter`
implementations rather than the older `MediaProvider` abstraction. Content
policies remain separate from playback and are intentionally disabled by default.
Provider-specific media details should not leak into the UI layer.
