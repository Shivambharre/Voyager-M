import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';

void main() {
  test(
    'persists note edits and restores them in a new repository instance',
    () async {
      var storedNotes = <StudyNote>[];
      final firstSession = InMemoryNotesRepository(
        loadNotes: () async => List.of(storedNotes),
        persistNotes: (notes) async => storedNotes = List.of(notes),
      );
      final now = DateTime.utc(2026, 11, 2);
      final note = StudyNote(
        id: 'web-note',
        title: 'Local note',
        content: 'Keep this offline.',
        contentJson: '[{"insert":"Keep this offline.\\n"}]',
        createdAt: now,
        updatedAt: now,
        resourceType: NoteResourceType.library,
        resourceId: 'library-1',
        resourceName: 'Study library',
        timestampSeconds: 30,
      );

      await firstSession.saveNote(note);

      final reopenedSession = InMemoryNotesRepository(
        loadNotes: () async => List.of(storedNotes),
        persistNotes: (notes) async => storedNotes = List.of(notes),
      );
      final restored = (await reopenedSession.getNotes()).single;
      expect(restored.title, note.title);
      expect(restored.contentJson, note.contentJson);
      expect(restored.resourceType, NoteResourceType.library);
      expect(restored.resourceId, 'library-1');
      expect(restored.timestampSeconds, 30);

      await reopenedSession.deleteNote(note.id);
      expect(storedNotes, isEmpty);
    },
  );

  test('rolls back an in-memory edit when local persistence fails', () async {
    final repository = InMemoryNotesRepository(
      persistNotes: (_) async => throw StateError('Storage unavailable'),
    );
    final note = StudyNote(
      id: 'failed-note',
      title: 'Unsaved',
      content: 'Keep the last saved value.',
      createdAt: DateTime.utc(2026, 11, 2),
      updatedAt: DateTime.utc(2026, 11, 2),
    );

    await expectLater(repository.saveNote(note), throwsStateError);
    expect(await repository.getNotes(), isEmpty);
  });
}
