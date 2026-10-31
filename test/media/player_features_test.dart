import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/playback_controller.dart';
import 'package:voyager_learning/core/media/playback_state.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/video_models.dart';
import 'package:voyager_learning/features/history/data/in_memory_recent_watch_history_repository.dart';
import 'package:voyager_learning/features/goals/data/in_memory_daily_goal_repository.dart';
import 'package:voyager_learning/features/library/data/in_memory_learning_library_repository.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/progress/data/in_memory_progress_repository.dart';
import 'package:voyager_learning/features/progress/domain/learning_progress.dart';
import 'package:voyager_learning/features/player/presentation/learning_player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'compact controls fit, quality choices switch, and fullscreen can exit',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = InMemoryLearningLibraryRepository();
      final notes = InMemoryNotesRepository();
      final history = InMemoryRecentWatchHistoryRepository();
      final playback = _FakePlaybackController();
      await tester.pumpWidget(
        MaterialApp(
          home: LearningPlayerScreen(
            playbackController: playback,
            libraryRepository: library,
            notesRepository: notes,
            recentWatchHistoryRepository: history,
            progressRepository: InMemoryProgressRepository(),
            dailyGoalRepository: InMemoryDailyGoalRepository(),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      await tester.ensureVisible(find.text('LOAD VIDEO'));
      await tester.tap(find.text('LOAD VIDEO'));
      await tester.pumpAndSettle();

      final layoutException = tester.takeException();
      expect(layoutException, isNull);
      expect((await history.getRecent()).single.title, 'Sample lesson');
      final qualitySelector = tester.widget<DropdownButton<MediaStreamInfo>>(
        find.byKey(const Key('player-quality-selector')),
      );
      expect(
        qualitySelector.items!.map((item) => (item.child as Text).data),
        containsAll(['720p', '360p']),
      );
      await tester.tap(find.byKey(const Key('player-quality-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('360p').last);
      await tester.pumpAndSettle();
      expect(playback.selectedStream?.resolutionHeight, 360);

      await tester.tap(find.byTooltip('Play'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      playback.refreshPlayback();
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('player-controls-overlay')),
            )
            .opacity,
        0,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('player-video-window'))),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('player-controls-overlay')),
            )
            .opacity,
        1,
      );
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('Enter fullscreen'));
      await tester.tap(find.byTooltip('Enter fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Exit fullscreen'), findsOneWidget);
      await tester.tap(find.byTooltip('Play'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('player-controls-overlay')),
            )
            .opacity,
        0,
      );
      await tester.tapAt(const Offset(180, 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('player-controls-overlay')),
            )
            .opacity,
        1,
      );
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Exit fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enter fullscreen'), findsOneWidget);

      await tester.tap(find.byTooltip('Enter fullscreen'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enter fullscreen'), findsOneWidget);
    },
  );

  testWidgets(
    'player can save a playlist and note, change quality, and enter fullscreen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = InMemoryLearningLibraryRepository();
      final notes = InMemoryNotesRepository();
      final history = InMemoryRecentWatchHistoryRepository();
      final playback = _FakePlaybackController();

      await tester.pumpWidget(
        MaterialApp(
          home: LearningPlayerScreen(
            playbackController: playback,
            libraryRepository: library,
            notesRepository: notes,
            recentWatchHistoryRepository: history,
            progressRepository: InMemoryProgressRepository(),
            dailyGoalRepository: InMemoryDailyGoalRepository(),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'https://www.youtube.com/playlist?list=PL1234567890ABC',
      );
      await tester.ensureVisible(find.text('LOAD VIDEO'));
      await tester.tap(find.text('LOAD VIDEO'));
      await tester.pumpAndSettle();

      expect(find.text('Sample course'), findsOneWidget);
      expect(find.byKey(const Key('player-seek-slider')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('player-seek-slider'))).bottom,
        lessThan(tester.getRect(find.text('Sample course')).top),
      );
      await tester.tap(find.byKey(const Key('save-playlist-button')));
      await tester.pumpAndSettle();
      expect((await library.getPlaylists()).single.title, 'Sample course');
      expect(
        (await library.getPlaylistEntries('PL1234567890ABC')),
        hasLength(1),
      );

      final saveNoteButton = find.byKey(const Key('save-player-note-button'));
      await tester.dragUntilVisible(
        saveNoteButton,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.enterText(find.byType(TextField).last, 'Important idea');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(saveNoteButton);
      await tester.tap(saveNoteButton);
      await tester.pumpAndSettle();
      expect((await notes.getNotes()).single.content, 'Important idea');

      final qualitySelector = tester.widget<DropdownButton<MediaStreamInfo>>(
        find.byKey(const Key('player-quality-selector')),
      );
      qualitySelector.onChanged!(playback.availableStreams.last);
      await tester.pumpAndSettle();
      expect(playback.selectedStream, playback.availableStreams.last);

      await tester.drag(find.byType(ListView), const Offset(0, 900));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Enter fullscreen'));
      await tester.tap(find.byTooltip('Enter fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Exit fullscreen'), findsOneWidget);
      await tester.tap(find.byTooltip('Exit fullscreen'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enter fullscreen'), findsOneWidget);
    },
  );

  testWidgets('restores saved progress without starting playback', (
    tester,
  ) async {
    final progress = InMemoryProgressRepository();
    await progress.saveProgress(
      LearningProgress(
        videoId: 'dQw4w9WgXcQ',
        positionSeconds: 47,
        durationSeconds: 120,
        updatedAt: DateTime.utc(2026, 9, 27),
      ),
    );
    final playback = _FakePlaybackController();
    await tester.pumpWidget(
      MaterialApp(
        home: LearningPlayerScreen(
          playbackController: playback,
          libraryRepository: InMemoryLearningLibraryRepository(),
          notesRepository: InMemoryNotesRepository(),
          recentWatchHistoryRepository: InMemoryRecentWatchHistoryRepository(),
          progressRepository: progress,
          dailyGoalRepository: InMemoryDailyGoalRepository(),
          resumePlayback: true,
          defaultPlaybackSpeed: 1.5,
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextField).first,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.ensureVisible(find.text('LOAD VIDEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOAD VIDEO'));
    await tester.pumpAndSettle();

    expect(playback.snapshot.position, const Duration(seconds: 47));
    expect(playback.snapshot.status, PlayerStatus.ready);
    expect(playback.snapshot.playbackSpeed, 1.5);
  });

  testWidgets('saves videos to a playlist and marks lessons complete', (
    tester,
  ) async {
    final progress = InMemoryProgressRepository();
    final dailyGoals = InMemoryDailyGoalRepository();
    final library = InMemoryLearningLibraryRepository();
    await library.savePlaylist(
      const LearningPlaylist(
        id: 'my-playlist',
        sourceId: 'my-playlist',
        sourceUrl: '',
        title: 'My playlist',
        creator: 'You',
      ),
    );
    final playback = _FakePlaybackController();
    await tester.pumpWidget(
      MaterialApp(
        home: LearningPlayerScreen(
          playbackController: playback,
          libraryRepository: library,
          notesRepository: InMemoryNotesRepository(),
          recentWatchHistoryRepository: InMemoryRecentWatchHistoryRepository(),
          progressRepository: progress,
          dailyGoalRepository: dailyGoals,
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextField).first,
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.ensureVisible(find.text('LOAD VIDEO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LOAD VIDEO'));
    await tester.pumpAndSettle();
    expect(await library.getVideos(), isEmpty);

    final saveToPlaylist = find.text('SAVE TO PLAYLIST');
    await tester.ensureVisible(saveToPlaylist);
    await tester.tap(saveToPlaylist);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My playlist'));
    await tester.pumpAndSettle();
    expect(await library.getPlaylistEntries('my-playlist'), hasLength(1));

    final completeLesson = find.text('DONE');
    await tester.ensureVisible(completeLesson);
    await tester.tap(completeLesson);
    await tester.pumpAndSettle();
    expect((await progress.getProgress('dQw4w9WgXcQ'))?.isCompleted, isTrue);
    expect((await dailyGoals.getSummary(DateTime.now())).completedLessons, 1);
  });
}

class _FakePlaybackController implements PlaybackController {
  _FakePlaybackController() {
    selectedStream = _streams.first;
  }

  final _snapshots = StreamController<PlayerSnapshot>.broadcast();
  final _streams = <MediaStreamInfo>[
    MediaStreamInfo(
      url: Uri.parse('https://media.example/720.mp4'),
      mimeType: 'video/mp4',
      container: 'mp4',
      resolutionHeight: 720,
      hasAudio: true,
      hasVideo: true,
    ),
    MediaStreamInfo(
      url: Uri.parse('https://media.example/360.mp4'),
      mimeType: 'video/mp4',
      container: 'mp4',
      resolutionHeight: 360,
      hasAudio: true,
      hasVideo: true,
    ),
  ];
  PlayerSnapshot _snapshot = const PlayerSnapshot(
    status: PlayerStatus.ready,
    position: Duration.zero,
    duration: Duration(minutes: 2),
    playbackSpeed: 1,
  );

  @override
  PlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  VideoInfo? currentVideo = VideoInfo(
    id: 'dQw4w9WgXcQ',
    source: VideoSourceKind.youtubeVideo,
    url: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
    title: 'Sample lesson',
    duration: Duration(minutes: 2),
    streams: [],
  );

  @override
  PlaylistInfo? currentPlaylist;

  @override
  List<MediaStreamInfo> get availableStreams => List.unmodifiable(_streams);

  @override
  MediaStreamInfo? selectedStream;

  @override
  Future<void> load(String sourceUrl) async {
    final source = SourceDetector.detect(sourceUrl)!;
    currentPlaylist = PlaylistInfo(
      id: source.contentId,
      source: VideoSourceKind.youtubePlaylist,
      url: source.url,
      title: 'Sample course',
      author: 'Voyager',
      entries: [
        PlaylistEntryInfo(
          videoId: 'dQw4w9WgXcQ',
          title: 'Sample lesson',
          position: 0,
          url: Uri.https('www.youtube.com', '/watch', {'v': 'dQw4w9WgXcQ'}),
          duration: const Duration(minutes: 2),
        ),
      ],
    );
  }

  @override
  Future<void> prefetchVideo(String sourceUrl) async {}

  @override
  Future<void> selectLecture(PlaylistEntryInfo entry) async {}

  @override
  Widget buildSurface() => const ColoredBox(color: Colors.black);

  @override
  Future<void> play() async => _emit(PlayerStatus.playing);

  @override
  Future<void> pause() async => _emit(PlayerStatus.paused);

  void _emit(PlayerStatus status) {
    _snapshot = PlayerSnapshot(
      status: status,
      position: _snapshot.position,
      duration: _snapshot.duration,
      playbackSpeed: _snapshot.playbackSpeed,
    );
    _snapshots.add(_snapshot);
  }

  void refreshPlayback() => _emit(PlayerStatus.playing);

  @override
  Future<void> seekTo(Duration position) async {
    _snapshot = PlayerSnapshot(
      status: _snapshot.status,
      position: position,
      duration: _snapshot.duration,
      playbackSpeed: _snapshot.playbackSpeed,
    );
    _snapshots.add(_snapshot);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _snapshot = PlayerSnapshot(
      status: _snapshot.status,
      position: _snapshot.position,
      duration: _snapshot.duration,
      playbackSpeed: speed,
    );
  }

  @override
  Future<void> selectStream(MediaStreamInfo stream) async {
    selectedStream = stream;
  }

  @override
  Future<Duration> get currentPosition async => _snapshot.position;

  @override
  Future<void> dispose() async => _snapshots.close();
}
