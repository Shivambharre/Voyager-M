import 'watch_activity.dart';
import 'watch_calendar.dart';
import 'watch_activity_repository.dart';
import '../../../core/media/playback_state.dart';

class WatchActivityTracker {
  WatchActivityTracker({
    required this.repository,
    DateTime Function()? clock,
    WatchCalendar? calendar,
  }) : _clock = clock ?? DateTime.now,
       _calendar = calendar ?? const SystemWatchCalendar();

  static const _maximumSampleGap = Duration(seconds: 3);

  final WatchActivityRepository repository;
  final DateTime Function() _clock;
  final WatchCalendar _calendar;
  final Map<String, int> _pendingMicroseconds = {};
  DateTime? _lastSampleAt;
  Duration? _lastPosition;
  PlayerStatus? _lastStatus;
  bool _lastBuffering = false;
  double _lastPlaybackSpeed = 1;
  String? _sourceId;
  Future<void>? _flushTask;

  void observe(PlayerSnapshot snapshot, {required String? sourceId}) {
    final now = _clock();
    if (sourceId == null) {
      resetPositionBaseline();
      _sourceId = null;
      return;
    }
    if (_sourceId != sourceId) {
      resetPositionBaseline();
      _sourceId = sourceId;
    }

    final previousAt = _lastSampleAt;
    final previousPosition = _lastPosition;
    final previousStatus = _lastStatus;
    if (previousAt != null &&
        previousPosition != null &&
        previousStatus == PlayerStatus.playing &&
        !_lastBuffering &&
        !snapshot.isBuffering) {
      final elapsed = now.difference(previousAt);
      final positionDelta = snapshot.position - previousPosition;
      final wasAdvancing =
          elapsed > Duration.zero &&
          elapsed <= _maximumSampleGap &&
          positionDelta > Duration.zero &&
          positionDelta <=
              elapsed * _lastPlaybackSpeed * 1.8 +
                  const Duration(milliseconds: 500);
      final remainsActive =
          snapshot.status == PlayerStatus.playing ||
          snapshot.status == PlayerStatus.paused;
      if (wasAdvancing && remainsActive) {
        _creditInterval(previousAt, now);
      }
    }

    _lastSampleAt = now;
    _lastPosition = snapshot.position;
    _lastStatus = snapshot.status;
    _lastBuffering = snapshot.isBuffering;
    _lastPlaybackSpeed = snapshot.playbackSpeed;
  }

  void resetPositionBaseline() {
    _lastSampleAt = null;
    _lastPosition = null;
    _lastStatus = null;
    _lastBuffering = false;
  }

  void _creditInterval(DateTime start, DateTime end) {
    var cursor = start;
    while (cursor.isBefore(end)) {
      final nextMidnight = _calendar.nextMidnightAfter(cursor);
      final segmentEnd = end.isBefore(nextMidnight) ? end : nextMidnight;
      final micros = segmentEnd.difference(cursor).inMicroseconds;
      if (micros > 0) {
        final key = WatchActivity.dateKeyFor(_calendar.localDateTime(cursor));
        _pendingMicroseconds.update(
          key,
          (existing) => existing + micros,
          ifAbsent: () => micros,
        );
      }
      cursor = segmentEnd;
    }
  }

  Future<void> flush() {
    final activeFlush = _flushTask;
    if (activeFlush != null) return activeFlush;
    final pending = <String, int>{
      for (final entry in _pendingMicroseconds.entries)
        if (entry.value >= Duration.microsecondsPerSecond)
          entry.key: entry.value ~/ Duration.microsecondsPerSecond,
    };
    if (pending.isEmpty) return Future<void>.value();

    late final Future<void> task;
    task = _persistPending(pending).whenComplete(() {
      if (identical(_flushTask, task)) _flushTask = null;
    });
    _flushTask = task;
    return task;
  }

  Future<void> _persistPending(Map<String, int> pending) async {
    for (final entry in pending.entries) {
      await repository.addEligibleSeconds(
        dateKey: entry.key,
        seconds: entry.value,
        updatedAtUtc: _clock().toUtc(),
      );
      final persistedMicros = entry.value * Duration.microsecondsPerSecond;
      final remaining =
          (_pendingMicroseconds[entry.key] ?? 0) - persistedMicros;
      if (remaining > 0) {
        _pendingMicroseconds[entry.key] = remaining;
      } else {
        _pendingMicroseconds.remove(entry.key);
      }
    }
  }
}
