import '../../../core/database/database.dart';
import '../domain/daily_goal_repository.dart';
import '../domain/daily_goal_summary.dart';

class SqliteDailyGoalRepository implements DailyGoalRepository {
  const SqliteDailyGoalRepository(this._database);

  final AppDatabase _database;

  @override
  Future<DailyGoalSummary> getSummary(DateTime date) async {
    final rows = await _database.query(
      'daily_goal_activity',
      where: 'activity_date = ?',
      whereArgs: [_dateKey(date)],
    );
    return DailyGoalSummary(
      date: DateTime(date.year, date.month, date.day),
      playedSeconds: rows.fold<int>(
        0,
        (total, row) => total + (row['played_seconds']! as int),
      ),
      completedLessons: rows.where((row) => row['completed_at'] != null).length,
    );
  }

  @override
  Future<void> addPlaybackTime({
    required DateTime date,
    required String videoId,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    await _database.transaction((transaction) async {
      final dateKey = _dateKey(date);
      final rows = await transaction.query(
        'daily_goal_activity',
        where: 'activity_date = ? AND video_id = ?',
        whereArgs: [dateKey, videoId],
      );
      if (rows.isEmpty) {
        await transaction.insert('daily_goal_activity', {
          'activity_date': dateKey,
          'video_id': videoId,
          'played_seconds': seconds,
        });
      } else {
        await transaction.update(
          'daily_goal_activity',
          {'played_seconds': (rows.first['played_seconds']! as int) + seconds},
          where: 'activity_date = ? AND video_id = ?',
          whereArgs: [dateKey, videoId],
        );
      }
    });
  }

  @override
  Future<void> markLessonCompleted({
    required DateTime date,
    required String videoId,
  }) async {
    await _database.transaction((transaction) async {
      final dateKey = _dateKey(date);
      final rows = await transaction.query(
        'daily_goal_activity',
        where: 'activity_date = ? AND video_id = ?',
        whereArgs: [dateKey, videoId],
      );
      if (rows.isEmpty) {
        await transaction.insert('daily_goal_activity', {
          'activity_date': dateKey,
          'video_id': videoId,
          'played_seconds': 0,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else if (rows.first['completed_at'] == null) {
        await transaction.update(
          'daily_goal_activity',
          {'completed_at': DateTime.now().toUtc().toIso8601String()},
          where: 'activity_date = ? AND video_id = ?',
          whereArgs: [dateKey, videoId],
        );
      }
    });
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
