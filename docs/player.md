# Player Boundary

## Contract

`PlaybackController` is the player-facing contract used by
`LearningPlayerScreen`. It coordinates a `VideoSourceRegistry`, metadata cache,
`StreamSelector`, and `MediaPlayer`; extraction stays outside the screen.

## Current state

The source detector routes YouTube video URLs, playlist URLs, and MIT OCW URLs
to separate adapters. Android uses the NewPipe Extractor bridge for YouTube
metadata, playlist entries, and combined or adaptive audio/video streams. Web
and other platforms use `youtube_explode_dart`. Android pairs adaptive
video-only tracks with NewPipe audio streams. Playlist stream extraction is
deferred until a lecture is selected. `MitOcwAdapter` handles MIT-hosted pages
and direct media links; it does not treat every OCW page or YouTube embed as
playable.

`StreamSelector` selects fresh streams with combined audio and video in a
supported MIME type, up to 1080p. The player defaults to the highest available
supported stream without a network-bitrate cap. Android NewPipe results include
YouTube video-only tracks paired with an audio track; Android Media3 merges the
two sources during playback. This prevents the previous 360p ceiling caused by
discarding all video-only formats. The player exposes a YouTube-style
seek/progress overlay, playback and skip controls, speed and quality choices,
and fullscreen controls directly on the video surface in both normal and
fullscreen layouts. Compact phone controls fit within the 16:9 video surface,
and the fullscreen back control or device Back returns to the normal player.
Playlist controls remain above the playlist entries rather than after the
playlist.
`AndroidMediaPlayer` uses Media3 ExoPlayer for direct and merged audio/video
sources. Other platforms use `FlutterMediaPlayer` and `video_player`; neither
player receives a YouTube webpage URL or downloads complete video files for
metadata.

SQLite caches stable video/playlist metadata and playlist ordering. Temporary
stream URLs are not cached; a new stream manifest is requested whenever a
lecture is loaded again. Saving a playlist or a timestamped note writes through
the corresponding repository; saved moments remain screen-local.

## Migration from the IFrame player

The `youtube_player_iframe` dependency and screen-level controller have been
removed. Existing saved YouTube page URLs remain valid inputs; first load now
detects the URL, caches stable metadata, selects a current direct media stream,
and gives its direct stream source to the platform player. Schema v2 adds a
metadata cache and upgrades existing schemas without rewriting learning
records. Recent watch history stores stable video details and timestamps, never
temporary stream URLs. No video files are migrated.

## Limitations

YouTube extraction relies on reverse-engineered endpoints and may stop working;
terms and distribution compliance require review before release. Age/region
restrictions and private videos remain unavailable. Stream URLs expire and are
treated as transient. Browser playback depends on browser codec/CORS support.
OCW pages are heterogeneous and only direct MIT-hosted media is recognized.

Playback widgets and controller behavior are tested with fakes; Android uses
`AndroidMediaPlayer`, while other platforms use `FlutterMediaPlayer`.
