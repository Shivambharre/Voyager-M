import '../../../core/database/database.dart';
import '../domain/watch_activity.dart';
import '../domain/watch_activity_repository.dart';

class SqliteWatchActivityRepository implements WatchActivityRepository {
  const SqliteWatchActivityRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<WatchActivity>> getActivities() async {
    final rows = await _database.query('watch_activity', orderBy: 'date_key');
    return rows
        .map(
          (row) => WatchActivity(
            dateKey: row['date_key']! as String,
            watchedSeconds: row['watched_seconds']! as int,
            isQualified: row['is_qualified'] == 1,
            updatedAtUtc: DateTime.parse(row['updated_at_utc']! as String)
                .toUtc(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> addEligibleSeconds({
    required String dateKey,
    required int seconds,
    required DateTime updatedAtUtc,
  }) async {
    if (seconds <= 0) return;
    await _database.transaction((transaction) async {
      final rows = await transaction.query(
        'watch_activity',
        where: 'date_key = ?',
        whereArgs: [dateKey],
      );
      final total =
          (rows.isEmpty ? 0 : rows.first['watched_seconds']! as int) + seconds;
      final values = {
        'date_key': dateKey,
        'watched_seconds': total,
        'is_qualified': total >= WatchActivity.dailyTargetSeconds ? 1 : 0,
        'updated_at_utc': updatedAtUtc.toUtc().toIso8601String(),
      };
      if (rows.isEmpty) {
        await transaction.insert('watch_activity', values);
      } else {
        await transaction.update(
          'watch_activity',
          values,
          where: 'date_key = ?',
          whereArgs: [dateKey],
        );
      }
    });
  }
}
