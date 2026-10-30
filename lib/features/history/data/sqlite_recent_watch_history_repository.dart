import '../../../core/database/database.dart';
import '../domain/recent_watch_entry.dart';
import '../domain/recent_watch_history_repository.dart';

class SqliteRecentWatchHistoryRepository
    implements RecentWatchHistoryRepository {
  const SqliteRecentWatchHistoryRepository(this._database);

  static const _maximumEntries = 50;

  final AppDatabase _database;

  @override
  Future<List<RecentWatchEntry>> getRecent({int limit = 50}) async {
    if (limit <= 0) return const [];
    final rows = await _database.query(
      'recent_watch_history',
      orderBy: 'watched_at DESC',
    );
    return rows
        .take(limit)
        .map(
          (row) => RecentWatchEntry(
            videoId: row['video_id']! as String,
            sourceUrl: row['source_url']! as String,
            title: row['title']! as String,
            creator: row['creator']! as String,
            durationSeconds: row['duration_seconds']! as int,
            thumbnailUrl: row['thumbnail_url'] as String?,
            watchedAt: DateTime.parse(row['watched_at']! as String),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> record(RecentWatchEntry entry) async {
    await _database.upsert(
      'recent_watch_history',
      {
        'video_id': entry.videoId,
        'source_url': entry.sourceUrl,
        'title': entry.title,
        'creator': entry.creator,
        'duration_seconds': entry.durationSeconds,
        'thumbnail_url': entry.thumbnailUrl,
        'watched_at': entry.watchedAt.toUtc().toIso8601String(),
      },
      keyWhere: 'video_id = ?',
      keyArgs: [entry.videoId],
    );
    while (true) {
      final overflow = (await getRecent(limit: _maximumEntries + 1))
          .skip(_maximumEntries)
          .toList(growable: false);
      if (overflow.isEmpty) break;
      for (final oldEntry in overflow) {
        await _database.delete(
          'recent_watch_history',
          where: 'video_id = ?',
          whereArgs: [oldEntry.videoId],
        );
      }
    }
  }

  @override
  Future<void> clear() async {
    final entries = await _database.query(
      'recent_watch_history',
      columns: ['video_id'],
    );
    for (final entry in entries) {
      await _database.delete(
        'recent_watch_history',
        where: 'video_id = ?',
        whereArgs: [entry['video_id']],
      );
    }
  }
}
