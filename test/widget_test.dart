import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/di/service_locator.dart';
import 'package:voyager_learning/features/history/domain/recent_watch_entry.dart';
import 'package:voyager_learning/features/history/domain/recent_watch_history_repository.dart';
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

  testWidgets('Home displays the study overview', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('A LITTLE PROGRESS\nGOES A LONG WAY.'), findsOneWidget);
  });

  testWidgets('Primary navigation opens roadmaps and design showcase', (
    tester,
  ) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ROADMAPS').last);
    await tester.pumpAndSettle();
    expect(find.text('ONE STEP AT A TIME.'), findsOneWidget);

    await tester.tap(find.byTooltip('Open design system showcase'));
    await tester.pumpAndSettle();
    expect(find.text('NEO-BRUTALIST V1.0'), findsOneWidget);
    expect(find.text('COLOR PALETTE'), findsOneWidget);
  });

  testWidgets('Home opens recently watched videos', (tester) async {
    final history = serviceLocator<RecentWatchHistoryRepository>();
    await history.record(
      RecentWatchEntry(
        videoId: 'watched-video',
        sourceUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        title: 'Recently watched lesson',
        creator: 'Voyager',
        durationSeconds: 240,
        watchedAt: DateTime.utc(2026, 10, 30),
      ),
    );
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-watch-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('WATCH HISTORY'), findsOneWidget);
    expect(find.text('Recently watched lesson'), findsOneWidget);
  });
}
