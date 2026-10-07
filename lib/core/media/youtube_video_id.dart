abstract final class YoutubeVideoId {
  static final _validId = RegExp(r'^[A-Za-z0-9_-]{11}$');
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

  static String? fromUrl(String source) {
    final uri = Uri.tryParse(source.trim());
    final host = uri?.host.toLowerCase();
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        !_youtubeHosts.contains(host)) {
      return null;
    }

    String? candidate;
    if (host!.endsWith('youtu.be')) {
      candidate = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (uri.path == '/watch') {
      candidate = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        const {'embed', 'shorts', 'live'}.contains(uri.pathSegments.first)) {
      candidate = uri.pathSegments[1];
    }

    return candidate != null && _validId.hasMatch(candidate) ? candidate : null;
  }
}