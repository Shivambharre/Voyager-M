class RecentWatchEntry {
  const RecentWatchEntry({
    required this.videoId,
    required this.sourceUrl,
    required this.title,
    required this.creator,
    required this.durationSeconds,
    required this.watchedAt,
    this.thumbnailUrl,
  });

  final String videoId;
  final String sourceUrl;
  final String title;
  final String creator;
  final int durationSeconds;
  final String? thumbnailUrl;
  final DateTime watchedAt;
}
