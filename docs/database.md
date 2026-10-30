# Database Boundary and Status

## Scope

SQLite is the Android store for structured learning data: video and playlist
metadata, playlist entries, roadmaps/topics, progress, notes, bookmarks, and
user settings. Large media bytes are not stored in the database.

## Current state

- `SqfliteAppDatabase` opens `voyager_learning.db` and creates the core
  roadmap, library, playlist, note, progress, bookmark, settings, and metadata
  cache tables.
- Schema version 2 adds `video_metadata_cache`; schema version 3 adds bounded
  recent watch history. Upgrades preserve existing study records.
- SQLite-backed repositories exist for roadmaps, library, notes, progress, and
  settings. Android DI selects these repositories; mock/Web mode uses
  in-memory implementations.
- Recent watch history uses its own SQLite table on Android and an in-memory
  repository on Web/mock; it stores stable video details and watch timestamps,
  not temporary stream URLs.
- Metadata caching stores title, thumbnail, duration, author, and playlist
  entry order, but intentionally excludes temporary media stream URLs.

## Remaining work

1. Add migration-from-v1 coverage against an actual version-1 database fixture.
2. Add missing schema/repository coverage as new learning entities are
  implemented.
3. Connect progress and settings screens/lifecycle to their existing
  repositories.
4. Continue testing constraints, duplicate handling, and close/reopen behavior.

Device-file attachment storage is not part of the active app flow. Do not store
large media bytes in SQLite.
