import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voyager_learning/core/database/database.dart';
import 'package:voyager_learning/features/library/data/sqlite_learning_library_repository.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/goals/data/sqlite_daily_goal_repository.dart';
import 'package:voyager_learning/features/history/data/sqlite_recent_watch_history_repository.dart';
import 'package:voyager_learning/features/history/domain/recent_watch_entry.dart';
import 'package:voyager_learning/features/notes/data/sqlite_notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/progress/data/sqlite_progress_repository.dart';
import 'package:voyager_learning/features/progress/domain/learning_progress.dart';
import 'package:voyager_learning/features/roadmap/data/sqlite_roadmap_repository.dart';
import 'package:voyager_learning/features/roadmap/domain/roadmap.dart';
import 'package:voyager_learning/features/settings/data/sqlite_settings_repository.dart';
import 'package:voyager_learning/features/settings/domain/learning_settings.dart';
import 'package:voyager_learning/features/watch_activity/data/sqlite_watch_activity_repository.dart';
import 'package:voyager_learning/features/profile/data/sqlite_local_profile_repository.dart';
import 'package:voyager_learning/features/profile/domain/local_profile.dart';
import 'package:voyager_learning/features/watch_activity/domain/watch_activity.dart';

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
        'recent_watch_history',
        'daily_goal_activity',
        'watch_activity',
        'local_profile',
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
    'persists one cumulative watch activity record per local date',
    () async {
      final repository = SqliteWatchActivityRepository(database);
      final timestamp = DateTime.utc(2026, 10, 31, 12);
      await repository.addEligibleSeconds(
        dateKey: '2026-10-31',
        seconds: 14 * 60,
        updatedAtUtc: timestamp,
      );
      expect((await repository.getActivities()).single.isQualified, isFalse);
      await repository.addEligibleSeconds(
        dateKey: '2026-10-31',
        seconds: 60,
        updatedAtUtc: timestamp.add(const Duration(minutes: 1)),
      );

      final activities = await repository.getActivities();
      expect(activities, hasLength(1));
      expect(
        activities.single.watchedSeconds,
        WatchActivity.dailyTargetSeconds,
      );
      expect(activities.single.isQualified, isTrue);
      expect(
        activities.single.updatedAtUtc,
        timestamp.add(const Duration(minutes: 1)),
      );
    },
  );

  test('persists editable local profile values', () async {
    final repository = SqliteLocalProfileRepository(database);
    expect((await repository.getProfile()).displayName, 'Voyager Learner');
    const updated = LocalProfile(displayName: 'Ada Lovelace', username: 'ada');
    await repository.saveProfile(updated);
    expect(await repository.getProfile(), isNotNull);
    final profile = await repository.getProfile();
    expect(profile.displayName, updated.displayName);
    expect(profile.username, updated.username);
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

  test('persists and orders recent watch history', () async {
    final repository = SqliteRecentWatchHistoryRepository(database);
    final firstWatch = DateTime.utc(2026, 10, 29);
    final latestWatch = firstWatch.add(const Duration(hours: 1));
    await repository.record(
      RecentWatchEntry(
        videoId: 'v1',
        sourceUrl: 'https://example.test/v1',
        title: 'Lesson one',
        creator: 'Teacher',
        durationSeconds: 240,
        watchedAt: firstWatch,
      ),
    );
    await repository.record(
      RecentWatchEntry(
        videoId: 'v2',
        sourceUrl: 'https://example.test/v2',
        title: 'Lesson two',
        creator: 'Teacher',
        durationSeconds: 300,
        watchedAt: latestWatch,
      ),
    );
    await repository.record(
      RecentWatchEntry(
        videoId: 'v1',
        sourceUrl: 'https://example.test/v1',
        title: 'Lesson one',
        creator: 'Teacher',
        durationSeconds: 240,
        watchedAt: latestWatch.add(const Duration(minutes: 1)),
      ),
    );

    final recent = await repository.getRecent();
    expect(recent.map((entry) => entry.videoId), ['v1', 'v2']);
    expect(recent.first.title, 'Lesson one');

    await repository.clear();
    expect(await repository.getRecent(), isEmpty);
  });

  test(
    'keeps player metadata out of the saved library until requested',
    () async {
      final repository = SqliteLearningLibraryRepository(database);
      const video = LearningVideo(
        id: 'metadata-only',
        sourceId: 'metadata-only',
        sourceUrl: 'https://example.test/metadata-only',
        title: 'Watched lesson',
        creator: 'Teacher',
        durationSeconds: 120,
      );

      await repository.saveVideoMetadata(video);

      expect((await repository.getVideo(video.id))?.id, video.id);
      expect(await repository.getVideos(), isEmpty);

      await repository.saveVideo(video);
      expect((await repository.getVideos()).map((item) => item.id), [video.id]);
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
        confirmTopicCompletion: false,
        dailyStudyMinutesTarget: 45,
        dailyLessonsTarget: 2,
      );
      await settings.saveSettings(learningSettings);
      final loadedSettings = await settings.getSettings();
      expect(loadedSettings.appearance, learningSettings.appearance);
      expect(
        loadedSettings.defaultPlaybackSpeed,
        learningSettings.defaultPlaybackSpeed,
      );
      expect(loadedSettings.resumePlayback, learningSettings.resumePlayback);
      expect(
        loadedSettings.confirmTopicCompletion,
        learningSettings.confirmTopicCompletion,
      );
      expect(
        loadedSettings.dailyStudyMinutesTarget,
        learningSettings.dailyStudyMinutesTarget,
      );
      expect(
        loadedSettings.dailyLessonsTarget,
        learningSettings.dailyLessonsTarget,
      );

      final goals = SqliteDailyGoalRepository(database);
      final activityDate = DateTime(2026, 9, 27);
      await goals.addPlaybackTime(
        date: activityDate,
        videoId: video.id,
        seconds: 125,
      );
      await goals.addPlaybackTime(
        date: activityDate,
        videoId: video.id,
        seconds: 40,
      );
      await goals.markLessonCompleted(date: activityDate, videoId: video.id);
      await goals.markLessonCompleted(date: activityDate, videoId: video.id);
      final dailySummary = await goals.getSummary(activityDate);
      expect(dailySummary.playedSeconds, 165);
      expect(dailySummary.completedLessons, 1);

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
      expect(
        reopenedSettings.dailyStudyMinutesTarget,
        learningSettings.dailyStudyMinutesTarget,
      );
      expect(
        reopenedSettings.dailyLessonsTarget,
        learningSettings.dailyLessonsTarget,
      );
      final reopenedGoals = await SqliteDailyGoalRepository(database)
          .getSummary(activityDate);
      expect(reopenedGoals.playedSeconds, 165);
      expect(reopenedGoals.completedLessons, 1);
    },
  );

  test('database uses its configured application file name', () {
    expect(
      path.join(directory.path, SqfliteAppDatabase.databaseFileName),
      endsWith('voyager_learning.db'),
    );
    expect(SqfliteAppDatabase.schemaVersion, 6);
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
            await db.execute('''
              CREATE TABLE videos (
                id TEXT PRIMARY KEY NOT NULL,
                source_id TEXT NOT NULL,
                source_url TEXT NOT NULL,
                title TEXT NOT NULL,
                creator TEXT NOT NULL DEFAULT '',
                duration_seconds INTEGER NOT NULL DEFAULT 0,
                thumbnail_url TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE settings (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                appearance TEXT NOT NULL DEFAULT 'system',
                playback_speed REAL NOT NULL DEFAULT 1,
                resume_playback INTEGER NOT NULL DEFAULT 1,
                confirm_topic_completion INTEGER NOT NULL DEFAULT 1
              )
            ''');
            await db.insert('videos', {
              'id': 'legacy-video',
              'source_id': 'legacy-video',
              'source_url': 'https://example.test/legacy-video',
              'title': 'Legacy saved lesson',
              'creator': 'Teacher',
              'duration_seconds': 120,
            });
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
        expect(
          await upgraded.query(
            'sqlite_master',
            columns: ['name'],
            where: "type = 'table' AND name IN ('recent_watch_history', 'watch_activity', 'local_profile')",
          ),
          hasLength(3),
        );
        expect(await upgraded.query('migration_probe'), [
          {'value': 'preserved'},
        ]);
        expect(
          (await SqliteLearningLibraryRepository(
            upgraded,
          ).getVideos()).single.id,
          'legacy-video',
        );
      } finally {
        await upgraded.close();
        await legacyDirectory.delete(recursive: true);
      }
    },
  );
}
