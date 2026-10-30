import 'recent_watch_entry.dart';

abstract interface class RecentWatchHistoryRepository {
  Future<List<RecentWatchEntry>> getRecent({int limit = 50});
  Future<void> record(RecentWatchEntry entry);
  Future<void> clear();
}
