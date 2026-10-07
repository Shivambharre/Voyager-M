# Player Boundary

## Contract

`PlaybackController` is the player-facing contract used by
`LearningPlayerScreen`. It coordinates a `VideoSourceRegistry`, metadata cache,
`StreamSelector`, and `MediaPlayer`; extraction stays outside the screen.
`PlayerEngine` remains as the older provider-neutral mock contract for
deterministic architecture tests.

## Current state

The source detector routes YouTube video URLs, playlist URLs, and MIT OCW URLs
to separate adapters. `YoutubeAdapter` uses `youtube_explode_dart` for metadata,
playlist entries, and stream descriptors. Playlist stream manifests are
requested only after a lecture is selected. `MitOcwAdapter` handles MIT-hosted
pages and direct media links; it does not treat every OCW page or YouTube embed
as playable.

`StreamSelector` selects only fresh streams with combined audio and video in a
supported MIME type, resolution, and network budget. Separate audio/video
tracks are intentionally rejected because this backend does not mux tracks.
The player retains the available compatible streams and supports switching
quality without losing the current playback position. A fullscreen action
temporarily enables immersive landscape playback; seek controls expose labels
and remain disabled until duration is known.
`FlutterMediaPlayer` passes the selected direct media URI to `video_player`,
which uses ExoPlayer on Android. It never passes a YouTube webpage URL to the
native player and never downloads a complete video for metadata.

SQLite caches stable video/playlist metadata and playlist ordering. Temporary
stream URLs are not cached; a new stream manifest is requested whenever a
lecture is loaded again. Saving a playlist stores its metadata, ordered entries,
and video records through `LearningLibraryRepository`. Player notes save through
`NotesRepository` with the current video and timestamp, when available.

## Migration from the IFrame player

The `youtube_player_iframe` dependency and screen-level controller have been
removed. Existing saved YouTube page URLs remain valid inputs; first load now
detects the URL, caches stable metadata, selects a current direct media stream,
and gives that stream URI to `video_player`. Schema v2 adds a metadata cache and
upgrades schema v1 without rewriting existing learning records. No video files
or temporary stream URLs are migrated.

## Filtering boundary

`ContentFilterService` and `ContentFilterEngine` are separate from playback.
Filtering is disabled by default. Only `applicationManaged` requests are
forwarded; YouTube player and extracted-media scopes are always allowed. The
MethodChannel adapter is a bridge contract only: no Android Rust library is
currently packaged or enabled.

## Limitations

YouTube extraction relies on reverse-engineered endpoints and may stop working;
terms and distribution compliance require review before release. Age/region
restrictions and private videos remain unavailable. Stream URLs expire and are
treated as transient. Browser playback depends on browser codec/CORS support.
OCW pages are heterogeneous and only direct MIT-hosted media is recognized.

Retain a mock implementation for deterministic widget and application tests.
