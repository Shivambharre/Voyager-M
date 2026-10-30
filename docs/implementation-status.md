# Implementation Status

This document records behavior that is present in the repository today. A
contract, data model, or screen prototype alone does not count as a connected
feature.

## Active application flows

| Area | Current status | Remaining boundary |
| --- | --- | --- |
| App shell and design system | Home, Roadmaps, Library, Notes, Settings, and player navigation are present | Theme toggle is session-local; some screens remain prototypes |
| Roadmaps | SQLite and in-memory repositories; roadmap/topic create, edit, delete, activate, and completion flows | Reordering and linking roadmap topics to saved content are not implemented |
| Library | Saved playlist/video metadata and ordered entries persist and display in Library/Home | Import/cache experience is limited to saving from the player |
| Notes | Notes tab and player notes persist through repository adapters | Attachments are not implemented |
| Watch history | Recently loaded videos are recorded locally and listed from the Home watch-history shortcut | History is bounded to the 50 most recent distinct videos |
| YouTube playback | Android uses NewPipe; other platforms lazily use `youtube_explode_dart` | Extraction depends on upstream changes and has not been validated on a physical Android device |
| MIT OCW playback | Recognized pages and direct media links are supported | Arbitrary OCW pages and embedded YouTube are not guaranteed |
| Player controls | One playback controller supports quality selection, adaptive Android audio/video track merging, seeking, speed, compact controls, and fullscreen exit | Browser CORS/codecs vary; higher YouTube resolutions depend on extractor-provided adaptive tracks |
| SQLite | Schema v3, metadata cache, watch history, repositories, and migration/reopen coverage exist | More migration and edge-case coverage is useful |

## Retained but not wired to screens

Progress/bookmark and settings models plus SQLite/in-memory repositories are
implemented and tested, but the player does not save progress and the Settings
screen does not persist settings. They are data-layer foundations, not active
user-facing features.

## Removed prototypes

The unused mock media provider, mock player engine, duplicate YouTube ID parser,
unused content-policy and file-storage stubs, and unconnected content/ad-filter
subsystem were removed. The active runtime has one player pipeline. The Android
and non-Android YouTube extractors are separate platform implementations; the
Dart fallback is created only on platforms that need it.

## Validation

Run `flutter analyze`, `flutter test`, `flutter build web`, and
`$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.incremental=false'; flutter build apk --debug`
from the project root. Cleanup validation passed for analysis, the full test
suite (36 tests), Web build, and Android debug APK build. No physical-device
playback or live provider extraction was tested; do not treat a successful
build as evidence of live provider availability.

## Known boundaries

- YouTube extraction is reverse-engineered and can stop working; review current
  upstream terms and the GPL-3.0-or-later Android dependency before release.
- Stream URLs are temporary and not cached. Playback requires network access.
- No device-file attachments, cloud sync, content/ad filtering, or video
  offline-copy flow is implemented.
