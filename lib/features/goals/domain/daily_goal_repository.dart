import 'daily_goal_summary.dart';

abstract interface class DailyGoalRepository {
  Future<DailyGoalSummary> getSummary(DateTime date);

  Future<void> addPlaybackTime({
    required DateTime date,
    required String videoId,
    required int seconds,
  });

  Future<void> markLessonCompleted({
    required DateTime date,
    required String videoId,
  });
}
