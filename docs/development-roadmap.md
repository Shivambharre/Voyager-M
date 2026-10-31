# Development Roadmap

This document describes the current app scope. It is not a promise that an
unfinished feature is ready to use. See
[implementation-status.md](implementation-status.md) for active behavior and
known gaps.

## Active app flows

- Create, edit, delete, and complete roadmap topics.
- Save, view, open, and delete playlists and videos.
- Create and delete study notes.
- Record and view recent video history.
- Resolve and play supported YouTube sources.
- Resolve and play supported MIT OpenCourseWare video media.
- Use playback controls for seeking, speed, quality selection, and fullscreen.
- Share a YouTube video or playlist link to the Android app.

## Implemented data that is not connected to screens

SQLite and in-memory implementations exist for progress, bookmarks, and
settings. The current player does not save progress. The Settings screen does
not save settings. The bookmark action does not save a bookmark.

## Not in the current app flow

- Playback resume and daily goals
- Roadmap topic reordering or links from topics to saved videos
- Attachments, video downloads, or offline playback
- Cloud accounts or cloud sync
- Content or advertisement filtering
- General video discovery

Do not treat these items as active features. Check `TODO.md` before you add a
visible design action.

## Work rule

Change one active flow at a time. Add tests for the change. Update the related
documents after validation. See
[development-workflow.md](development-workflow.md) and [testing.md](testing.md).
