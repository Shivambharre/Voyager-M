# Architecture

## Product

VoyagerM is a local-first learning app. It helps users organize lessons in
roadmaps, save playlists and videos, write study notes, and review strict daily
watch streaks. It supports YouTube and selected MIT OpenCourseWare media.

The app focuses on study tasks. It does not provide a general video-discovery
feed or a cloud account.

## Main rules

- Store structured study data in local repositories.
- Keep screens separate from database and media-provider code.
- Use repository and media contracts between app layers.
- Test feature rules without network access or platform code.

## App layers

| Layer | Responsibility |
| --- | --- |
| Presentation | Screens, widgets, navigation, and themes |
| Domain | App models and repository contracts |
| Data | SQLite and in-memory repository implementations |
| Platform | Android media extraction and playback |
| Composition root | Selects and creates the app implementations |

`lib/main.dart` starts the app. `lib/core/di/service_locator.dart` registers
repositories and creates the playback controller.

## Current implementations

| Area | Current implementation |
| --- | --- |
| Repository selection | Android uses SQLite. Web uses in-memory repositories by default. Tests can request in-memory repositories. |
| Roadmaps | Roadmap and topic repositories support create, read, update, and delete flows. |
| Library and notes | Android stores saved playlists, videos, and notes in SQLite. |
| Watch history | Android stores up to 50 distinct recent videos. It stores stable metadata, not media streams. |
| Watch activity and profile | Android stores daily eligible playback totals and an editable local profile in SQLite. Web/mock mode uses in-memory repositories. |
| Progress and settings | SQLite and in-memory repositories are used by the app screens. |
| YouTube | Android uses the NewPipe Extractor bridge. Other platforms use `youtube_explode_dart`. |
| MIT OpenCourseWare | `MitOcwAdapter` reads supported pages and direct media links. |
| Playback | Android uses Media3. Other platforms use `video_player`. |

The Web default is selected by `kIsWeb`. The composition function also accepts
`useMocks` for tests or other explicit app setups. Do not treat every
non-Android platform as Web mode.

## Media flow

The player screen uses `PlaybackController`. A single snapshot subscription
tracks eligible watch time across the supported source adapters. It credits
only short intervals with advancing position and no buffering, and batches
daily totals through `WatchActivityRepository`. Seeking and app interruptions
reset the position baseline without resetting the daily total.

The controller detects a source,
selects a `VideoSourceAdapter`, selects a playable stream, and sends the stream
to a `MediaPlayer`.

On Android, the NewPipe bridge can pair a video-only track with an audio track.
Media3 plays the paired tracks. The other player implementation does not accept
separate audio and video tracks.

See [data-flow.md](data-flow.md), [media-provider.md](media-provider.md), and
[player.md](player.md) for details.

## Data flow

Screens use repository contracts. The composition root selects SQLite or
in-memory implementations. Do not import SQLite APIs into feature domain code.

The app caches video and playlist metadata. It does not cache temporary media
stream URLs. Playback and provider extraction require a network connection.

## Current boundaries

- Roadmap topics are not linked to saved videos.
- Profile identity and watch data are local-only; there is no signed-in
  account or cloud synchronization.
- The app does not store attachments or video files.
- The app does not sync data to a cloud service.

See [implementation-status.md](implementation-status.md) for the full feature
status.
