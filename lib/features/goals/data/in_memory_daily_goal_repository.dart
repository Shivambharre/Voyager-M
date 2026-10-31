import '../domain/daily_goal_repository.dart';
import '../domain/daily_goal_summary.dart';

class InMemoryDailyGoalRepository implements DailyGoalRepository {
  final Map<(String, String), _DailyGoalEntry> _entries = {};

  @override
  Future<DailyGoalSummary> getSummary(DateTime date) async {
    final key = _dateKey(date);
    final entries = _entries.entries
        .where((entry) => entry.key.$1 == key)
        .map((entry) => entry.value);
    var playedSeconds = 0;
    var completedLessons = 0;
    for (final entry in entries) {
      playedSeconds += entry.playedSeconds;
      if (entry.completedAt != null) completedLessons++;
    }
    return DailyGoalSummary(
      date: DateTime(date.year, date.month, date.day),
      playedSeconds: playedSeconds,
      completedLessons: completedLessons,
    );
  }

  @override
  Future<void> addPlaybackTime({
    required DateTime date,
    required String videoId,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    final key = (_dateKey(date), videoId);
    final previous = _entries[key];
    _entries[key] = _DailyGoalEntry(
      playedSeconds: (previous?.playedSeconds ?? 0) + seconds,
      completedAt: previous?.completedAt,
    );
  }

  @override
  Future<void> markLessonCompleted({
    required DateTime date,
    required String videoId,
  }) async {
    final key = (_dateKey(date), videoId);
    final previous = _entries[key];
    _entries[key] = _DailyGoalEntry(
      playedSeconds: previous?.playedSeconds ?? 0,
      completedAt: previous?.completedAt ?? DateTime.now(),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _DailyGoalEntry {
  const _DailyGoalEntry({required this.playedSeconds, this.completedAt});

  final int playedSeconds;
  final DateTime? completedAt;
}
