import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/watch_activity/domain/watch_activity.dart';
import 'package:voyager_learning/features/watch_activity/domain/watch_streak_calculator.dart';

void main() {
  const calculator = WatchStreakCalculator();
  final updatedAt = DateTime.utc(2026, 10, 31);

  WatchActivity activity(String date, int seconds) => WatchActivity(
    dateKey: date,
    watchedSeconds: seconds,
    isQualified: seconds >= WatchActivity.dailyTargetSeconds,
    updatedAtUtc: updatedAt,
  );

  test('14 minutes is not qualified and 15 minutes is qualified', () {
    final summary = calculator.calculate([
      activity('2026-10-30', 14 * 60),
      activity('2026-10-31', 15 * 60),
    ], nowLocal: DateTime(2026, 10, 31, 23, 59));

    expect(summary.currentStreak, 1);
    expect(summary.bestStreak, 1);
    expect(summary.totalWatchedSeconds, 29 * 60);
  });

  test(
    'an unqualified finished day breaks the streak and today is pending',
    () {
      final summary = calculator.calculate([
        activity('2026-10-28', 900),
        activity('2026-10-29', 899),
        activity('2026-10-30', 900),
      ], nowLocal: DateTime(2026, 10, 30, 12));

      expect(summary.currentStreak, 1);
      expect(summary.bestStreak, 1);
    },
  );

  test(
    'an unqualified current day does not break yesterday’s streak early',
    () {
      final summary = calculator.calculate([
        activity('2026-10-28', 900),
        activity('2026-10-29', 900),
      ], nowLocal: DateTime(2026, 10, 30, 8));

      expect(summary.currentStreak, 2);
    },
  );

  test(
    'best streak is retained after a miss and a new streak begins at one',
    () {
      final summary = calculator.calculate([
        activity('2026-10-20', 900),
        activity('2026-10-21', 900),
        activity('2026-10-22', 900),
        activity('2026-10-23', 200),
        activity('2026-10-24', 900),
      ], nowLocal: DateTime(2026, 10, 24, 23));

      expect(summary.currentStreak, 1);
      expect(summary.bestStreak, 3);
      expect(summary.totalWatchedSeconds, 3800);
      expect(summary.earnedMilestones, [3]);
    },
  );

  test('heatmap levels become darker at each required time boundary', () {
    expect(WatchActivity.heatmapLevelFor(0), 0);
    expect(WatchActivity.heatmapLevelFor(59), 0);
    expect(WatchActivity.heatmapLevelFor(60), 1);
    expect(WatchActivity.heatmapLevelFor(4 * 60 + 59), 1);
    expect(WatchActivity.heatmapLevelFor(5 * 60), 2);
    expect(WatchActivity.heatmapLevelFor(15 * 60), 3);
    expect(WatchActivity.heatmapLevelFor(30 * 60), 4);
    expect(WatchActivity.heatmapLevelFor(60 * 60), 5);
  });

  test('date keys use the local calendar date across local midnight', () {
    expect(
      WatchActivity.dateKeyFor(DateTime(2026, 10, 31, 23, 59)),
      '2026-10-31',
    );
    expect(WatchActivity.dateKeyFor(DateTime(2026, 11, 1)), '2026-11-01');
  });
}
