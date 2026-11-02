import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/di/service_locator.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/library/domain/learning_library_repository.dart';
import 'package:voyager_learning/features/progress/domain/learning_progress.dart';
import 'package:voyager_learning/features/progress/domain/progress_repository.dart';
import 'package:voyager_learning/features/roadmap/data/in_memory_roadmap_repository.dart';
import 'package:voyager_learning/main.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    await configureDependencies(useMocks: true);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('creates a library, opens its details, and returns to Library', (
    tester,
  ) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIBRARY').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-playlist-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('playlist-name-field')),
      'Musk',
    );
    await tester.enterText(
      find.byKey(const Key('playlist-description-field')),
      'Renaissance studies',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Musk'), findsOneWidget);
    expect(find.text('Renaissance studies'), findsOneWidget);
    await tester.tap(find.text('Musk'));
    await tester.pumpAndSettle();
    expect(find.text('0 videos · 0 completed'), findsOneWidget);
    expect(find.text('No videos yet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your study library'), findsOneWidget);
    expect(find.text('Musk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows saved progress and persists playlist reordering', (
    tester,
  ) async {
    final library = serviceLocator<LearningLibraryRepository>();
    final progress = serviceLocator<ProgressRepository>();
    const playlist = LearningPlaylist(
      id: 'musk-library',
      sourceId: 'musk-library',
      sourceUrl: '',
      title: 'Musk',
      creator: 'You',
      description: 'Renaissance studies',
    );
    const firstVideo = LearningVideo(
      id: 'first-video',
      sourceId: 'first-source',
      sourceUrl: 'https://example.test/first',
      title: 'First lesson',
      creator: 'Teacher',
      durationSeconds: 480,
    );
    const secondVideo = LearningVideo(
      id: 'second-video',
      sourceId: 'second-source',
      sourceUrl: 'https://example.test/second',
      title: 'Second lesson',
      creator: 'Teacher',
      durationSeconds: 180,
    );
    await library.saveVideoMetadata(firstVideo);
    await library.saveVideoMetadata(secondVideo);
    await library.savePlaylist(playlist);
    await library.savePlaylistEntries(playlist.id, [
      PlaylistEntry(
        playlistId: playlist.id,
        videoId: firstVideo.id,
        position: 0,
      ),
      PlaylistEntry(
        playlistId: playlist.id,
        videoId: secondVideo.id,
        position: 1,
      ),
    ]);
    await progress.saveProgress(
      LearningProgress(
        videoId: firstVideo.id,
        positionSeconds: 480,
        durationSeconds: 480,
        isCompleted: true,
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    await progress.saveProgress(
      LearningProgress(
        videoId: secondVideo.id,
        positionSeconds: 45,
        durationSeconds: 180,
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIBRARY').last);
    await tester.pumpAndSettle();
    expect(find.text('2 videos · 1 completed'), findsOneWidget);
    await tester.tap(find.text('Musk'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('completed-video-first-video')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('video-progress-second-video')),
      findsOneWidget,
    );
    expect(find.text('0:45 / 3:00'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('video-progress-second-video')),
          )
          .value,
      0.25,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('playlist-overall-progress')),
          )
          .value,
      0.5,
    );

    final dragHandle = find.byKey(
      const Key('reorder-playlist-video-first-video'),
    );
    final drag = await tester.startGesture(tester.getCenter(dragHandle));
    await tester.pump(const Duration(milliseconds: 100));
    await drag.moveBy(const Offset(0, 10));
    await tester.pump();
    await drag.moveBy(const Offset(0, 80));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(
      (await library.getPlaylistEntries(playlist.id))
          .map((entry) => entry.videoId)
          .toList(),
      ['second-video', 'first-video'],
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your study library'), findsOneWidget);
    await tester.tap(find.text('Musk'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Second lesson')).dy,
      lessThan(tester.getTopLeft(find.text('First lesson')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
