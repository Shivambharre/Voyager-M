import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/library/data/in_memory_learning_library_repository.dart';
import 'package:voyager_learning/features/library/domain/learning_content.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';
import 'package:voyager_learning/features/notes/presentation/notes_home_page.dart';
import 'package:voyager_learning/features/roadmap/data/in_memory_roadmap_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the two note categories and searches note bodies', (
    tester,
  ) async {
    final notes = InMemoryNotesRepository();
    final library = InMemoryLearningLibraryRepository();
    final roadmaps = InMemoryRoadmapRepository();
    const video = LearningVideo(
      id: 'video-1',
      sourceId: 'source-1',
      sourceUrl: 'https://example.test/video',
      title: 'Algorithms',
      creator: 'Teacher',
      durationSeconds: 90,
    );
    const playlist = LearningPlaylist(
      id: 'playlist-1',
      sourceId: 'playlist-1',
      sourceUrl: 'https://example.test/library',
      title: 'Study library',
      creator: 'Teacher',
    );
    await library.saveVideo(video);
    await library.savePlaylist(playlist);
    final now = DateTime.utc(2026, 11, 2);
    await notes.saveNote(
      StudyNote(
        id: 'video-note',
        title: 'Untitled Note',
        content: 'Remember binary search',
        videoId: video.id,
        resourceType: NoteResourceType.video,
        resourceId: video.id,
        resourceName: video.title,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await notes.saveNote(
      StudyNote(
        id: 'library-note',
        title: 'Reading list',
        content: 'Read chapter three',
        libraryId: playlist.id,
        resourceType: NoteResourceType.library,
        resourceId: playlist.id,
        resourceName: playlist.title,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotesHomePage(
            repository: notes,
            libraryRepository: library,
            roadmapRepository: roadmaps,
            onOpenPlayer: ({sourceUrl, initialPosition}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Video / Lesson Notes'), findsOneWidget);
    expect(find.text('Library Notes'), findsOneWidget);
    expect(find.text('Personal Notes'), findsNothing);
    expect(find.text('Algorithms'), findsOneWidget);
    expect(find.text('Study library'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'binary search');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Untitled Note'), findsOneWidget);
    expect(find.text('Reading list'), findsNothing);
  });
}
