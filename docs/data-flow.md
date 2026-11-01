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

Playback snapshots also feed the watch-activity tracker. It checks playback
status, buffering, and position advancement, then periodically persists
eligible seconds by the user's local calendar date. The profile reads these
daily records to calculate current/best streaks, milestones, and heatmap levels.
Daily watch activity does not replace the separate configurable daily-goal
records.

The profile screen reads and edits a local display name and username, and opens
the existing watch-history, bookmarks, and settings flows. This app has no
account authentication, so its sign-out row explains that profile data remains
on this device.

## Android share flow

Android sends shared text to the Flutter app through an EventChannel.
`SharedYoutubeLink` finds a valid YouTube video or playlist link in that text.
The app opens the player with that link. Other shared text shows an error.

## Data that is not connected

See [implementation-status.md](implementation-status.md) for the full feature
status.
