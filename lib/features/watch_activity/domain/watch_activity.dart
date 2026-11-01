class WatchActivity {
  const WatchActivity({
    required this.dateKey,
    required this.watchedSeconds,
    required this.isQualified,
    required this.updatedAtUtc,
  });

  final String dateKey;
  final int watchedSeconds;
  final bool isQualified;
  final DateTime updatedAtUtc;

  static const int dailyTargetSeconds = 15 * 60;

  static String dateKeyFor(DateTime localDate) =>
      '${localDate.year.toString().padLeft(4, '0')}-'
      '${localDate.month.toString().padLeft(2, '0')}-'
      '${localDate.day.toString().padLeft(2, '0')}';

  static int heatmapLevelFor(int watchedSeconds) {
    if (watchedSeconds < 60) return 0;
    if (watchedSeconds < 5 * 60) return 1;
    if (watchedSeconds < 15 * 60) return 2;
    if (watchedSeconds < 30 * 60) return 3;
    if (watchedSeconds < 60 * 60) return 4;
    return 5;
  }
}
