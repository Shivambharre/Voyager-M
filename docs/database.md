# Database Boundary and Status

## Intended role

SQLite is the planned primary store for structured learning data: video and
playlist metadata, playlist entries, roadmaps/topics/items, progress, notes,
attachments metadata, bookmarks, and user settings. Large image/PDF bytes belong
in app-managed device storage, with only metadata and a path/reference kept in
SQLite.

## Current state

- `SqfliteAppDatabase` opens `voyager_learning.db` and creates the core
  roadmap, library, playlist, note, progress, bookmark, settings, and metadata
  cache tables.
- Schema version 2 adds `video_metadata_cache`; the version-1 upgrade is tested
  to create that table and preserve existing study records.
- SQLite-backed repositories exist for roadmaps, library, notes, progress, and
  settings. Android DI selects these repositories; mock/Web mode uses
  in-memory implementations.
- Metadata caching stores title, thumbnail, duration, author, and playlist
  entry order, but intentionally excludes temporary media stream URLs.

## Current database status

1. Migration-from-v1 coverage is in place for the schema v2 metadata cache table
   and existing study records.
2. Roadmap, library, notes, progress, settings, and metadata repositories are
   wired to real SQLite adapters on Android.
3. The Home, Library, and Notes screens now read repository state instead of
   local sample lists.
4. Close/reopen behavior and repository CRUD tests remain the main regression
   safety net for schema and persistence changes.

Device-file storage remains a separate deferred adapter; do not store large
media bytes in SQLite.
