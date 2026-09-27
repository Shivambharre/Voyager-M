import 'study_note.dart';

abstract interface class NotesRepository {
  Future<List<StudyNote>> getNotes({String? videoId, String? topicId});
  Future<void> saveNote(StudyNote note);
  Future<void> deleteNote(String id);
}
