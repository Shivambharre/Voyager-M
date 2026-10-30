# Current Data Flow

## Startup and environment selection

1. `main()` initializes Flutter and boots the app shell.
2. `configureDependencies()` registers interfaces in GetIt.
3. On Android, the app selects SQLite-backed repositories and a metadata cache.
4. In mock/Web builds, the same composition root selects in-memory repositories.
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
  -> Android Media3 player or Flutter `video_player` fallback
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

## Provider boundary

Source resolution flows through `SourceDetector` and `VideoSourceAdapter`
implementations. Android uses NewPipe; other platforms lazily create the
`youtube_explode_dart` fallback. Provider-specific media details do not leak
into the UI layer. Unused mock-media and content-filter prototypes were removed.
