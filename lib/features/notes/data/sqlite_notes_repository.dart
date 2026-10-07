import '../../../core/database/database.dart';
import '../domain/notes_repository.dart';
import '../domain/study_note.dart';

class SqliteNotesRepository implements NotesRepository {
  const SqliteNotesRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<StudyNote>> getNotes({String? videoId, String? topicId}) async {
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (videoId != null) {
      conditions.add('video_id = ?');
      arguments.add(videoId);
    }
    if (topicId != null) {
      conditions.add('topic_id = ?');
      arguments.add(topicId);
    }
    final rows = await _database.query(
      'notes',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_noteFromRow).toList(growable: false);
  }

  @override
  Future<void> saveNote(StudyNote note) async {
    await _database.upsert('notes', {
      'id': note.id,
      'content': note.content,
      'video_id': note.videoId,
      'topic_id': note.topicId,
      'timestamp_seconds': note.timestampSeconds,
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    }, keyWhere: 'id = ?', keyArgs: [note.id]);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _database.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  StudyNote _noteFromRow(Map<String, Object?> row) => StudyNote(
        id: row['id']! as String,
        content: row['content']! as String,
        videoId: row['video_id'] as String?,
        topicId: row['topic_id'] as String?,
        timestampSeconds: row['timestamp_seconds'] as int?,
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );
}
