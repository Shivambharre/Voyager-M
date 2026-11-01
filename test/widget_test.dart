import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/di/service_locator.dart';
import 'package:voyager_learning/core/share/shared_video_intent_source.dart';
import 'package:voyager_learning/features/history/domain/recent_watch_entry.dart';
import 'package:voyager_learning/features/history/domain/recent_watch_history_repository.dart';
import 'package:voyager_learning/features/roadmap/data/in_memory_roadmap_repository.dart';
import 'package:voyager_learning/features/settings/domain/learning_settings.dart';
import 'package:voyager_learning/features/settings/domain/settings_repository.dart';
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
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'VoyagerM',
    );
    expect(find.text('A LITTLE PROGRESS\nGOES A LONG WAY.'), findsOneWidget);
    expect(find.byKey(const Key('begin-learning-button')), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -450));
    await tester.pumpAndSettle();
    final actions = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(GridView).first,
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList();
    expect(actions, ['Resume', 'Daily Goals', 'Progress', 'Bookmarks']);
    expect(tester.takeException(), isNull);
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
    expect(find.text('THE CLASSICAL ARCHIVE'), findsOneWidget);
    expect(find.text('Color palette'), findsOneWidget);
  });

  testWidgets(
    'profile follows appearance in the header and edits local identity',
    (tester) async {
      await tester.pumpWidget(
        VoyagerApp(repository: InMemoryRoadmapRepository()),
      );
      await tester.pumpAndSettle();

      final appearance = find.byTooltip('Use dark appearance');
      final profileButton = find.byKey(const Key('open-profile-button'));
      expect(
        tester.getCenter(profileButton).dx,
        greaterThan(tester.getCenter(appearance).dx),
      );
      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      expect(find.text('WATCH ACTIVITY'), findsOneWidget);
      expect(find.text('CURRENT STREAK'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Ada Lovelace');
      await tester.enterText(find.byType(TextField).at(1), 'ada');
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('@ada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Primary navigation retains Library, Notes, and Settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('LIBRARY').last);
    await tester.pumpAndSettle();
    expect(find.text('Your study library'), findsOneWidget);

    await tester.tap(find.text('NOTES').last);
    await tester.pumpAndSettle();
    expect(find.text('Study notes'), findsOneWidget);

    await tester.tap(find.text('SETTINGS').last);
    await tester.pumpAndSettle();
    expect(find.text('A PLACE OF YOUR OWN'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    final historyButton = find.byKey(const Key('open-watch-history-button'));
    await tester.ensureVisible(historyButton);
    await tester.pumpAndSettle();
    await tester.tap(historyButton);
    await tester.pumpAndSettle();

    expect(find.text('WATCH HISTORY'), findsOneWidget);
    expect(find.text('Recently watched lesson'), findsOneWidget);
  });

  testWidgets('Begin Learning opens the existing focused study route', (
    tester,
  ) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('begin-learning-button')));
    await tester.pumpAndSettle();

    expect(find.text('FOCUSED STUDY'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('settings changes persist and update the app appearance', (
    tester,
  ) async {
    final settingsRepository = serviceLocator<SettingsRepository>();
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('SETTINGS').last);
    await tester.pumpAndSettle();

    final resumeSwitch = find.byKey(const Key('settings-resume-playback'));
    await tester.ensureVisible(resumeSwitch);
    await tester.tap(resumeSwitch);
    await tester.pumpAndSettle();
    expect((await settingsRepository.getSettings()).resumePlayback, isFalse);

    await tester.tap(find.byTooltip('Use dark appearance'));
    await tester.pumpAndSettle();
    expect(
      (await settingsRepository.getSettings()).appearance,
      AppearanceMode.dark,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('daily goals action opens the configured goal summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    final dailyGoalsAction = find.text('Daily Goals');
    await tester.scrollUntilVisible(
      dailyGoalsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(dailyGoalsAction);
    await tester.pumpAndSettle();

    expect(find.text('DAILY GOALS'), findsOneWidget);
    expect(find.text('0 of 30 minutes'), findsOneWidget);
  });

  testWidgets('reports when shared text does not contain a YouTube link', (
    tester,
  ) async {
    final sharedVideos = _FakeSharedVideoIntentSource();
    addTearDown(sharedVideos.close);
    await tester.pumpWidget(
      VoyagerApp(
        repository: InMemoryRoadmapRepository(),
        sharedVideoIntentSource: sharedVideos,
      ),
    );
    await tester.pumpAndSettle();

    sharedVideos.add('This is not a YouTube link.');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Share a YouTube video or playlist link.'),
      findsOneWidget,
    );
  });
}

class _FakeSharedVideoIntentSource implements SharedVideoIntentSource {
  final _sharedTexts = StreamController<String>.broadcast();

  @override
  Stream<String> get sharedTexts => _sharedTexts.stream;

  void add(String text) => _sharedTexts.add(text);

  Future<void> close() => _sharedTexts.close();
}
