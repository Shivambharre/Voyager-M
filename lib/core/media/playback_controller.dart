import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../content_filter/filter_service.dart';
import 'media_player.dart';
import 'player_engine.dart';
import 'source_detector.dart';
import 'stream_selector.dart';
import 'video_metadata_cache.dart';
import 'video_models.dart';
import 'video_source_adapter.dart';
import 'video_source_registry.dart';

abstract interface class PlaybackController {
  PlayerSnapshot get snapshot;
  Stream<PlayerSnapshot> get snapshots;
  VideoInfo? get currentVideo;
  PlaylistInfo? get currentPlaylist;
  List<MediaStreamInfo> get availableStreams;
  MediaStreamInfo? get selectedStream;

  Future<void> load(String sourceUrl);
  Future<void> selectLecture(PlaylistEntryInfo entry);
  Widget buildSurface();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> selectStream(MediaStreamInfo stream);
  Future<Duration> get currentPosition;
  Future<void> dispose();
}

class DefaultPlaybackController implements PlaybackController {
  DefaultPlaybackController({
    required this.sources,
    required this.metadataCache,
    required this.mediaPlayer,
    required this.streamPolicy,
    required this.config,
    required this.contentFilter,
  });

  final VideoSourceRegistry sources;
  final VideoMetadataCache metadataCache;
  final MediaPlayer mediaPlayer;
  final StreamSelectionPolicy streamPolicy;
  final AppConfig config;
  final ContentFilterService contentFilter;
  VideoSourceAdapter? _activeAdapter;
  VideoInfo? _currentVideo;
  PlaylistInfo? _currentPlaylist;
  List<MediaStreamInfo> _availableStreams = const [];
  MediaStreamInfo? _selectedStream;
  bool _disposed = false;

  @override
  PlayerSnapshot get snapshot => mediaPlayer.snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => mediaPlayer.snapshots;

  @override
  VideoInfo? get currentVideo => _currentVideo;

  @override
  PlaylistInfo? get currentPlaylist => _currentPlaylist;

  @override
  List<MediaStreamInfo> get availableStreams => _availableStreams;

  @override
  MediaStreamInfo? get selectedStream => _selectedStream;

  @override
  Future<void> load(String sourceUrl) async {
    _ensureOpen();
    await mediaPlayer.pause();
    final source = SourceDetector.detect(sourceUrl);
    if (source == null) {
      throw const VideoSourceException(
        VideoSourceFailure.invalidUrl,
        'Enter a valid YouTube video, playlist, or MIT OpenCourseWare URL.',
      );
    }
    if (source.kind != VideoSourceKind.mitOpenCourseware &&
        !config.useExtractedYoutubePlayer) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'Extracted YouTube playback is disabled in this build.',
      );
    }
    _currentVideo = null;
    _currentPlaylist = null;
    _availableStreams = const [];
    _selectedStream = null;
    _activeAdapter = sources.resolve(source);
    if (source.kind == VideoSourceKind.youtubePlaylist) {
      await _loadPlaylist(source);
      return;
    }
    await _loadVideo(source, useCache: true);
  }

  Future<void> _loadPlaylist(SourceDescriptor source) async {
    final cached = await metadataCache.getPlaylist(
      source.kind,
      source.contentId,
    );
    final playlist = cached ?? await _activeAdapter!.getPlaylistInfo(source);
    _currentPlaylist = playlist;
    if (cached == null) await metadataCache.putPlaylist(playlist);
    if (playlist.entries.isEmpty) {
      throw const VideoSourceException(
        VideoSourceFailure.unavailable,
        'This playlist has no playable lecture entries.',
      );
    }
  }

  Future<void> _loadVideo(
    SourceDescriptor source, {
    required bool useCache,
  }) async {
    final cached = useCache
        ? await metadataCache.getVideo(source.kind, source.contentId)
        : null;
    final video = cached ?? await _activeAdapter!.getVideoInfo(source);
    if (cached == null) await metadataCache.putVideo(video);
    await _playVideo(video);
  }

  @override
  Future<void> selectLecture(PlaylistEntryInfo entry) async {
    _ensureOpen();
    await mediaPlayer.pause();
    final playlist = _currentPlaylist;
    if (playlist == null) {
      throw StateError('Load a playlist before selecting a lecture.');
    }
    final source = SourceDetector.detect(entry.url.toString());
    if (source == null || source.kind != VideoSourceKind.youtubeVideo) {
      throw const VideoSourceException(
        VideoSourceFailure.invalidUrl,
        'This playlist entry does not contain a valid video URL.',
      );
    }
    if (!config.useExtractedYoutubePlayer) {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedSource,
        'Extracted YouTube playback is disabled in this build.',
      );
    }
    _activeAdapter = sources.resolve(source);
    await _loadVideo(source, useCache: true);
  }

  Future<void> _playVideo(VideoInfo video) async {
    final adapter = _activeAdapter;
    if (adapter == null) throw StateError('No source adapter is active.');
    final streams = await adapter.getStreams(video);
    _availableStreams = StreamSelector.available(streams, streamPolicy);
    final selection = StreamSelector.select(streams, streamPolicy);
    final stream = selection.stream;
    if (stream == null) {
      throw VideoSourceException(
        selection.failure == StreamSelectionFailure.noCombinedAudioVideoStream
            ? VideoSourceFailure.unsupportedFormat
            : selection.failure == StreamSelectionFailure.expiredStream
            ? VideoSourceFailure.expiredStream
            : VideoSourceFailure.unsupportedFormat,
        _streamSelectionMessage(selection.failure),
      );
    }
    _currentVideo = video;
    _selectedStream = stream;
    try {
      await mediaPlayer.load(stream.url);
    } on Object {
      rethrow;
    }
  }

  String _streamSelectionMessage(StreamSelectionFailure? failure) =>
      switch (failure) {
        StreamSelectionFailure.noCombinedAudioVideoStream => 'Only separate audio and video tracks are available. This player cannot mux tracks yet.',
        StreamSelectionFailure.unsupportedMimeType =>
          'No stream format supported by this device is available.',
        StreamSelectionFailure.exceedsDeviceResolution =>
          'No stream matches the device resolution limit.',
        StreamSelectionFailure.expiredStream =>
          'The media stream has expired. Reload the lecture to refresh it.',
        null => 'No playable stream is available for this lecture.',
      };

  @override
  Widget buildSurface() => mediaPlayer.buildSurface();

  @override
  Future<void> play() => mediaPlayer.play();

  @override
  Future<void> pause() => mediaPlayer.pause();

  @override
  Future<void> seekTo(Duration position) => mediaPlayer.seekTo(position);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      mediaPlayer.setPlaybackSpeed(speed);

  @override
  Future<void> selectStream(MediaStreamInfo stream) async {
    _ensureOpen();
    if (!_availableStreams.contains(stream)) {
      throw ArgumentError.value(stream, 'stream', 'Stream is not available.');
    }
    if (stream == _selectedStream) return;

    final position = await mediaPlayer.currentPosition;
    final wasPlaying = snapshot.status == PlayerStatus.playing;
    await mediaPlayer.pause();
    await mediaPlayer.load(stream.url);
    if (position > Duration.zero) await mediaPlayer.seekTo(position);
    if (wasPlaying) await mediaPlayer.play();
    _selectedStream = stream;
  }

  @override
  Future<Duration> get currentPosition => mediaPlayer.currentPosition;

  void _ensureOpen() {
    if (_disposed) throw StateError('Playback controller has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await contentFilter.dispose();
    await mediaPlayer.dispose();
    await sources.dispose();
  }
}
