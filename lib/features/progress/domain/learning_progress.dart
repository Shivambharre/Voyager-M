class LearningProgress {
  const LearningProgress({
    required this.videoId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
    this.isCompleted = false,
  })  : assert(positionSeconds >= 0),
        assert(durationSeconds >= 0);

  final String videoId;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;
  final bool isCompleted;
}

class LearningBookmark {
  const LearningBookmark({
    required this.id,
    required this.videoId,
    required this.positionSeconds,
    required this.createdAt,
    this.label = '',
  }) : assert(positionSeconds >= 0);

  final String id;
  final String videoId;
  final int positionSeconds;
  final DateTime createdAt;
  final String label;
}
