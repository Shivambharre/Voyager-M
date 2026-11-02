import '../../../core/database/database.dart';
import '../domain/notes_repository.dart';
import '../domain/study_note.dart';

class SqliteNotesRepository implements NotesRepository {
  const SqliteNotesRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<StudyNote>> getNotes({
    String? videoId,
    String? topicId,
    String? libraryId,
    String? resourceId,
    NoteResourceType? resourceType,
    String? searchQuery,
  }) async {
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
    if (libraryId != null) {
      conditions.add(
        "resource_type = 'library' AND resource_id = ?",
      );
      arguments.add(libraryId);
    }
    if (resourceId != null) {
      conditions.add('resource_id = ?');
      arguments.add(resourceId);
    }
    if (resourceType != null) {
      conditions.add('resource_type = ?');
      arguments.add(resourceType.name);
    }
    final query = searchQuery?.trim();
    if (query != null && query.isNotEmpty) {
      conditions.add(
        '(title LIKE ? OR content LIKE ? OR resource_name LIKE ?)',
      );
      final pattern = '%$query%';
      arguments.addAll([pattern, pattern, pattern]);
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
      'title': note.title,
      'content': note.content,
      'content_json': note.contentJson ?? '',
      'video_id': note.videoId ??
          (note.resolvedResourceType == NoteResourceType.video
              ? note.resolvedResourceId
              : null),
      'topic_id': note.topicId ??
          (note.resolvedResourceType == NoteResourceType.lesson
              ? note.resolvedResourceId
              : null),
      'timestamp_seconds': note.timestampSeconds,
      'resource_type': note.resolvedResourceType?.name,
      'resource_id': note.resolvedResourceId,
      'resource_name': note.resourceName,
      'resource_archived': note.isResourceArchived ? 1 : 0,
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
    title: row['title'] as String? ?? 'Untitled Note',
    content: row['content']! as String,
    contentJson: row['content_json'] as String?,
    videoId: row['video_id'] as String?,
    topicId: row['topic_id'] as String?,
    libraryId: row['resource_type'] == 'library'
        ? row['resource_id'] as String?
        : null,
    resourceType: _resourceTypeFromName(row['resource_type'] as String?),
    resourceId: row['resource_id'] as String?,
    resourceName: row['resource_name'] as String?,
    isResourceArchived: row['resource_archived'] == 1,
    timestampSeconds: row['timestamp_seconds'] as int?,
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  NoteResourceType? _resourceTypeFromName(String? value) {
    for (final type in NoteResourceType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}
