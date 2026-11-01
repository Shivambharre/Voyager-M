import '../domain/watch_activity.dart';
import '../domain/watch_activity_repository.dart';

class InMemoryWatchActivityRepository implements WatchActivityRepository {
  final Map<String, WatchActivity> _activities = {};

  @override
  Future<List<WatchActivity>> getActivities() async =>
      _activities.values.toList()..sort((first, second) {
        return first.dateKey.compareTo(second.dateKey);
      });

  @override
  Future<void> addEligibleSeconds({
    required String dateKey,
    required int seconds,
    required DateTime updatedAtUtc,
  }) async {
    if (seconds <= 0) return;
    final total = (_activities[dateKey]?.watchedSeconds ?? 0) + seconds;
    _activities[dateKey] = WatchActivity(
      dateKey: dateKey,
      watchedSeconds: total,
      isQualified: total >= WatchActivity.dailyTargetSeconds,
      updatedAtUtc: updatedAtUtc.toUtc(),
    );
  }
}
