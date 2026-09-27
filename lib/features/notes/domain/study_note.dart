class StudyNote {
  const StudyNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.videoId,
    this.topicId,
    this.timestampSeconds,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoId;
  final String? topicId;
  final int? timestampSeconds;
}
