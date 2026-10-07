import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/playback_controller.dart';
import 'package:voyager_learning/core/media/player_engine.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/video_models.dart';
import 'package:voyager_learning/features/library/data/in_memory_learning_library_repository.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/player/presentation/learning_player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'player can save a playlist and note, change quality, and enter fullscreen',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = InMemoryLearningLibraryRepository();
      final notes = InMemoryNotesRepository();
      final playback = _FakePlaybackController();

      await tester.pumpWidget(
        MaterialApp(
          home: LearningPlayerScreen(
            playbackController: playback,
            libraryRepository: library,
            notesRepository: notes,
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
  final PlayerSnapshot _snapshot = const PlayerSnapshot(
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
  Future<void> selectLecture(PlaylistEntryInfo entry) async {}

  @override
  Widget buildSurface() => const ColoredBox(color: Colors.black);

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  Future<void> selectStream(MediaStreamInfo stream) async {
    selectedStream = stream;
  }

  @override
  Future<Duration> get currentPosition async => _snapshot.position;

  @override
  Future<void> dispose() async => _snapshots.close();
}
