import 'source_detector.dart';
import 'video_models.dart';

enum VideoSourceFailure {
  invalidUrl,
  unsupportedSource,
  networkFailure,
  unavailable,
  privateVideo,
  ageRestricted,
  regionRestricted,
  extractionFailure,
  expiredStream,
  unsupportedFormat,
}

class VideoSourceException implements Exception {
  const VideoSourceException(this.failure, this.message);

  final VideoSourceFailure failure;
  final String message;

  @override
  String toString() => message;
}

abstract interface class VideoSourceAdapter {
  bool canHandle(Uri url);

  Future<VideoInfo> getVideoInfo(SourceDescriptor source);

  Future<PlaylistInfo> getPlaylistInfo(SourceDescriptor source);

  Future<List<MediaStreamInfo>> getStreams(VideoInfo video);

  Future<void> dispose();
}
