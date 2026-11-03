import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqlite;

abstract interface class DatabaseExecutor {
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  });

  Future<int> insert(String table, Map<String, Object?> values);

  Future<void> upsert(
    String table,
    Map<String, Object?> values, {
    required String keyWhere,
    required List<Object?> keyArgs,
  });

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  });

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  });
}

abstract interface class DatabaseTransaction implements DatabaseExecutor {}

// This is the main database contract.
// Every feature repo talks to this instead of using raw SQLite calls.
abstract interface class AppDatabase implements DatabaseExecutor {
  Future<void> initialize();
  Future<void> close();
  Future<T> transaction<T>(
    Future<T> Function(DatabaseTransaction transaction) action,
  );
}

class SqfliteAppDatabase implements AppDatabase {
  SqfliteAppDatabase({
    Future<String> Function()? databasePathProvider,
    sqlite.DatabaseFactory? databaseFactory,
  }) : _databasePathProvider = databasePathProvider ?? sqlite.getDatabasesPath,
       _databaseFactory = databaseFactory ?? sqlite.databaseFactory;

  final Future<String> Function() _databasePathProvider;
  final sqlite.DatabaseFactory _databaseFactory;
  sqlite.Database? _database;

  static const int schemaVersion = 7;
  static const String databaseFileName = 'voyager_learning.db';

  Future<sqlite.Database> get _connection async {
    final database = _database;
    if (database == null) {
      throw StateError('Database is not initialized.');
    }
    return database;
  }

  @override
  // Create the SQLite file once, then keep using it for the app life.
  Future<void> initialize() async {
    if (_database != null) return;
    final directory = await _databasePathProvider();
    _database = await _databaseFactory.openDatabase(
      path.join(directory, databaseFileName),
      options: sqlite.OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          await _createMetadataCache(db);
          await _createRecentWatchHistory(db);
          await _createDailyGoalActivity(db);
          await _createWatchActivity(db);
          await _createLocalProfile(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeSchema(db, oldVersion, newVersion);
        },
      ),
    );
  }

  // This is the app's main data schema.
  // It stores topics, notes, videos, progress, and user settings.
  Future<void> _createSchema(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE roadmaps (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1))
      )
    ''');
    await db.execute('''
      CREATE TABLE topics (
        id TEXT PRIMARY KEY NOT NULL,
        roadmap_id TEXT NOT NULL REFERENCES roadmaps(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('notStarted', 'inProgress', 'completed')),
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE videos (
        id TEXT PRIMARY KEY NOT NULL,
        source_id TEXT NOT NULL,
        source_url TEXT NOT NULL,
        title TEXT NOT NULL,
        creator TEXT NOT NULL DEFAULT '',
        duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
        thumbnail_url TEXT,
        is_saved INTEGER NOT NULL DEFAULT 1 CHECK (is_saved IN (0, 1))
      )
    ''');
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY NOT NULL,
        source_id TEXT NOT NULL,
        source_url TEXT NOT NULL,
        title TEXT NOT NULL,
        creator TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE playlist_entries (
        playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, video_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL DEFAULT 'Untitled Note',
        content TEXT NOT NULL,
        content_json TEXT NOT NULL DEFAULT '',
        video_id TEXT REFERENCES videos(id) ON DELETE SET NULL,
        topic_id TEXT REFERENCES topics(id) ON DELETE SET NULL,
        timestamp_seconds INTEGER CHECK (timestamp_seconds IS NULL OR timestamp_seconds >= 0),
        resource_type TEXT,
        resource_id TEXT,
        resource_name TEXT,
        resource_archived INTEGER NOT NULL DEFAULT 0
          CHECK (resource_archived IN (0, 1)),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE progress (
        video_id TEXT PRIMARY KEY NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
        position_seconds INTEGER NOT NULL CHECK (position_seconds >= 0),
        duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
        is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)),
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY NOT NULL,
        video_id TEXT NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
        position_seconds INTEGER NOT NULL CHECK (position_seconds >= 0),
        label TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        appearance TEXT NOT NULL DEFAULT 'system'
          CHECK (appearance IN ('system', 'light', 'dark')),
        playback_speed REAL NOT NULL DEFAULT 1 CHECK (playback_speed > 0),
        resume_playback INTEGER NOT NULL DEFAULT 1
          CHECK (resume_playback IN (0, 1)),
        confirm_topic_completion INTEGER NOT NULL DEFAULT 1
          CHECK (confirm_topic_completion IN (0, 1)),
        daily_study_minutes_target INTEGER NOT NULL DEFAULT 30
          CHECK (daily_study_minutes_target > 0),
        daily_lessons_target INTEGER NOT NULL DEFAULT 1
          CHECK (daily_lessons_target > 0)
      )
    ''');
    await db.execute(
      'CREATE INDEX topics_roadmap_position ON topics(roadmap_id, position)',
    );
    await db.execute(
      'CREATE INDEX playlist_entries_order ON playlist_entries(playlist_id, position)',
    );
    await db.execute(
      'CREATE INDEX notes_video_updated ON notes(video_id, updated_at)',
    );
    await db.execute(
      'CREATE INDEX notes_topic_updated ON notes(topic_id, updated_at)',
    );
    await db.execute(
      'CREATE INDEX notes_resource_updated ON notes(resource_type, resource_id, updated_at DESC)',
    );
    await db.execute('CREATE INDEX notes_updated ON notes(updated_at DESC)');
    await db.execute(
      'CREATE INDEX bookmarks_video_position ON bookmarks(video_id, position_seconds)',
    );
  }

  // Small cache for video metadata so the app does not fetch the same info again and again.
  Future<void> _createMetadataCache(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE video_metadata_cache (
        source TEXT NOT NULL,
        content_id TEXT NOT NULL,
        kind TEXT NOT NULL CHECK (kind IN ('video', 'playlist')),
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (source, content_id, kind)
      )
    ''');
  }

  Future<void> _createRecentWatchHistory(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE recent_watch_history (
        video_id TEXT PRIMARY KEY NOT NULL,
        source_url TEXT NOT NULL,
        title TEXT NOT NULL,
        creator TEXT NOT NULL DEFAULT '',
        duration_seconds INTEGER NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
        thumbnail_url TEXT,
        watched_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX recent_watch_history_order ON recent_watch_history(watched_at DESC)',
    );
  }

  Future<void> _createDailyGoalActivity(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE daily_goal_activity (
        activity_date TEXT NOT NULL,
        video_id TEXT NOT NULL,
        played_seconds INTEGER NOT NULL DEFAULT 0 CHECK (played_seconds >= 0),
        completed_at TEXT,
        PRIMARY KEY (activity_date, video_id)
      )
    ''');
  }

  Future<void> _createWatchActivity(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE watch_activity (
        date_key TEXT PRIMARY KEY NOT NULL,
        watched_seconds INTEGER NOT NULL DEFAULT 0 CHECK (watched_seconds >= 0),
        is_qualified INTEGER NOT NULL DEFAULT 0 CHECK (is_qualified IN (0, 1)),
        updated_at_utc TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createLocalProfile(sqlite.DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE local_profile (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        username TEXT NOT NULL,
        updated_at_utc TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeSchema(
    sqlite.DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1 && newVersion >= 1) {
      await _createSchema(db);
    }
    if (oldVersion < 2 && newVersion >= 2) {
      await _createMetadataCache(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await _createRecentWatchHistory(db);
    }
    if (oldVersion < 4 && newVersion >= 4) {
      await db.execute(
        'ALTER TABLE settings ADD COLUMN daily_study_minutes_target INTEGER NOT NULL DEFAULT 30 CHECK (daily_study_minutes_target > 0)',
      );
      await db.execute(
        'ALTER TABLE settings ADD COLUMN daily_lessons_target INTEGER NOT NULL DEFAULT 1 CHECK (daily_lessons_target > 0)',
      );
      await _createDailyGoalActivity(db);
    }
    if (oldVersion < 5 && newVersion >= 5) {
      await db.execute(
        'ALTER TABLE videos ADD COLUMN is_saved INTEGER NOT NULL DEFAULT 1 CHECK (is_saved IN (0, 1))',
      );
    }
    if (oldVersion < 6 && newVersion >= 6) {
      await _createWatchActivity(db);
      await _createLocalProfile(db);
    }
    if (oldVersion >= 1 && oldVersion < 7 && newVersion >= 7) {
      final noteTables = await db.query(
        'sqlite_master',
        columns: ['name'],
        where: "type = 'table' AND name = 'notes'",
      );
      if (noteTables.isEmpty) {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY NOT NULL,
            title TEXT NOT NULL DEFAULT 'Untitled Note',
            content TEXT NOT NULL,
            content_json TEXT NOT NULL DEFAULT '',
            video_id TEXT REFERENCES videos(id) ON DELETE SET NULL,
            topic_id TEXT REFERENCES topics(id) ON DELETE SET NULL,
            timestamp_seconds INTEGER
              CHECK (timestamp_seconds IS NULL OR timestamp_seconds >= 0),
            resource_type TEXT,
            resource_id TEXT,
            resource_name TEXT,
            resource_archived INTEGER NOT NULL DEFAULT 0
              CHECK (resource_archived IN (0, 1)),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      } else {
        await db.execute(
          "ALTER TABLE notes ADD COLUMN title TEXT NOT NULL DEFAULT 'Untitled Note'",
        );
        await db.execute(
          "ALTER TABLE notes ADD COLUMN content_json TEXT NOT NULL DEFAULT ''",
        );
        await db.execute('ALTER TABLE notes ADD COLUMN resource_type TEXT');
        await db.execute('ALTER TABLE notes ADD COLUMN resource_id TEXT');
        await db.execute('ALTER TABLE notes ADD COLUMN resource_name TEXT');
        await db.execute(
          'ALTER TABLE notes ADD COLUMN resource_archived INTEGER NOT NULL DEFAULT 0 CHECK (resource_archived IN (0, 1))',
        );
      }
      if (noteTables.isNotEmpty) {
        await db.execute('''
        UPDATE notes
        SET resource_type = 'video',
            resource_id = video_id,
            resource_name = (SELECT title FROM videos WHERE videos.id = notes.video_id)
        WHERE video_id IS NOT NULL
      ''');
        await db.execute('''
        UPDATE notes
        SET resource_type = 'lesson',
            resource_id = topic_id,
            resource_name = (SELECT title FROM topics WHERE topics.id = notes.topic_id)
        WHERE topic_id IS NOT NULL
      ''');
      }
      await db.execute(
        'CREATE INDEX notes_resource_updated ON notes(resource_type, resource_id, updated_at DESC)',
      );
      await db.execute('CREATE INDEX notes_updated ON notes(updated_at DESC)');
    }
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    return (await _connection).query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    return (await _connection).insert(table, values);
  }

  @override
  Future<void> upsert(
    String table,
    Map<String, Object?> values, {
    required String keyWhere,
    required List<Object?> keyArgs,
  }) async {
    await transaction((transaction) async {
      final affected = await transaction.update(
        table,
        values,
        where: keyWhere,
        whereArgs: keyArgs,
      );
      if (affected == 0) {
        await transaction.insert(table, values);
      }
    });
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return (await _connection).update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    return (await _connection).delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseTransaction transaction) action,
  ) async {
    return (await _connection).transaction(
      (transaction) => action(_SqfliteTransaction(transaction)),
    );
  }

  @override
  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}

class _SqfliteTransaction implements DatabaseTransaction {
  const _SqfliteTransaction(this._transaction);

  final sqlite.Transaction _transaction;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) {
    return _transaction.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) {
    return _transaction.insert(table, values);
  }

  @override
  Future<void> upsert(
    String table,
    Map<String, Object?> values, {
    required String keyWhere,
    required List<Object?> keyArgs,
  }) async {
    final affected = await _transaction.update(
      table,
      values,
      where: keyWhere,
      whereArgs: keyArgs,
    );
    if (affected == 0) {
      await _transaction.insert(table, values);
    }
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) {
    return _transaction.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) {
    return _transaction.delete(table, where: where, whereArgs: whereArgs);
  }
}
