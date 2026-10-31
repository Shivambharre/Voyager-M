class DailyGoalSummary {
  const DailyGoalSummary({
    required this.date,
    required this.playedSeconds,
    required this.completedLessons,
  });

  final DateTime date;
  final int playedSeconds;
  final int completedLessons;
}
