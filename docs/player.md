# Player

## Player path

`LearningPlayerScreen` uses `PlaybackController`. The controller detects a
source, selects an adapter, gets current stream data, and sends a playable URL
to a platform player.

```text
LearningPlayerScreen
  -> PlaybackController
  -> SourceDetector and VideoSourceRegistry
  -> VideoSourceAdapter
  -> StreamSelector
  -> MediaPlayer
```

## Providers and players

- Android uses NewPipe for YouTube extraction and Media3 for playback.
- Other platforms use `youtube_explode_dart` and `video_player`.
- `MitOcwAdapter` reads supported MIT OpenCourseWare pages and media links.
- The player loads a playlist first. It resolves a lecture stream when the
  user selects that lecture.
- Android can merge a video-only URL with a separate audio URL. The Flutter
  player rejects a separate audio URL.

The player sends a direct media stream URL to the media player. It does not
send a YouTube page URL.

## Stream selection

The current policy accepts `video/mp4` and `video/webm` streams up to 1080
pixels high. It selects a fresh stream with both audio and video. The default
network quality setting is `fast`, which has no bitrate limit.

Android can map a video-only track with a paired audio URL as a combined
playable stream. Media3 merges the two sources. The stream selector does not
select audio-only streams.

## Learning data

The player saves the lesson position and duration while a lesson plays. It
also saves progress when playback stops and when the player closes. The
Resume setting controls automatic position restore. A completed lesson does
not resume automatically. The player does not start playback after restore.

The user can mark a lesson complete. This action updates progress and today's
lesson goal. The Save moment control stores a bookmark at the current position.
The Bookmarks screen opens the saved position and can delete a bookmark.

The player stores video metadata so that progress and bookmarks can refer to
the lesson. This metadata alone does not add the lesson to the saved Library.
Saving a playlist or video adds it to the Library.

Daily study time counts only while playback reports that it is playing. The
player saves this time in local-date sections. Default daily targets are 30
minutes and one completed lesson. Users can change both targets in Settings.

## Controls and settings

The player provides playback, seek, speed, quality, and fullscreen controls.
Playback speed can range from 0.25x to 3x. Settings store the default
playback speed, resume preference, topic-completion confirmation, appearance,
and daily-goal targets.

The player can save a playlist and a note with the current video and time.
Share link uses the Android share sheet on Android. Other platforms copy the
link to the clipboard.

## Cache and playback data

The database caches stable video and playlist metadata. It does not cache
temporary stream URLs. A new stream request occurs when the player loads a
lesson. Recent history stores video metadata and watch time. Progress stores
the current playback position.

See [database.md](database.md) for storage details,
[media-provider.md](media-provider.md) for provider behavior, and
[testing.md](testing.md) for validation.
