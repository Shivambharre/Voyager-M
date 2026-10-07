import '../../../core/database/database.dart';
import '../domain/learning_progress.dart';
import '../domain/progress_repository.dart';

class SqliteProgressRepository implements ProgressRepository {
  const SqliteProgressRepository(this._database);

  final AppDatabase _database;

  @override
  Future<LearningProgress?> getProgress(String videoId) async {
    final rows = await _database.query(
      'progress',
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
    return rows.isEmpty ? null : _progressFromRow(rows.first);
  }

  @override
  Future<void> saveProgress(LearningProgress progress) async {
    await _database.upsert('progress', {
      'video_id': progress.videoId,
      'position_seconds': progress.positionSeconds,
      'duration_seconds': progress.durationSeconds,
      'is_completed': progress.isCompleted ? 1 : 0,
      'updated_at': progress.updatedAt.toUtc().toIso8601String(),
    }, keyWhere: 'video_id = ?', keyArgs: [progress.videoId]);
  }

  @override
  Future<List<LearningBookmark>> getBookmarks(String videoId) async {
    final rows = await _database.query(
      'bookmarks',
      where: 'video_id = ?',
      whereArgs: [videoId],
      orderBy: 'position_seconds',
    );
    return rows.map(_bookmarkFromRow).toList(growable: false);
  }

  @override
  Future<void> saveBookmark(LearningBookmark bookmark) async {
    await _database.upsert('bookmarks', {
      'id': bookmark.id,
      'video_id': bookmark.videoId,
      'position_seconds': bookmark.positionSeconds,
      'label': bookmark.label,
      'created_at': bookmark.createdAt.toUtc().toIso8601String(),
    }, keyWhere: 'id = ?', keyArgs: [bookmark.id]);
  }

  @override
  Future<void> deleteBookmark(String id) async {
    await _database.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  LearningProgress _progressFromRow(Map<String, Object?> row) =>
      LearningProgress(
        videoId: row['video_id']! as String,
        positionSeconds: row['position_seconds']! as int,
        durationSeconds: row['duration_seconds']! as int,
        isCompleted: row['is_completed'] == 1,
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );

  LearningBookmark _bookmarkFromRow(Map<String, Object?> row) =>
      LearningBookmark(
        id: row['id']! as String,
        videoId: row['video_id']! as String,
        positionSeconds: row['position_seconds']! as int,
        label: row['label']! as String,
        createdAt: DateTime.parse(row['created_at']! as String),
      );
}
