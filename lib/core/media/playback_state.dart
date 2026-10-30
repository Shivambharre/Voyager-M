enum PlayerStatus { idle, loading, ready, playing, paused, completed, error }

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
