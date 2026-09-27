# Database Boundary and Status

## Intended role

SQLite is the planned primary store for structured learning data: video and
playlist metadata, playlist entries, roadmaps/topics/items, progress, notes,
attachments metadata, bookmarks, and user settings. Large image/PDF bytes belong
in app-managed device storage, with only metadata and a path/reference kept in
SQLite.

## Current state

- `sqflite` is included in `pubspec.yaml`.
- `AppDatabase` and `SqfliteAppDatabase` are placeholders in
  `lib/core/database/database.dart`.
- The placeholder does not open a database, create tables, migrate versions, or
  implement any feature repository.
- GetIt currently registers in-memory feature repositories instead.
- The app can therefore run without SQLite, but user changes are not durable.

## Phase 2.1 work remaining

1. Decide schema version 1 and record entity relationships and delete behavior.
2. Implement database opening and versioned migration callbacks.
3. Create tables and indexes for IDs, foreign keys, order, and query patterns.
4. Implement repositories behind current feature contracts with transactions
   where multiple related records change.
5. Test CRUD, constraints, migration from prior schema versions, duplicate IDs,
   and persistence after close/reopen.
6. Only switch dependency injection from mocks once adapter tests pass.

Do not claim persistence based only on having the package dependency or a
database class name.
