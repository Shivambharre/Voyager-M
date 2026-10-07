# Media Provider Boundary

## Contract

Source resolution is handled by `SourceDetector` and `VideoSourceAdapter`.
These adapters return app-owned `VideoInfo`, `PlaylistInfo`, and
`MediaStreamInfo` models instead of platform SDK objects, making the player
state independent from any one YouTube or MIT implementation.

## Current state

The app resolves supported URLs through `SourceDetector`, which routes YouTube
videos/playlists and MIT OCW sources to domain adapters. Metadata and playlist
entries are cached with `VideoMetadataCache` while stream URLs remain transient
and are selected only when the player loads a lecture.

`YoutubeAdapter` uses `youtube_explode_dart` to resolve stream metadata and
playlist metadata. On Android, `NewPipeYoutubeAdapter` is also available for
metadata extraction and playlist entry discovery. `MitOcwAdapter` parses direct
MIT-hosted media links and metadata from OCW pages.

`StreamSelector` only keeps fresh, combined audio/video streams that match the
supported MIME types, resolution cap, and bitrate policy. The player retains the
available stream list to support quality switching and preserves the current
playback position when switching streams.

## Production integration boundaries

Extraction and playback are replaceable, but YouTube extraction is
reverse-engineered and may be restricted by service terms. Do not filter
YouTube's player/ad requests, extract full video files, persist temporary stream
URLs, or provide offline YouTube copies. Before release, review current service
terms, package updates, platform behavior, attribution, and license obligations.
Any third-party adapter remains subject to its respective license and no app
release should proceed without review. See `THIRD_PARTY_NOTICES.md`.

## Error behavior

Invalid input stays an explicit format/validation error. Adapter failures map to
player-level domain errors such as unsupported source, unavailable item, expired
stream, or incompatible format. The app no longer depends on placeholder
provider assets for valid media workflows.
