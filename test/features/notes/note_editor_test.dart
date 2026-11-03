import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/notes/presentation/note_editor_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates a note and auto-saves title changes', (tester) async {
    final repository = InMemoryNotesRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: NoteEditorPage(
          repository: repository,
          resourceType: NoteResourceType.video,
          resourceId: 'video-1',
          resourceName: 'Lesson one',
          timestampSeconds: 48,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attach playback timestamp'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Key idea',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    final saved = (await repository.getNotes()).single;
    expect(saved.title, 'Key idea');
    expect(saved.contentJson, contains('"insert"'));
    expect(saved.timestampSeconds, 48);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets(
    'opening a note does not edit its timestamp and delete confirms',
    (tester) async {
      final repository = InMemoryNotesRepository();
      final updatedAt = DateTime.utc(2025, 1, 1);
      final note = StudyNote(
        id: 'existing-note',
        title: 'Saved title',
        content: 'Saved body',
        createdAt: updatedAt,
        updatedAt: updatedAt,
        videoId: 'video-1',
        resourceType: NoteResourceType.video,
        resourceId: 'video-1',
        resourceName: 'Lesson one',
      );
      await repository.saveNote(note);

      await tester.pumpWidget(
        MaterialApp(
          home: NoteEditorPage(
            repository: repository,
            note: note,
            resourceType: NoteResourceType.video,
            resourceId: 'video-1',
            resourceName: 'Lesson one',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect((await repository.getNotes()).single.updatedAt, updatedAt);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      expect(find.text('This permanently deletes the note.'), findsOneWidget);
      expect(await repository.getNotes(), hasLength(1));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await repository.getNotes(), isEmpty);
    },
  );
}
