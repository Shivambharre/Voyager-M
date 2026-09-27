import '../domain/notes_repository.dart';
import '../domain/study_note.dart';

class InMemoryNotesRepository implements NotesRepository {
  final Map<String, StudyNote> _notes = {};

  @override
  Future<List<StudyNote>> getNotes({String? videoId, String? topicId}) async {
    final notes = _notes.values.where((note) {
      return (videoId == null || note.videoId == videoId) &&
          (topicId == null || note.topicId == topicId);
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
