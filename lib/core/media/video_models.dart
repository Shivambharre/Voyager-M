enum VideoSourceKind { youtubeVideo, youtubePlaylist, mitOpenCourseware }

class VideoInfo {
  const VideoInfo({
    required this.id,
    required this.source,
    required this.url,
    required this.title,
    required this.duration,
    required this.streams,
    this.thumbnailUrl,
    this.author,
  });

  final String id;
  final VideoSourceKind source;
  final Uri url;
  final String title;
  final Duration duration;
  final Uri? thumbnailUrl;
  final String? author;
  final List<MediaStreamInfo> streams;
}

class PlaylistInfo {
  const PlaylistInfo({
    required this.id,
    required this.source,
    required this.url,
    required this.title,
    required this.entries,
    this.thumbnailUrl,
    this.author,
    this.description,
  });

  final String id;
  final VideoSourceKind source;
  final Uri url;
  final String title;
  final Uri? thumbnailUrl;
  final String? author;
  final String? description;
  final List<PlaylistEntryInfo> entries;
}

class PlaylistEntryInfo {
  const PlaylistEntryInfo({
    required this.videoId,
    required this.title,
    required this.position,
    required this.url,
    this.thumbnailUrl,
    this.duration,
  });

  final String videoId;
  final String title;
  final int position;
  final Uri url;
  final Uri? thumbnailUrl;
  final Duration? duration;
}

class MediaStreamInfo {
  const MediaStreamInfo({
    required this.url,
    required this.mimeType,
    required this.container,
    required this.hasAudio,
    required this.hasVideo,
    this.resolutionHeight,
    this.bitrateBitsPerSecond,
    this.codecs,
    this.audioCodec,
    this.videoCodec,
    this.expiresAt,
  });

  final Uri url;
  final String mimeType;
  final String container;
  final int? resolutionHeight;
  final int? bitrateBitsPerSecond;
  final bool hasAudio;
  final bool hasVideo;
  final String? codecs;
  final String? audioCodec;
  final String? videoCodec;
  final DateTime? expiresAt;
}
