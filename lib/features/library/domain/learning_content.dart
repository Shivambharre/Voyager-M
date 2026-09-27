class LearningVideo {
  const LearningVideo({
    required this.id,
    required this.sourceId,
    required this.sourceUrl,
    required this.title,
    required this.creator,
    required this.durationSeconds,
    this.thumbnailUrl,
  });

  final String id;
  final String sourceId;
  final String sourceUrl;
  final String title;
  final String creator;
  final int durationSeconds;
  final String? thumbnailUrl;
}

class LearningPlaylist {
  const LearningPlaylist({
    required this.id,
    required this.sourceId,
    required this.sourceUrl,
    required this.title,
    required this.creator,
    this.description = '',
  });

  final String id;
  final String sourceId;
  final String sourceUrl;
  final String title;
  final String creator;
  final String description;
}

class PlaylistEntry {
  const PlaylistEntry({
    required this.playlistId,
    required this.videoId,
    required this.position,
  });

  final String playlistId;
  final String videoId;
  final int position;
}
