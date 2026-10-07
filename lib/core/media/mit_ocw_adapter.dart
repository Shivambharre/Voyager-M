import 'dart:async';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'source_detector.dart';
import 'video_models.dart';
import 'video_source_adapter.dart';

class MitOcwAdapter implements VideoSourceAdapter {
  MitOcwAdapter({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Map<String, List<MediaStreamInfo>> _pendingStreams = {};
  bool _disposed = false;

  @override
  bool canHandle(Uri url) =>
      SourceDetector.detect(url.toString())?.kind ==
      VideoSourceKind.mitOpenCourseware;

  @override
  Future<VideoInfo> getVideoInfo(SourceDescriptor source) async {
    _ensureOpen();
    if (source.kind != VideoSourceKind.mitOpenCourseware) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'This URL is not an MIT OpenCourseWare page.',
      );
    }
    final response = await _getPage(source.url);
    final document = html_parser.parse(response.body);
    final title =
        _meta(document, 'og:title') ??
        document.querySelector('title')?.text.trim() ??
        'MIT OpenCourseWare lesson';
    final description = _meta(document, 'og:description');
    final thumbnail = _resolveUri(source.url, _meta(document, 'og:image'));
    final author = _meta(document, 'author') ?? 'MIT OpenCourseWare';
    final seconds = int.tryParse(_meta(document, 'video:duration') ?? '');
    final info = VideoInfo(
      id: source.contentId,
      source: VideoSourceKind.mitOpenCourseware,
      url: source.url,
      title: title,
      duration: Duration(seconds: seconds ?? 0),
      thumbnailUrl: thumbnail,
      author: author,
      streams: const [],
    );
    _pendingStreams[info.id] = _extractStreams(document, source.url);
    if (description == null) return info;
    return info;
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(SourceDescriptor source) async {
    throw const VideoSourceException(
      VideoSourceFailure.unsupportedSource,
      'MIT OpenCourseWare pages do not expose a standard playlist format.',
    );
  }

  @override
  Future<List<MediaStreamInfo>> getStreams(VideoInfo video) async {
    _ensureOpen();
    final pending = _pendingStreams.remove(video.id);
    if (pending != null) return pending;
    final response = await _getPage(video.url);
    return _extractStreams(html_parser.parse(response.body), video.url);
  }

  Future<http.Response> _getPage(Uri url) async {
    try {
      final response = await _client
          .get(url, headers: const {'user-agent': 'VoyagerLearning/1.0'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 404 || response.statusCode == 410) {
        throw const VideoSourceException(
          VideoSourceFailure.unavailable,
          'This MIT OpenCourseWare page is unavailable.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VideoSourceException(
          VideoSourceFailure.networkFailure,
          'MIT OpenCourseWare returned HTTP ${response.statusCode}.',
        );
      }
      return response;
    } on VideoSourceException {
      rethrow;
    } on TimeoutException {
      throw const VideoSourceException(
        VideoSourceFailure.networkFailure,
        'MIT OpenCourseWare took too long to respond.',
      );
    } on http.ClientException {
      throw const VideoSourceException(
        VideoSourceFailure.networkFailure,
        'Could not reach MIT OpenCourseWare. Check your connection.',
      );
    }
  }

  List<MediaStreamInfo> _extractStreams(Document document, Uri page) {
    final streams = <MediaStreamInfo>[];
    final seen = <Uri>{};
    for (final element in document.querySelectorAll(
      'video[src], video source[src], audio[src], audio source[src], source[src], a[href]',
    )) {
      final rawUri = element.attributes['src'] ?? element.attributes['href'];
      final uri = _resolveUri(page, rawUri);
      if (uri == null ||
          !_isAllowedMediaHost(uri.host) ||
          !_hasSupportedExtension(uri.path) ||
          !seen.add(uri)) {
        continue;
      }
      final extension = uri.pathSegments.last.split('.').last.toLowerCase();
      final isAudio =
          element.localName == 'audio' ||
          const {'mp3', 'm4a', 'aac', 'ogg'}.contains(extension);
      final isVideo = !isAudio;
      final isVideoElement =
          element.localName == 'video' || element.parent?.localName == 'video';
      final hasCombinedTracks = isVideoElement || extension == 'mp4';
      streams.add(
        MediaStreamInfo(
          url: uri,
          mimeType: _mimeType(extension),
          container: extension,
          hasAudio: isAudio || hasCombinedTracks,
          hasVideo: isVideo,
          codecs: element.attributes['type'],
        ),
      );
    }
    return streams;
  }

  String? _meta(Document document, String key) {
    return document
            .querySelector('meta[property="$key"]')
            ?.attributes['content']
            ?.trim()
            .nonEmpty ??
        document
            .querySelector('meta[name="$key"]')
            ?.attributes['content']
            ?.trim()
            .nonEmpty;
  }

  Uri? _resolveUri(Uri base, String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final resolved = uri.hasScheme ? uri : base.resolveUri(uri);
    if (resolved.scheme != 'https' && resolved.scheme != 'http') return null;
    return resolved;
  }

  bool _isAllowedMediaHost(String host) =>
      host == 'mit.edu' || host.endsWith('.mit.edu');

  bool _hasSupportedExtension(String path) => const {
    'mp4',
    'm4v',
    'webm',
    'mp3',
    'm4a',
    'aac',
    'ogg',
  }.contains(path.split('.').last.toLowerCase());

  String _mimeType(String extension) => switch (extension) {
    'mp4' || 'm4v' => 'video/mp4',
    'webm' => 'video/webm',
    'mp3' => 'audio/mpeg',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    _ => 'audio/ogg',
  };

  void _ensureOpen() {
    if (_disposed) throw StateError('MIT OCW adapter has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pendingStreams.clear();
    if (_ownsClient) _client.close();
  }
}

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}
