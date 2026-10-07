import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voyager_learning/core/database/database.dart';
import 'package:voyager_learning/features/library/data/sqlite_learning_library_repository.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/notes/data/sqlite_notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/progress/data/sqlite_progress_repository.dart';
import 'package:voyager_learning/features/progress/domain/learning_progress.dart';
import 'package:voyager_learning/features/roadmap/data/sqlite_roadmap_repository.dart';
import 'package:voyager_learning/features/roadmap/domain/roadmap.dart';
import 'package:voyager_learning/features/settings/data/sqlite_settings_repository.dart';
import 'package:voyager_learning/features/settings/domain/learning_settings.dart';

void main() {
  late Directory directory;
  late SqfliteAppDatabase database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('voyager-sqlite-test-');
    database = SqfliteAppDatabase(
      databasePathProvider: () async => directory.path,
      databaseFactory: databaseFactoryFfi,
    );
    await database.initialize();
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('creates versioned schema with expected tables and indexes', () async {
    final tables = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table'",
    );
    final names = tables.map((row) => row['name']).toSet();
    expect(
      names,
      containsAll([
        'roadmaps',
        'topics',
        'videos',
        'playlists',
        'playlist_entries',
        'notes',
        'progress',
        'bookmarks',
        'settings',
        'video_metadata_cache',
      ]),
    );
    final indexes = await database.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'index'",
    );
    expect(
      indexes.map((row) => row['name']),
      contains('topics_roadmap_position'),
    );
  });

  test(
    'persists roadmap and topic edits and cascades roadmap deletion',
    () async {
      final repository = SqliteRoadmapRepository(database);
      const roadmap = Roadmap(
        id: 'r1',
        title: 'Foundations',
        description: 'A sequence of study topics',
        isActive: true,
      );
      await repository.saveRoadmap(roadmap);
      const topic = Topic(
        id: 't1',
        roadmapId: 'r1',
        title: 'First topic',
        status: TopicStatus.inProgress,
        position: 2,
      );
      await repository.saveTopic(topic);
      final savedTopics = await repository.getTopicsForRoadmap('r1');
      expect(savedTopics, hasLength(1));
      expect(savedTopics.single.id, topic.id);
      expect(savedTopics.single.position, topic.position);

      await repository.saveRoadmap(
        const Roadmap(
          id: 'r1',
          title: 'Updated',
          description: 'Updated details',
          isActive: false,
        ),
      );
      expect((await repository.getRoadmap('r1'))?.title, 'Updated');
      expect(
        (await repository.getTopicsForRoadmap('r1')).single.title,
        topic.title,
      );

      await repository.deleteRoadmap('r1');
      expect(await repository.getRoadmap('r1'), isNull);
      expect(await repository.getTopicsForRoadmap('r1'), isEmpty);
    },
  );

  test(
    'persists library records and replaces playlist entries atomically',
    () async {
      final repository = SqliteLearningLibraryRepository(database);
      const video = LearningVideo(
        id: 'v1',
        sourceId: 'source-v1',
        sourceUrl: 'https://example.test/v1',
        title: 'Lesson one',
        creator: 'Teacher',
        durationSeconds: 120,
      );
      const playlist = LearningPlaylist(
        id: 'p1',
        sourceId: 'source-p1',
        sourceUrl: 'https://example.test/playlist',
        title: 'Course',
        creator: 'Teacher',
      );
      await repository.saveVideo(video);
      await repository.savePlaylist(playlist);
      await repository.savePlaylistEntries('p1', const [
        PlaylistEntry(playlistId: 'p1', videoId: 'v1', position: 0),
      ]);
      expect((await repository.getVideos()).single.title, video.title);
      expect((await repository.getPlaylist('p1'))?.title, playlist.title);
      expect((await repository.getPlaylistEntries('p1')).single.position, 0);

      await expectLater(
        repository.savePlaylistEntries('p1', const [
          PlaylistEntry(playlistId: 'p1', videoId: 'missing', position: 1),
        ]),
        throwsA(anything),
      );
      final existingEntries = await repository.getPlaylistEntries('p1');
      expect(existingEntries, hasLength(1));
      expect(existingEntries.single.videoId, 'v1');
    },
  );

  test(
    'persists notes, progress, bookmarks, and settings across reopen',
    () async {
      final library = SqliteLearningLibraryRepository(database);
      const video = LearningVideo(
        id: 'v1',
        sourceId: 'source-v1',
        sourceUrl: 'https://example.test/v1',
        title: 'Lesson',
        creator: 'Teacher',
        durationSeconds: 200,
      );
      await library.saveVideo(video);

      final now = DateTime.utc(2026, 9, 27);
      final notes = SqliteNotesRepository(database);
      final note = StudyNote(
        id: 'n1',
        videoId: video.id,
        content: 'Remember this',
        timestampSeconds: 34,
        createdAt: now,
        updatedAt: now,
      );
      await notes.saveNote(note);
      expect(
        (await notes.getNotes(videoId: video.id)).single.content,
        note.content,
      );

      final progress = SqliteProgressRepository(database);
      final savedProgress = LearningProgress(
        videoId: video.id,
        positionSeconds: 35,
        durationSeconds: 200,
        updatedAt: now,
      );
      await progress.saveProgress(savedProgress);
      final loadedProgress = await progress.getProgress(video.id);
      expect(loadedProgress?.positionSeconds, savedProgress.positionSeconds);
      expect(loadedProgress?.durationSeconds, savedProgress.durationSeconds);

      final bookmark = LearningBookmark(
        id: 'b1',
        videoId: 'v1',
        positionSeconds: 34,
        label: 'Important',
        createdAt: now,
      );
      await progress.saveBookmark(bookmark);
      final loadedBookmarks = await progress.getBookmarks(video.id);
      expect(loadedBookmarks.single.positionSeconds, bookmark.positionSeconds);
      expect(loadedBookmarks.single.label, bookmark.label);

      final settings = SqliteSettingsRepository(database);
      const learningSettings = LearningSettings(
        appearance: AppearanceMode.dark,
        defaultPlaybackSpeed: 1.5,
        resumePlayback: false,
      );
      await settings.saveSettings(learningSettings);
      final loadedSettings = await settings.getSettings();
      expect(loadedSettings.appearance, learningSettings.appearance);
      expect(
        loadedSettings.defaultPlaybackSpeed,
        learningSettings.defaultPlaybackSpeed,
      );
      expect(loadedSettings.resumePlayback, learningSettings.resumePlayback);

      await database.close();
      database = SqfliteAppDatabase(
        databasePathProvider: () async => directory.path,
        databaseFactory: databaseFactoryFfi,
      );
      await database.initialize();
      final reopenedNotes = await SqliteNotesRepository(database)
          .getNotes(videoId: video.id);
      expect(reopenedNotes.single.content, note.content);
      final reopenedProgress = await SqliteProgressRepository(database)
          .getProgress(video.id);
      expect(reopenedProgress?.positionSeconds, savedProgress.positionSeconds);
      final reopenedSettings = await SqliteSettingsRepository(database)
          .getSettings();
      expect(reopenedSettings.appearance, learningSettings.appearance);
    },
  );

  test('database uses its configured application file name', () {
    expect(
      path.join(directory.path, SqfliteAppDatabase.databaseFileName),
      endsWith('voyager_learning.db'),
    );
    expect(SqfliteAppDatabase.schemaVersion, 2);
  });

  test(
    'upgrades a version 1 database without deleting existing records',
    () async {
      final legacyDirectory = await Directory.systemTemp.createTemp(
        'voyager-v1-migration-',
      );
      final legacyPath = path.join(
        legacyDirectory.path,
        SqfliteAppDatabase.databaseFileName,
      );
      final legacy = await databaseFactoryFfi.openDatabase(
        legacyPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE migration_probe (value TEXT NOT NULL)',
            );
            await db.insert('migration_probe', {'value': 'preserved'});
          },
        ),
      );
      await legacy.close();

      final upgraded = SqfliteAppDatabase(
        databasePathProvider: () async => legacyDirectory.path,
        databaseFactory: databaseFactoryFfi,
      );
      try {
        await upgraded.initialize();
        expect(
          (await upgraded.query(
            'sqlite_master',
            columns: ['name'],
            where: "type = 'table' AND name = 'video_metadata_cache'",
          )),
          hasLength(1),
        );
        expect(await upgraded.query('migration_probe'), [
          {'value': 'preserved'},
        ]);
      } finally {
        await upgraded.close();
        await legacyDirectory.delete(recursive: true);
      }
    },
  );
}
