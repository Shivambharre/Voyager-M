# Media Providers

## Source contract

`SourceDetector` accepts supported YouTube video links, YouTube playlist
links, and MIT OpenCourseWare page links. `VideoSourceRegistry` selects an
adapter for a source. Each adapter returns app-owned models. Screens do not
use provider SDK models.

Simple version: the app first checks what kind of media link it got, then
picks the right adapter to turn it into app-friendly data.

## YouTube

- Android calls the native NewPipe Extractor bridge in
  `android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt`.
- Web and other non-Android platforms use `youtube_explode_dart`.
- `NewPipeYoutubeAdapter` selects the platform path.
- The Android bridge returns video and playlist details and playable streams.
- Android can pair a video-only track with an audio track for Media3 playback.

Simple version: Android uses a native helper, while web uses a Dart package.
The app then builds a clean media object that the player can use.

The `USE_EXTRACTED_YOUTUBE_PLAYER` build option controls YouTube extraction.
It is `true` by default. If the app sets it to `false`, the player rejects
YouTube sources. MIT OpenCourseWare playback does not use this option.

Think of this flag as a safety switch: when it is on, the app tries to pull
YouTube media details; when it is off, it refuses to play YouTube links.

## MIT OpenCourseWare

`MitOcwAdapter` requests an MIT OpenCourseWare page and reads its metadata. It
searches the page for direct media links with supported file extensions on an
MIT host. It does not support every course page or every embedded video
player. It does not expose a standard playlist format.

Simple version: this adapter inspects an MIT course page, finds a real media
file, and hands it to the player. It is more like a direct file finder than a
full media library.

## Errors and limits

Adapters report invalid sources and extraction or network failures through
`VideoSourceException`. YouTube extraction can stop working when the service
changes. Private, age-restricted, or region-restricted videos may not work.
Temporary stream URLs can expire. The app requests current streams when it
loads a lesson and does not cache those URLs.

In plain English: media links can break, expire, or become blocked, so the app
checks fresh stream data each time instead of trusting old URLs.

YouTube extraction uses reverse-engineered behavior. Before release, review
the current service terms, provider behavior, and package licenses. The
Android NewPipe Extractor dependency is GPL-3.0-or-later. The Dart
`youtube_explode_dart` package is BSD-3-Clause. See
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

This is a legal and reliability note: the app depends on third-party extraction
logic, so the team must keep license and usage rules in check.

The app does not filter provider requests, save full YouTube videos, or offer
offline YouTube copies.

Simple version: the app plays media sources, but it does not build a copy or
store a downloadable YouTube archive for offline use.
