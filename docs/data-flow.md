# Current Data Flow

## Startup and mock mode

1. `main()` ensures Flutter bindings are initialized.
2. `configureDependencies()` registers interfaces in GetIt.
3. The initial registration selects in-memory repositories, `MockMediaProvider`,
   `MockPlayerEngine`, `LearningContentPolicy`, and `InMemoryFileStorage`.
4. `VoyagerApp` gets the `RoadmapRepository` from the composition root unless a
   repository is explicitly injected by a test.
5. The app shell passes the roadmap contract to the roadmap screen.

No backend, user account, or internet connection is required to start the mock UI.

## Implemented contracts not yet connected to screen actions

Library, notes, progress, settings, media, player, content policy, and file
storage interfaces are registered, but the current UI screens do not yet route
their state changes through these repositories/services. The screen sample data
is presentation-only.

## Target local-first flow

```text
Screen
  -> feature action/use case
  -> domain repository/service interface
  -> selected data adapter
  -> SQLite for structured records / device storage for large files
```

Playback is a separate replaceable path:

```text
Player UI
  -> player-facing feature state
  -> PlayerEngine
  -> selected platform player
```

Source resolution similarly goes through `MediaProvider`; content decisions go
through `ContentPolicy`. Provider-specific types should not flow back to the UI.

The target flows describe intended architecture, not completed behavior.
