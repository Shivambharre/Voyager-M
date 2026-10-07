import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/di/service_locator.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/library/domain/learning_library_repository.dart';
import 'package:voyager_learning/features/notes/domain/notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/roadmap/data/in_memory_roadmap_repository.dart';
import 'package:voyager_learning/features/roadmap/domain/roadmap.dart';
import 'package:voyager_learning/main.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    await configureDependencies(useMocks: true);
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('Home opens the player without a preloaded demo lesson', (
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
    expect(find.text('NOTHING IN PROGRESS'), findsOneWidget);
    await tester.tap(find.text('OPEN PLAYER').first);
    await tester.pumpAndSettle();

    expect(find.text('YOUTUBE PLAYER'), findsOneWidget);
    expect(find.text('LOAD VIDEO'), findsOneWidget);
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
    expect(find.text('Demo learning path'), findsOneWidget);

    await tester.tap(find.byTooltip('Open design system showcase'));
    await tester.pumpAndSettle();
    expect(find.text('NEO-BRUTALIST V1.0'), findsOneWidget);
    expect(find.text('COLOR PALETTE'), findsOneWidget);
  });

  testWidgets('saved playlists and notes appear in Home, Library, and Notes', (
    tester,
  ) async {
    final library = serviceLocator<LearningLibraryRepository>();
    final notes = serviceLocator<NotesRepository>();
    await library.savePlaylist(
      const LearningPlaylist(
        id: 'saved-course',
        sourceId: 'saved-course',
        sourceUrl: 'https://www.youtube.com/playlist?list=PL1234567890ABC',
        title: 'Saved course',
        creator: 'Study author',
      ),
    );
    final now = DateTime.utc(2026, 10, 5);
    await notes.saveNote(
      StudyNote(
        id: 'saved-note',
        content: 'Persisted learning note',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved course'), findsOneWidget);
    expect(find.text('1 saved notes'), findsOneWidget);

    await tester.tap(find.text('LIBRARY').last);
    await tester.pumpAndSettle();
    expect(find.text('Saved course'), findsOneWidget);

    await tester.tap(find.text('NOTES').last);
    await tester.pumpAndSettle();
    expect(find.text('Persisted learning note'), findsOneWidget);
  });

  testWidgets('Roadmaps can be created, edited through topics, and deleted', (
    tester,
  ) async {
    await tester.pumpWidget(
      VoyagerApp(repository: InMemoryRoadmapRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ROADMAPS').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CREATE ROADMAP').first);
    await tester.pumpAndSettle();

    final roadmapFields = find.byType(TextField);
    await tester.enterText(roadmapFields.at(0), 'Research path');
    await tester.enterText(roadmapFields.at(1), 'A test roadmap');
    await tester.tap(find.text('CREATE').last);
    await tester.pumpAndSettle();
    expect(find.text('Research path'), findsOneWidget);

    await tester.tap(find.text('Research path'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit roadmap'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Edited path');
    await tester.tap(find.text('SAVE').last);
    await tester.pumpAndSettle();
    expect(find.text('Edited path'), findsOneWidget);

    await tester.tap(find.byTooltip('Add topic'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'First topic');
    await tester.tap(find.text('ADD TOPIC').last);
    await tester.pumpAndSettle();
    expect(find.text('First topic'), findsOneWidget);

    final statusDropdown = tester.widget<DropdownButton<TopicStatus>>(
      find.byType(DropdownButton<TopicStatus>),
    );
    statusDropdown.onChanged!(TopicStatus.completed);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 topics complete'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.text('Edited path'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete roadmap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE').last);
    await tester.pumpAndSettle();
    expect(find.text('Demo learning path'), findsOneWidget);
    expect(find.text('Edited path'), findsNothing);

    await tester.tap(find.text('Demo learning path'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete roadmap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE').last);
    await tester.pumpAndSettle();
    expect(find.text('NO ROADMAPS YET'), findsOneWidget);
  });
}
