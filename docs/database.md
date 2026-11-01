# Database

## Purpose

Android uses SQLite for learning data. The database stores text, IDs, URLs,
timestamps, and metadata. It does not store video files.

The database code is in
[`database.dart`](../lib/core/database/database.dart). The database file is
`voyager_learning.db`. The current schema version is 6.

## Tables

The database stores:

- roadmaps and topics
- videos, playlists, and playlist entries
- notes
- learning progress and bookmarks
- settings, daily-goal activity, and eligible watch activity
- a local editable profile
- video metadata cache and recent watch history

The `videos.is_saved` field separates saved library items from metadata that
the player needs for progress and bookmarks. A video can have metadata without
appearing in the Library. Existing videos remain saved after an upgrade.

Foreign keys and database checks protect related records and valid values.
Indexes support roadmap order, playlist order, note lookup, bookmark order,
and recent-history order.

## Migrations

- Version 1 creates the core learning tables.
- Version 2 adds `video_metadata_cache`.
- Version 3 adds `recent_watch_history`.
- Version 4 adds daily-goal targets to `settings` and creates
  `daily_goal_activity`.
- Version 5 adds `videos.is_saved`. Existing video records use the saved
  value.
- Version 6 adds daily `watch_activity` records and `local_profile`.

The migration test checks that records remain when the app opens an older
database. The test does not use a complete production version-1 database.

## Repositories

Android uses SQLite repositories for roadmaps, library, notes, progress,
settings, recent watch history, daily goals, watch activity, and the local
profile. Web and explicit mock mode use in-memory repositories.

Watch activity is unique per local calendar date. Each row stores accumulated
eligible seconds, whether the 15-minute threshold was reached, and its UTC
update timestamp. The profile stores a display name and username locally.

Player metadata does not add a video to the saved Library. The player saves
progress and bookmarks separately. Saving a playlist or video adds that item
to the Library.

## Metadata cache and history

The metadata cache stores stable video and playlist details. It does not store
temporary media stream URLs. The player requests current streams when it loads
a lesson.

The Android database keeps up to 50 distinct videos in recent watch history.
A later watch of the same video updates its entry.

## Tests

`test/database/sqlite_repositories_test.dart` checks repository behavior,
database reopen behavior, schema version, and migration behavior. Add tests
when a schema or repository changes.
