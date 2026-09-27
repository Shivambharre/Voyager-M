import 'dart:async';

import 'media_provider.dart';

enum PlayerStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  unavailable,
  error,
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.status,
    required this.position,
    required this.duration,
    required this.playbackSpeed,
    this.errorMessage,
  });

  const PlayerSnapshot.initial()
      : status = PlayerStatus.idle,
        position = Duration.zero,
        duration = Duration.zero,
        playbackSpeed = 1,
        errorMessage = null;

  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final String? errorMessage;
}

abstract interface class PlayerEngine {
  PlayerSnapshot get snapshot;
  Stream<PlayerSnapshot> get snapshots;

  Future<void> load(MediaAsset asset);
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> dispose();
}

class MockPlayerEngine implements PlayerEngine {
  final StreamController<PlayerSnapshot> _controller =
      StreamController<PlayerSnapshot>.broadcast();
  PlayerSnapshot _snapshot = const PlayerSnapshot.initial();

  @override
  PlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _controller.stream;

  @override
  Future<void> load(MediaAsset asset) async {
    _emit(
      PlayerSnapshot(
        status: asset.durationSeconds > 0
            ? PlayerStatus.ready
            : PlayerStatus.unavailable,
        position: Duration.zero,
        duration: Duration(seconds: asset.durationSeconds),
        playbackSpeed: _snapshot.playbackSpeed,
        errorMessage: asset.durationSeconds > 0
            ? null
            : 'Media duration is unavailable.',
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_snapshot.status == PlayerStatus.idle ||
        _snapshot.status == PlayerStatus.unavailable ||
        _snapshot.status == PlayerStatus.error) {
      throw StateError('Load available media before starting playback.');
    }
    _emit(_copyWith(status: PlayerStatus.playing));
  }

  @override
  Future<void> pause() async {
    if (_snapshot.status == PlayerStatus.playing) {
      _emit(_copyWith(status: PlayerStatus.paused));
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (position < Duration.zero || position > _snapshot.duration) {
      throw RangeError.range(
        position.inMilliseconds,
        0,
        _snapshot.duration.inMilliseconds,
        'position',
      );
    }
    _emit(_copyWith(position: position));
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.25 || speed > 3) {
      throw RangeError.value(speed, 'speed', 'Must be between 0.25 and 3.');
    }
    _emit(_copyWith(playbackSpeed: speed));
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  PlayerSnapshot _copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    String? errorMessage,
  }) {
    return PlayerSnapshot(
      status: status ?? _snapshot.status,
      position: position ?? _snapshot.position,
      duration: duration ?? _snapshot.duration,
      playbackSpeed: playbackSpeed ?? _snapshot.playbackSpeed,
      errorMessage: errorMessage,
    );
  }

  void _emit(PlayerSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }
}
