import 'video_models.dart';

class SourceDescriptor {
  const SourceDescriptor({
    required this.kind,
    required this.url,
    required this.contentId,
  });

  final VideoSourceKind kind;
  final Uri url;
  final String contentId;
}

abstract final class SourceDetector {
  static const _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
    'youtu.be',
    'www.youtu.be',
  };
  static final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final _playlistId = RegExp(r'^[A-Za-z0-9_-]{2,200}$');

  static SourceDescriptor? detect(String source) {
    final url = Uri.tryParse(source.trim());
    if (url == null ||
        (url.scheme != 'http' && url.scheme != 'https') ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty) {
      return null;
    }

    final host = url.host.toLowerCase();
    if (_youtubeHosts.contains(host)) {
      final playlistId = url.queryParameters['list'];
      if (playlistId != null && _playlistId.hasMatch(playlistId)) {
        return SourceDescriptor(
          kind: VideoSourceKind.youtubePlaylist,
          url: url,
          contentId: playlistId,
        );
      }

      final videoId = _videoIdFromUrl(url, host);
      if (videoId == null) return null;
      return SourceDescriptor(
        kind: VideoSourceKind.youtubeVideo,
        url: url,
        contentId: videoId,
      );
    }

    if (host == 'ocw.mit.edu' || host == 'www.ocw.mit.edu') {
      if (url.pathSegments.isEmpty) return null;
      return SourceDescriptor(
        kind: VideoSourceKind.mitOpenCourseware,
        url: url,
        contentId: url.path,
      );
    }
    return null;
  }

  static String? _videoIdFromUrl(Uri url, String host) {
    String? candidate;
    if (host == 'youtu.be' || host == 'www.youtu.be') {
      candidate = url.pathSegments.firstOrNull;
    } else if (url.path == '/watch') {
      candidate = url.queryParameters['v'];
    } else if (url.pathSegments.length >= 2 &&
        const {
          'embed',
          'shorts',
          'live',
          'v',
        }.contains(url.pathSegments.first)) {
      candidate = url.pathSegments[1];
    }
    return candidate != null && _youtubeId.hasMatch(candidate)
        ? candidate
        : null;
  }
}
