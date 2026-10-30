import '../domain/recent_watch_entry.dart';
import '../domain/recent_watch_history_repository.dart';

class InMemoryRecentWatchHistoryRepository
    implements RecentWatchHistoryRepository {
  final Map<String, RecentWatchEntry> _entries = {};

  @override
  Future<List<RecentWatchEntry>> getRecent({int limit = 50}) async {
    final entries = _entries.values.toList()
      ..sort((first, second) => second.watchedAt.compareTo(first.watchedAt));
    return List.unmodifiable(entries.take(limit));
  }

  @override
  Future<void> record(RecentWatchEntry entry) async {
    _entries[entry.videoId] = entry;
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}
