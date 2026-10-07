import 'package:youtube_explode_dart/youtube_explode_dart.dart' as youtube;

import 'source_detector.dart';
import 'video_models.dart';
import 'video_source_adapter.dart';

class YoutubeAdapter implements VideoSourceAdapter {
  YoutubeAdapter({youtube.YoutubeExplode? client})
    : _client = client ?? youtube.YoutubeExplode();

  final youtube.YoutubeExplode _client;
  bool _disposed = false;

  @override
  bool canHandle(Uri url) =>
      SourceDetector.detect(url.toString())?.kind ==
          VideoSourceKind.youtubeVideo ||
      SourceDetector.detect(url.toString())?.kind ==
          VideoSourceKind.youtubePlaylist;

  @override
  Future<VideoInfo> getVideoInfo(SourceDescriptor source) async {
    _ensureOpen();
    if (source.kind != VideoSourceKind.youtubeVideo) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'This URL is not a YouTube video.',
      );
    }
    try {
      final video = await _client.videos.get(source.contentId);
      return VideoInfo(
        id: video.id.value,
        source: VideoSourceKind.youtubeVideo,
        url: Uri.parse(video.url),
        title: video.title,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: Uri.parse(
          'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg',
        ),
        author: video.author,
        streams: const [],
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(SourceDescriptor source) async {
    _ensureOpen();
    if (source.kind != VideoSourceKind.youtubePlaylist) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'This URL is not a YouTube playlist.',
      );
    }
    try {
      final playlist = await _client.playlists.get(source.contentId);
      final entries = <PlaylistEntryInfo>[];
      await for (final video
          in _client.playlists.getVideos(source.contentId).take(500)) {
        entries.add(
          PlaylistEntryInfo(
            videoId: video.id.value,
            title: video.title,
            position: entries.length,
            url: Uri.parse(video.url),
            thumbnailUrl: Uri.parse(
              'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg',
            ),
            duration: video.duration,
          ),
        );
      }
      return PlaylistInfo(
        id: playlist.id.value,
        source: VideoSourceKind.youtubePlaylist,
        url: Uri.parse(playlist.url),
        title: playlist.title,
        thumbnailUrl: entries.isEmpty ? null : entries.first.thumbnailUrl,
        author: playlist.author,
        description: playlist.description,
        entries: entries,
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<List<MediaStreamInfo>> getStreams(VideoInfo video) async {
    _ensureOpen();
    if (video.source != VideoSourceKind.youtubeVideo) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'Streams are not available for this source.',
      );
    }
    try {
      final manifest = await _client.videos.streams.getManifest(video.id);
      return manifest.streams.map(_mapStream).toList(growable: false);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  MediaStreamInfo _mapStream(youtube.StreamInfo stream) {
    final isMuxed = stream is youtube.MuxedStreamInfo;
    final hasAudio = stream is youtube.AudioStreamInfo || isMuxed;
    final hasVideo = stream is youtube.VideoStreamInfo || isMuxed;
    final expireSeconds = int.tryParse(
      stream.url.queryParameters['expire'] ?? '',
    );
    final mimeType = stream.codec.mimeType.split(';').first.trim();
    final resolutionHeight = switch (stream) {
      youtube.VideoStreamInfo(:final videoResolution) => videoResolution.height,
      youtube.MuxedStreamInfo(:final videoResolution) => videoResolution.height,
      _ => null,
    };
    return MediaStreamInfo(
      url: stream.url,
      mimeType: mimeType,
      container: stream.container.name,
      resolutionHeight: hasVideo ? resolutionHeight : null,
      bitrateBitsPerSecond: stream.bitrate.bitsPerSecond,
      hasAudio: hasAudio,
      hasVideo: hasVideo,
      codecs: stream.codec.parameters['codecs'],
      audioCodec: switch (stream) {
        youtube.AudioStreamInfo(:final audioCodec) => audioCodec,
        youtube.MuxedStreamInfo(:final audioCodec) => audioCodec,
        _ => null,
      },
      videoCodec: switch (stream) {
        youtube.VideoStreamInfo(:final videoCodec) => videoCodec,
        youtube.MuxedStreamInfo(:final videoCodec) => videoCodec,
        _ => null,
      },
      expiresAt: expireSeconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expireSeconds * 1000),
    );
  }

  VideoSourceException _mapFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('private')) {
      return const VideoSourceException(
        VideoSourceFailure.privateVideo,
        'This video or playlist is private.',
      );
    }
    if (message.contains('age')) {
      return const VideoSourceException(
        VideoSourceFailure.ageRestricted,
        'This video is age-restricted and cannot be opened here.',
      );
    }
    if (message.contains('region') || message.contains('country')) {
      return const VideoSourceException(
        VideoSourceFailure.regionRestricted,
        'This video is unavailable in your region.',
      );
    }
    if (message.contains('unavailable') || message.contains('not found')) {
      return const VideoSourceException(
        VideoSourceFailure.unavailable,
        'This video or playlist is unavailable.',
      );
    }
    if (error is youtube.YoutubeExplodeException &&
        (message.contains('socket') ||
            message.contains('timeout') ||
            message.contains('connection') ||
            message.contains('network'))) {
      return const VideoSourceException(
        VideoSourceFailure.networkFailure,
        'Could not reach YouTube. Check your connection and try again.',
      );
    }
    return const VideoSourceException(
      VideoSourceFailure.extractionFailure,
      'YouTube could not provide this video information. Try again later.',
    );
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('YouTube adapter has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _client.close();
  }
}
