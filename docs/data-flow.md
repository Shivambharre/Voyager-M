# Data Flow

## App startup

1. `main()` initializes Flutter.
2. `configureDependencies()` registers the repositories and media services.
3. The app uses in-memory repositories on Web by default.
4. Android uses SQLite repositories.
5. Tests can pass `useMocks: true` to select in-memory repositories.
6. `VoyagerApp` builds the app shell and passes the roadmap repository.

The composition root is
[`service_locator.dart`](../lib/core/di/service_locator.dart). It also creates
a playback controller when a player screen opens.

## Roadmap flow

```text
Roadmap screen
  -> RoadmapRepository
  -> SQLite repository on Android
     or in-memory repository in mock/Web mode
```

The roadmap screen reads and saves roadmaps and topics through the repository.
It does not access SQLite directly.

## Library and notes flow

```text
Screen action
  -> repository contract
  -> SQLite repository or in-memory repository
  -> saved learning data
```

The player can save playlist details, playlist entries, videos, and notes.
The Library screen can open or delete saved items. The Notes screen can create
and delete notes.

## Player flow

```text
Player screen
  -> PlaybackController
  -> SourceDetector
  -> VideoSourceRegistry
  -> source adapter
  -> StreamSelector
  -> Android Media3 or Flutter video_player
```

Android resolves YouTube data through the NewPipe MethodChannel bridge.
Other platforms use `youtube_explode_dart`. MIT OpenCourseWare uses
`MitOcwAdapter`.

On Android, a video-only stream can include a separate audio URL. The native
Media3 player merges the two streams. `FlutterMediaPlayer` does not accept a
separate audio URL.

The player writes stable video metadata to the metadata cache. It records
recent watch history after a video loads. It does not save temporary stream
URLs.

## Android share flow

Android sends shared text to the Flutter app through an EventChannel.
`SharedYoutubeLink` finds a valid YouTube video or playlist link in that text.
The app opens the player with that link. Other shared text shows an error.

## Data that is not connected

Progress and settings repositories exist, but the active screens do not use
them. The appearance switch uses in-memory app state. The save-moment control
does not write a bookmark. See
[implementation-status.md](implementation-status.md).
