import 'study_note.dart';

abstract interface class NotesRepository {
  Future<List<StudyNote>> getNotes({
    String? videoId,
    String? topicId,
    String? libraryId,
    String? resourceId,
    NoteResourceType? resourceType,
    String? searchQuery,
  });
  Future<void> saveNote(StudyNote note);
  Future<void> deleteNote(String id);
}
