# Development Roadmap

This is the concise, current scope for the implementation. Completed behavior
and known limitations are tracked in
[`implementation-status.md`](implementation-status.md).

## Active application

- Roadmap and topic management through the roadmap repository.
- Saved playlists/videos and study notes backed by repositories.
- YouTube video and playlist playback through the Android NewPipe adapter,
  with a lazily created Dart extractor fallback on other platforms.
- MIT OpenCourseWare playback for supported pages/direct media.
- A single `PlaybackController` pipeline with platform players, adaptive
  Android audio/video track merging, resolution selection, seeking, speed, and
  fullscreen controls.

## Retained data foundations

SQLite and in-memory repositories also exist for progress and settings. They
are tested but are not currently connected to player lifecycle or app settings
UI; the visible theme toggle is session-local. The metadata database remains
versioned and migrations preserve existing records.

## Explicitly out of scope

Device-file attachments, progress/resume wiring, settings persistence, content
filtering, ad filtering, discovery feeds, and cloud sync are not part of the
current app flow. Unused mock player/media, policy, storage, and filtering
prototypes have been removed rather than kept as inactive architectures.

## Working rule

Change one active flow at a time, keep its targeted tests green, then run the
relevant full validation. See
[`development-workflow.md`](development-workflow.md) and
[`testing.md`](testing.md).
