class StudyNote {
  const StudyNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.title = 'Untitled Note',
    this.contentJson,
    this.videoId,
    this.topicId,
    this.libraryId,
    this.resourceType,
    this.resourceId,
    this.resourceName,
    this.isResourceArchived = false,
    this.timestampSeconds,
  });

  final String id;
  final String title;

  /// Extracted plain text used for search and simple previews.
  final String content;

  /// Quill Delta JSON. Empty for notes created before rich text was added.
  final String? contentJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? videoId;
  final String? topicId;
  final String? libraryId;
  final NoteResourceType? resourceType;
  final String? resourceId;
  final String? resourceName;
  final bool isResourceArchived;
  final int? timestampSeconds;

  NoteResourceType? get resolvedResourceType =>
      resourceType ??
      (videoId != null
          ? NoteResourceType.video
          : topicId != null
          ? NoteResourceType.lesson
          : libraryId != null
          ? NoteResourceType.library
          : null);

  String? get resolvedResourceId =>
      resourceId ?? videoId ?? topicId ?? libraryId;

  StudyNote copyWith({
    String? title,
    String? content,
    String? contentJson,
    DateTime? updatedAt,
  }) => StudyNote(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    contentJson: contentJson ?? this.contentJson,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    videoId: videoId,
    topicId: topicId,
    libraryId: libraryId,
    resourceType: resourceType,
    resourceId: resourceId,
    resourceName: resourceName,
    isResourceArchived: isResourceArchived,
    timestampSeconds: timestampSeconds,
  );
}

enum NoteResourceType { video, lesson, library }
