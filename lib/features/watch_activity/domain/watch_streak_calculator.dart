import 'watch_activity.dart';

class WatchStreakSummary {
  const WatchStreakSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalWatchedSeconds,
    required this.earnedMilestones,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalWatchedSeconds;
  final List<int> earnedMilestones;

  static const milestones = [3, 7, 14, 30, 60, 100, 365];
}

class WatchStreakCalculator {
  const WatchStreakCalculator();

  WatchStreakSummary calculate(
    Iterable<WatchActivity> activities, {
    required DateTime nowLocal,
  }) {
    final byDate = <String, WatchActivity>{
      for (final activity in activities) activity.dateKey: activity,
    };
    bool qualifies(String key) =>
        byDate[key]?.isQualified == true &&
        byDate[key]!.watchedSeconds >= WatchActivity.dailyTargetSeconds;

    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final yesterday = today.subtract(const Duration(days: 1));
    var currentStreak = 0;
    var cursor = qualifies(WatchActivity.dateKeyFor(today)) ? today : yesterday;
    while (qualifies(WatchActivity.dateKeyFor(cursor))) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final sortedDates = byDate.keys.toList()..sort();
    var bestStreak = 0;
    var runningStreak = 0;
    DateTime? previousDate;
    for (final key in sortedDates) {
      final date = _parseDateKey(key);
      if (!qualifies(key)) {
        runningStreak = 0;
        previousDate = date;
        continue;
      }
      if (previousDate != null && date.difference(previousDate).inDays == 1) {
        runningStreak++;
      } else {
        runningStreak = 1;
      }
      if (runningStreak > bestStreak) bestStreak = runningStreak;
      previousDate = date;
    }

    final totalWatchedSeconds = byDate.values.fold<int>(
      0,
      (total, activity) => total + activity.watchedSeconds,
    );
    return WatchStreakSummary(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalWatchedSeconds: totalWatchedSeconds,
      earnedMilestones: WatchStreakSummary.milestones
          .where((milestone) => bestStreak >= milestone)
          .toList(growable: false),
    );
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
