class Roadmap {
  const Roadmap({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String title;
  final String description;
  final bool isActive;
}

class Topic {
  const Topic({
    required this.id,
    required this.roadmapId,
    required this.title,
    required this.status,
  });

  final String id;
  final String roadmapId;
  final String title;
  final TopicStatus status;
}

enum TopicStatus {
  notStarted,
  inProgress,
  completed,
}
