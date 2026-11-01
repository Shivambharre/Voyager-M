import 'watch_activity.dart';

abstract interface class WatchActivityRepository {
  Future<List<WatchActivity>> getActivities();

  Future<void> addEligibleSeconds({
    required String dateKey,
    required int seconds,
    required DateTime updatedAtUtc,
  });
}
