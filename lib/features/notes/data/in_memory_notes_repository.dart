import '../domain/notes_repository.dart';
import '../domain/study_note.dart';

class InMemoryNotesRepository implements NotesRepository {
  final Map<String, StudyNote> _notes = {};

  @override
  Future<List<StudyNote>> getNotes({
    String? videoId,
    String? topicId,
    String? libraryId,
    String? resourceId,
    NoteResourceType? resourceType,
    String? searchQuery,
  }) async {
    final normalizedQuery = searchQuery?.trim().toLowerCase();
    final notes = _notes.values.where((note) {
      final matchesResource =
          (videoId == null || note.videoId == videoId) &&
          (topicId == null || note.topicId == topicId) &&
          (libraryId == null || note.libraryId == libraryId) &&
          (resourceId == null || note.resolvedResourceId == resourceId) &&
          (resourceType == null ||
              note.resolvedResourceType == resourceType);
      final matchesQuery = normalizedQuery == null ||
          normalizedQuery.isEmpty ||
          note.title.toLowerCase().contains(normalizedQuery) ||
          note.content.toLowerCase().contains(normalizedQuery);
      return matchesResource && matchesQuery;
    }).toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return List.unmodifiable(notes);
  }

  @override
  Future<void> saveNote(StudyNote note) async {
    _notes[note.id] = note;
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.remove(id);
  }
}
