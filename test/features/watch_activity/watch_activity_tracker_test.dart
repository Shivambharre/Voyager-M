import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/playback_state.dart';
import 'package:voyager_learning/features/watch_activity/data/in_memory_watch_activity_repository.dart';
import 'package:voyager_learning/features/watch_activity/domain/watch_activity_tracker.dart';
import 'package:voyager_learning/features/watch_activity/domain/watch_calendar.dart';

void main() {
  late DateTime now;
  late InMemoryWatchActivityRepository repository;
  late WatchActivityTracker tracker;

  PlayerSnapshot snapshot(
    PlayerStatus status,
    Duration position, {
    bool buffering = false,
  }) => PlayerSnapshot(
    status: status,
    position: position,
    duration: const Duration(minutes: 20),
    playbackSpeed: 1,
    isBuffering: buffering,
  );

  setUp(() {
    now = DateTime(2026, 10, 31, 10);
    repository = InMemoryWatchActivityRepository();
    tracker = WatchActivityTracker(repository: repository, clock: () => now);
  });

  test('counts only time confirmed by advancing playback position', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    final records = await repository.getActivities();
    expect(records.single.watchedSeconds, 2);
  });

  test('does not count paused time', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.paused, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.paused, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    expect((await repository.getActivities()).single.watchedSeconds, 2);
  });

  test('does not count intervals marked as buffering', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(
        PlayerStatus.playing,
        const Duration(seconds: 2),
        buffering: true,
      ),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 4)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 6)),
      sourceId: 'v1',
    );
    await tracker.flush();

    expect((await repository.getActivities()).single.watchedSeconds, 2);
  });

  test('ignores a seek jump and resumes tracking on the next sample', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(minutes: 5)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(minutes: 5, seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    expect((await repository.getActivities()).single.watchedSeconds, 2);
  });

  test('source changes preserve accumulated daily watch time', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 1));
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v2',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v2',
    );
    await tracker.flush();

    expect((await repository.getActivities()).single.watchedSeconds, 4);
  });

  test('splits eligible playback across the local midnight boundary', () async {
    now = DateTime(2026, 10, 31, 23, 59, 59);
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    final records = await repository.getActivities();
    expect(
      {for (final record in records) record.dateKey: record.watchedSeconds},
      {'2026-10-31': 1, '2026-11-01': 1},
    );
  });

  test('uses the injected timezone when assigning a local date', () async {
    now = DateTime.utc(2026, 10, 31, 22, 59, 59);
    tracker = WatchActivityTracker(
      repository: repository,
      clock: () => now,
      calendar: const _FixedOffsetWatchCalendar(Duration(hours: 2)),
    );
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    final records = await repository.getActivities();
    expect(records.single.dateKey, '2026-11-01');
    expect(records.single.watchedSeconds, 2);
  });

  test('explicit seek reset discards the transition interval', () async {
    tracker.observe(
      snapshot(PlayerStatus.playing, Duration.zero),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 3));
    tracker.resetPositionBaseline();
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(minutes: 4)),
      sourceId: 'v1',
    );
    now = now.add(const Duration(seconds: 2));
    tracker.observe(
      snapshot(PlayerStatus.playing, const Duration(minutes: 4, seconds: 2)),
      sourceId: 'v1',
    );
    await tracker.flush();

    expect((await repository.getActivities()).single.watchedSeconds, 2);
  });
}

class _FixedOffsetWatchCalendar implements WatchCalendar {
  const _FixedOffsetWatchCalendar(this.offset);

  final Duration offset;

  @override
  DateTime localDateTime(DateTime instant) => instant.toUtc().add(offset);

  @override
  DateTime nextMidnightAfter(DateTime instant) {
    final local = localDateTime(instant);
    return DateTime.utc(
      local.year,
      local.month,
      local.day + 1,
    ).subtract(offset);
  }
}
