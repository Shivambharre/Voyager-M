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
  })  : _databasePathProvider =
            databasePathProvider ?? sqlite.getDatabasesPath,
        _databaseFactory = databaseFactory ?? sqlite.databaseFactory;

  final Future<String> Function() _databasePathProvider;
  final sqlite.DatabaseFactory _databaseFactory;
  sqlite.Database? _database;

  static const int schemaVersion = 2;
  static const String databaseFileName = 'voyager_learning.db';

  Future<sqlite.Database> get _connection async {
    final database = _database;
    if (database == null) {
      throw StateError('Database is not initialized.');
    }
    return database;
  }

  @override
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
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeSchema(db, oldVersion, newVersion);
        },
      ),
    );
  }

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
        thumbnail_url TEXT
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
        content TEXT NOT NULL,
        video_id TEXT REFERENCES videos(id) ON DELETE SET NULL,
        topic_id TEXT REFERENCES topics(id) ON DELETE SET NULL,
        timestamp_seconds INTEGER CHECK (timestamp_seconds IS NULL OR timestamp_seconds >= 0),
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
          CHECK (confirm_topic_completion IN (0, 1))
      )
    ''');
    await db.execute('CREATE INDEX topics_roadmap_position ON topics(roadmap_id, position)');
    await db.execute('CREATE INDEX playlist_entries_order ON playlist_entries(playlist_id, position)');
    await db.execute('CREATE INDEX notes_video_updated ON notes(video_id, updated_at)');
    await db.execute('CREATE INDEX notes_topic_updated ON notes(topic_id, updated_at)');
    await db.execute('CREATE INDEX bookmarks_video_position ON bookmarks(video_id, position_seconds)');
  }

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
