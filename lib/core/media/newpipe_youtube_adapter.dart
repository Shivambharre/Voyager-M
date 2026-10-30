import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'source_detector.dart';
import 'video_models.dart';
import 'video_source_adapter.dart';
import 'youtube_adapter.dart';

class NewPipeYoutubeAdapter implements VideoSourceAdapter {
  NewPipeYoutubeAdapter({YoutubeAdapter? fallback}) {
    _fallback = fallback;
  }

  static const _channel = MethodChannel('com.voyager/newpipe');
  YoutubeAdapter? _fallback;

  YoutubeAdapter get _fallbackAdapter => _fallback ??= YoutubeAdapter();

  @override
  bool canHandle(Uri url) =>
      SourceDetector.detect(url.toString())?.kind ==
          VideoSourceKind.youtubeVideo ||
      SourceDetector.detect(url.toString())?.kind ==
          VideoSourceKind.youtubePlaylist;

  @override
  Future<VideoInfo> getVideoInfo(SourceDescriptor source) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _fallbackAdapter.getVideoInfo(source);
    }
    if (source.kind != VideoSourceKind.youtubeVideo) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'This URL is not a YouTube video.',
      );
    }

    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'resolveVideo',
        {'url': source.url.toString()},
      );
      if (info == null || info['title'] is! String || info['id'] is! String) {
        throw const VideoSourceException(
          VideoSourceFailure.extractionFailure,
          'NewPipe did not return video metadata.',
        );
      }
      final durationSeconds = info['durationSeconds'];
      final thumbnail = info['thumbnailUrl'];
      final author = info['author'];
      final streams = _parseStreams(info['streams']);
      return VideoInfo(
        id: info['id']! as String,
        source: VideoSourceKind.youtubeVideo,
        url: source.url,
        title: info['title']! as String,
        duration: Duration(
          seconds: durationSeconds is num ? durationSeconds.toInt() : 0,
        ),
        thumbnailUrl: thumbnail is String ? Uri.tryParse(thumbnail) : null,
        author: author is String ? author : null,
        streams: streams,
      );
    } on PlatformException catch (error) {
      throw VideoSourceException(
        VideoSourceFailure.extractionFailure,
        error.message ?? 'NewPipe could not resolve this video.',
      );
    }
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(SourceDescriptor source) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _fallbackAdapter.getPlaylistInfo(source);
    }
    if (source.kind != VideoSourceKind.youtubePlaylist) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'This URL is not a YouTube playlist.',
      );
    }

    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'resolvePlaylist',
        {'url': source.url.toString()},
      );
      final rawEntries = info?['entries'];
      if (info == null ||
          info['title'] is! String ||
          info['id'] is! String ||
          rawEntries is! List) {
        throw const VideoSourceException(
          VideoSourceFailure.extractionFailure,
          'NewPipe did not return playlist metadata.',
        );
      }

      final entries = <PlaylistEntryInfo>[];
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map) continue;
        final entry = Map<Object?, Object?>.from(rawEntry);
        final url = entry['url'];
        final title = entry['title'];
        if (url is! String || title is! String) continue;
        final videoSource = SourceDetector.detect(url);
        if (videoSource?.kind != VideoSourceKind.youtubeVideo) continue;

        final durationSeconds = entry['durationSeconds'];
        final thumbnail = entry['thumbnailUrl'];
        entries.add(
          PlaylistEntryInfo(
            videoId: videoSource!.contentId,
            title: title,
            position: entries.length,
            url: videoSource.url,
            thumbnailUrl: thumbnail is String ? Uri.tryParse(thumbnail) : null,
            duration: durationSeconds is num && durationSeconds > 0
                ? Duration(seconds: durationSeconds.toInt())
                : null,
          ),
        );
      }

      final playlistUrl = info['url'];
      final thumbnail = info['thumbnailUrl'];
      final author = info['author'];
      final description = info['description'];
      return PlaylistInfo(
        id: info['id']! as String,
        source: VideoSourceKind.youtubePlaylist,
        url: playlistUrl is String
            ? Uri.tryParse(playlistUrl) ?? source.url
            : source.url,
        title: info['title']! as String,
        entries: entries,
        thumbnailUrl: thumbnail is String ? Uri.tryParse(thumbnail) : null,
        author: author is String ? author : null,
        description: description is String ? description : null,
      );
    } on PlatformException catch (error) {
      throw VideoSourceException(
        VideoSourceFailure.extractionFailure,
        error.message ?? 'NewPipe could not resolve this playlist.',
      );
    }
  }

  @override
  Future<List<MediaStreamInfo>> getStreams(VideoInfo video) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _fallbackAdapter.getStreams(video);
    }
    if (video.streams.isNotEmpty) return video.streams;

    try {
      final streams = await _channel.invokeListMethod<Object?>(
        'resolveStreams',
        {'url': video.url.toString()},
      );
      return _parseStreams(streams);
    } on PlatformException catch (error) {
      throw VideoSourceException(
        VideoSourceFailure.extractionFailure,
        error.message ?? 'NewPipe could not resolve playable streams.',
      );
    }
  }

  List<MediaStreamInfo> _parseStreams(Object? rawStreams) {
    if (rawStreams is! List) return const [];
    final streams = <MediaStreamInfo>[];
    for (final rawStream in rawStreams) {
      if (rawStream is! Map) continue;
      final stream = Map<Object?, Object?>.from(rawStream);
      final url = stream['url'];
      final mimeType = stream['mimeType'];
      final container = stream['container'];
      if (url is! String || mimeType is! String || container is! String) {
        continue;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
        continue;
      }
      final height = stream['resolutionHeight'];
      final bitrate = stream['bitrateBitsPerSecond'];
      final audioUrl = stream['audioUrl'];
      final parsedAudioUrl = audioUrl is String ? Uri.tryParse(audioUrl) : null;
      streams.add(
        MediaStreamInfo(
          url: uri,
          mimeType: mimeType,
          container: container,
          resolutionHeight: height is num ? height.toInt() : null,
          bitrateBitsPerSecond: bitrate is num ? bitrate.toInt() : null,
          hasAudio: stream['hasAudio'] == true,
          hasVideo: stream['hasVideo'] == true,
          audioUrl:
              parsedAudioUrl != null &&
                  (parsedAudioUrl.scheme == 'https' ||
                      parsedAudioUrl.scheme == 'http')
              ? parsedAudioUrl
              : null,
        ),
      );
    }
    return List.unmodifiable(streams);
  }

  @override
  Future<void> dispose() async {
    await _fallback?.dispose();
    _fallback = null;
  }
}
