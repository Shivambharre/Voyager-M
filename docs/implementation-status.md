# Implementation Status

This document describes behavior in the current source tree. A model or
repository alone does not mean that a screen uses that feature.

## Active user flows

| Area | Current behavior | Known limit |
| --- | --- | --- |
| App shell | Home, Roadmaps, Library, Notes, and Settings are available. The header opens Profile and toggles appearance. | The design showcase is available only in debug builds. |
| Roadmaps | Users can create and edit roadmaps and topics, change topic status, and delete items. The app can ask before topic completion. | Users cannot reorder topics or link topics to saved content. |
| Library | Users can save, open, and delete videos and playlists. Playlist entries keep their order. | Saving a playlist is available from the player flow. |
| Notes | Users can create and delete notes. The player can save a note with a video and playback time. | Notes do not have file attachments. |
| Watch history | The player records loaded videos. Home can open the recent-history list. | Android keeps up to 50 distinct videos. Neither store saves playback position. |
| Progress | The player saves position and completion. Home can open the progress list and resume an incomplete lesson. | Progress is stored on the device. |
| Bookmarks | The player saves moments. Home can open, seek to, and delete bookmarks. | Bookmarks are stored on the device. |
| Daily goals | Home shows today's totals. The app counts playing time and manually completed lessons. | Default targets are 30 minutes and one lesson per day. |
| Watch streak | Eligible playback is accumulated by local date. A day qualifies at 15 minutes; strict consecutive-day streaks, best streaks, milestones, and a yearly heatmap are shown in Profile. | The app has no grace days or account/cloud synchronization. Web/mock mode uses in-memory data. |
| Profile | Profile name and username can be edited locally. History, bookmarks, and settings open their existing flows. | There is no signed-in account; the sign-out row explains that profile data is local. |
| Settings | Users can set appearance, default playback speed, resume behavior, topic-completion confirmation, and daily targets. | Settings are stored on the device. |
| YouTube | Android uses NewPipe. Other platforms use `youtube_explode_dart`. | Extraction depends on external service behavior. Live extraction is not covered by default tests. |
| MIT OpenCourseWare | The app reads page metadata and supported direct video media links from MIT pages. | Page formats vary. The app does not support every embedded player. |
| Playback | The controller supports stream selection, seeking, speed control, and fullscreen. Android Media3 can merge paired audio and video tracks. | The Flutter player cannot use separate audio and video tracks. Browser codecs and CORS can limit playback. |
| SQLite | Schema version 6 stores learning data, metadata cache, history, daily goals, watch activity, and local profile values. | The migration test does not use a complete production version-1 database. |
| Android APK | The Android app packages ARM64 (`arm64-v8a`) native libraries only. | 32-bit ARM phones and x86/x86_64 devices are not supported by this APK. |
| Sharing | Android accepts shared YouTube links and opens the native share sheet for an outgoing link. Other platforms copy outgoing links to the clipboard. | Incoming shared text must contain a supported YouTube link. |

## Not implemented

The app does not have topic ordering, topic-to-video links, attachments, video
downloads, offline playback, cloud sync, or content and advertisement filters.
It does not provide a general video-discovery feed.

## Validation limits

- Unit and widget tests use controlled inputs. They do not prove that a live
  provider will keep working.
- A Web build does not test Android plugins or native playback.
- Physical-device playback and live YouTube extraction require separate
  tests.
- The Android release build currently fails during R8. R8 reports missing
  `java.beans` classes referenced by Rhino. The release APK is not verified.
  Review the generated R8 rules and dependency before changing configuration.

Run the commands in [testing.md](testing.md) to check the current source tree.
