# Media Source Adapters

## Contract

`SourceDetector` routes supported URLs into `VideoSourceAdapter`
implementations, which return app-owned `VideoInfo`, `PlaylistInfo`, and
`MediaStreamInfo` models. Android routes YouTube metadata, playlists, and
combined or paired adaptive stream extraction through the native NewPipe Extractor
bridge. Other platforms lazily create the `youtube_explode_dart` fallback. The
MIT OCW adapter parses metadata and direct media links from MIT-hosted pages.
The library displays saved content; source extraction happens in the player.

## Production integration boundaries

Extraction and playback are replaceable, but YouTube extraction is
reverse-engineered and may be restricted by service terms. Do not filter
YouTube's player/ad requests, extract full video files, persist temporary stream
URLs, or provide offline YouTube copies. Before release, review current service
terms, package updates, platform behavior, attribution, and license obligations.
The Dart extractor is BSD-3-Clause; the Android NewPipe Extractor dependency is
GPL-3.0-or-later and requires license review before distribution. See
`THIRD_PARTY_NOTICES.md`.

Invalid input and extraction failures surface as `VideoSourceException`s.
YouTube extraction can break when upstream behavior changes; current service
terms and the GPL-3.0-or-later NewPipe dependency require review before release.
