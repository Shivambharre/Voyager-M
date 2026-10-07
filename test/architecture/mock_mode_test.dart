import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/di/service_locator.dart';
import 'package:voyager_learning/core/filtering/content_policy.dart';
import 'package:voyager_learning/core/media/media_provider.dart';
import 'package:voyager_learning/core/media/player_engine.dart';
import 'package:voyager_learning/core/storage/local_file_storage.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/library/domain/learning_library_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/notes/domain/notes_repository.dart';
import 'package:voyager_learning/features/progress/domain/progress_repository.dart';
import 'package:voyager_learning/features/roadmap/domain/roadmap_repository.dart';
import 'package:voyager_learning/features/settings/domain/learning_settings.dart';
import 'package:voyager_learning/features/settings/domain/settings_repository.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    await configureDependencies(useMocks: true);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  test('registers replaceable mock implementations centrally', () {
    expect(serviceLocator.get<RoadmapRepository>(), isA<RoadmapRepository>());
    expect(
      serviceLocator.get<LearningLibraryRepository>(),
      isA<LearningLibraryRepository>(),
    );
    expect(serviceLocator.get<NotesRepository>(), isA<NotesRepository>());
    expect(serviceLocator.get<ProgressRepository>(), isA<ProgressRepository>());
    expect(serviceLocator.get<SettingsRepository>(), isA<SettingsRepository>());
    expect(serviceLocator.get<MediaProvider>(), isA<MockMediaProvider>());
    expect(serviceLocator.get<PlayerEngine>(), isA<MockPlayerEngine>());
    expect(serviceLocator.get<ContentPolicy>(), isA<LearningContentPolicy>());
    expect(serviceLocator.get<LocalFileStorage>(), isA<InMemoryFileStorage>());
  });

  test(
    'mock repositories support basic create, read, and delete flows',
    () async {
      final roadmaps = serviceLocator.get<RoadmapRepository>();
      final initial = await roadmaps.getRoadmaps();
      expect(initial, hasLength(1));
      expect(await roadmaps.getTopicsForRoadmap('demo-roadmap'), hasLength(1));

      final library = serviceLocator.get<LearningLibraryRepository>();
      const video = LearningVideo(
        id: 'video-1',
        sourceId: 'source-video-1',
        sourceUrl: 'https://example.com/lesson',
        title: 'Test lesson',
        creator: 'Study creator',
        durationSeconds: 120,
      );
      await library.saveVideo(video);
      expect(await library.getVideo(video.id), video);
      await library.deleteVideo(video.id);
      expect(await library.getVideo(video.id), isNull);

      final notes = serviceLocator.get<NotesRepository>();
      final now = DateTime.utc(2026);
      final note = StudyNote(
        id: 'note-1',
        content: 'Important idea',
        videoId: 'video-1',
        timestampSeconds: 30,
        createdAt: now,
        updatedAt: now,
      );
      await notes.saveNote(note);
      expect(await notes.getNotes(videoId: 'video-1'), [note]);
      await notes.deleteNote(note.id);
      expect(await notes.getNotes(), isEmpty);

      final settings = serviceLocator.get<SettingsRepository>();
      const newSettings = LearningSettings(
        appearance: AppearanceMode.dark,
        defaultPlaybackSpeed: 1.25,
      );
      await settings.saveSettings(newSettings);
      final savedSettings = await settings.getSettings();
      expect(savedSettings.appearance, AppearanceMode.dark);
      expect(savedSettings.defaultPlaybackSpeed, 1.25);
    },
  );

  test(
    'mock media, player, content policy, and storage expose their contracts',
    () async {
      final media = serviceLocator.get<MediaProvider>();
      final asset = await media.loadAsset('https://example.com/lesson');
      expect(asset.sourceUrl, 'https://example.com/lesson');
      await expectLater(media.loadAsset('not a url'), throwsFormatException);

      final player = serviceLocator.get<PlayerEngine>();
      await player.load(
        const MediaAsset(
          id: 'lesson-1',
          title: 'Lesson',
          sourceUrl: 'https://example.com/lesson',
          durationSeconds: 120,
        ),
      );
      expect(player.snapshot.status, PlayerStatus.ready);
      await player.play();
      expect(player.snapshot.status, PlayerStatus.playing);
      await player.pause();
      expect(player.snapshot.status, PlayerStatus.paused);
      await player.seekTo(const Duration(seconds: 20));
      expect(player.snapshot.position, const Duration(seconds: 20));
      await player.setPlaybackSpeed(1.5);
      expect(player.snapshot.playbackSpeed, 1.5);
      await player.dispose();

      final policy = serviceLocator.get<ContentPolicy>();
      expect(
        policy.evaluate('https://video.example/lesson'),
        ContentDecision.allow,
      );
      expect(
        policy.evaluate('https://video.example/shorts/123'),
        ContentDecision.block,
      );
      expect(policy.evaluate('invalid'), ContentDecision.unavailable);

      final storage = serviceLocator.get<LocalFileStorage>();
      final path = await storage.saveFile('notes.txt', [1, 2, 3]);
      expect(await storage.listFiles(), [path]);
      await storage.deleteFile(path);
      expect(await storage.listFiles(), isEmpty);
    },
  );
}
