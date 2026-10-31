# Media Providers

## Source contract

`SourceDetector` accepts supported YouTube video links, YouTube playlist
links, and MIT OpenCourseWare page links. `VideoSourceRegistry` selects an
adapter for a source. Each adapter returns app-owned models. Screens do not
use provider SDK models.

## YouTube

- Android calls the native NewPipe Extractor bridge in
  `android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt`.
- Web and other non-Android platforms use `youtube_explode_dart`.
- `NewPipeYoutubeAdapter` selects the platform path.
- The Android bridge returns video and playlist details and playable streams.
- Android can pair a video-only track with an audio track for Media3 playback.

The `USE_EXTRACTED_YOUTUBE_PLAYER` build option controls YouTube extraction.
It is `true` by default. If the app sets it to `false`, the player rejects
YouTube sources. MIT OpenCourseWare playback does not use this option.

## MIT OpenCourseWare

`MitOcwAdapter` requests an MIT OpenCourseWare page and reads its metadata. It
searches the page for direct media links with supported file extensions on an
MIT host. It does not support every course page or every embedded video
player. It does not expose a standard playlist format.

## Errors and limits

Adapters report invalid sources and extraction or network failures through
`VideoSourceException`. YouTube extraction can stop working when the service
changes. Private, age-restricted, or region-restricted videos may not work.
Temporary stream URLs can expire. The app requests current streams when it
loads a lesson and does not cache those URLs.

YouTube extraction uses reverse-engineered behavior. Before release, review
the current service terms, provider behavior, and package licenses. The
Android NewPipe Extractor dependency is GPL-3.0-or-later. The Dart
`youtube_explode_dart` package is BSD-3-Clause. See
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

The app does not filter provider requests, save full YouTube videos, or offer
offline YouTube copies.
