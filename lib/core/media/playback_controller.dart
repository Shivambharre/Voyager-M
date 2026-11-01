import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'media_player.dart';
import 'playback_state.dart';
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
  Future<void> prefetchVideo(String sourceUrl);
  Future<void> selectLecture(PlaylistEntryInfo entry);
  Future<void> selectStream(MediaStreamInfo stream);
  Widget buildSurface();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
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
  });

  final VideoSourceRegistry sources;
  final VideoMetadataCache metadataCache;
  final MediaPlayer mediaPlayer;
  final StreamSelectionPolicy streamPolicy;
  final AppConfig config;
  VideoSourceAdapter? _activeAdapter;
  VideoInfo? _currentVideo;
  PlaylistInfo? _currentPlaylist;
  List<MediaStreamInfo> _availableStreams = const [];
  MediaStreamInfo? _selectedStream;
  final Set<Future<void>> _backgroundTasks = {};
  int _loadGeneration = 0;
  bool _manualQualitySelection = false;
  bool _upgradeInProgress = false;
  Future<void>? _upgradeTask;
  MediaStreamInfo? _pendingUpgrade;
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
    _loadGeneration++;
    _manualQualitySelection = false;
    _pendingUpgrade = null;
    final activeUpgrade = _upgradeTask;
    if (activeUpgrade != null) await activeUpgrade;
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
    final generation = _loadGeneration;
    final cached = useCache
        ? await metadataCache.getVideo(source.kind, source.contentId)
        : null;
    final adapter = _activeAdapter!;
    final cachedStreams = useCache
        ? await metadataCache.getCachedStreams(source.kind, source.contentId)
        : null;
    late VideoInfo video;
    if (cached == null) {
      video = source.kind == VideoSourceKind.youtubeVideo
          ? await adapter.getFastVideoInfo(source)
          : await adapter.getVideoInfo(source);
    } else if (source.kind == VideoSourceKind.youtubeVideo &&
        cachedStreams == null) {
      final fastVideo = await adapter.getFastVideoInfo(source);
      video = cached.copyWith(streams: fastVideo.streams);
    } else {
      video = cached;
    }
    var streams = cachedStreams ?? video.streams;
    var hasFullStreamList = cachedStreams != null
        ? await metadataCache.hasCompleteStreams(source.kind, source.contentId)
        : video.streams.isNotEmpty && video.streamsComplete;
    if (streams.isEmpty) {
      streams = await metadataCache.getOrLoadStreams(
        source.kind,
        source.contentId,
        () => adapter.getStreams(video),
      );
      hasFullStreamList = true;
    }
    video = video.copyWith(streams: streams);
    if (cached == null) {
      await metadataCache.putVideo(video.copyWith(streams: const []));
    }
    if (generation != _loadGeneration) return;
    await _playVideo(
      video,
      streams,
      generation: generation,
      resolveQualityInBackground:
          source.kind == VideoSourceKind.youtubeVideo && !hasFullStreamList,
    );
  }

  @override
  Future<void> prefetchVideo(String sourceUrl) {
    _ensureOpen();
    final source = SourceDetector.detect(sourceUrl);
    if (source == null || source.kind != VideoSourceKind.youtubeVideo) {
      return Future<void>.value();
    }

    late final Future<void> prefetch;
    prefetch = _prefetchVideo(source)
        .whenComplete(() => _backgroundTasks.remove(prefetch));
    _backgroundTasks.add(prefetch);
    return prefetch;
  }

  Future<void> _prefetchVideo(SourceDescriptor source) async {
    try {
      final adapter = sources.resolve(source);
      final cached = await metadataCache.getVideo(
        source.kind,
        source.contentId,
      );
      final video = await adapter.getFastVideoInfo(source);
      if (cached == null) await metadataCache.putVideo(video);
      if (video.streams.isNotEmpty) {
        if (video.streamsComplete) {
          await metadataCache.getOrLoadStreams(
            source.kind,
            source.contentId,
            () => Future<List<MediaStreamInfo>>.value(video.streams),
          );
        } else {
          await metadataCache.putFastStreams(
            source.kind,
            source.contentId,
            video.streams,
          );
        }
      }
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'video stream prefetch',
        ),
      );
    }
  }

  @override
  Future<void> selectLecture(PlaylistEntryInfo entry) async {
    _ensureOpen();
    _loadGeneration++;
    _manualQualitySelection = false;
    _pendingUpgrade = null;
    final activeUpgrade = _upgradeTask;
    if (activeUpgrade != null) await activeUpgrade;
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

  Future<void> _playVideo(
    VideoInfo video,
    List<MediaStreamInfo> streams, {
    required int generation,
    required bool resolveQualityInBackground,
  }) async {
    _availableStreams = StreamSelector.available(streams, streamPolicy);
    final selection = video.source == VideoSourceKind.youtubeVideo
        ? StreamSelector.selectFast(streams, streamPolicy)
        : StreamSelector.select(streams, streamPolicy);
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
    await mediaPlayer.load(stream.url, audioUri: stream.audioUrl);
    if (generation != _loadGeneration) return;
    _selectedStream = stream;
    if (resolveQualityInBackground) {
      final adapter = _activeAdapter;
      if (adapter != null) {
        late final Future<void> resolution;
        resolution = _resolveQualityInBackground(video, adapter, generation)
            .whenComplete(() => _backgroundTasks.remove(resolution));
        _backgroundTasks.add(resolution);
      }
    } else {
      _considerQualityUpgrade(streams);
    }
  }

  Future<void> _resolveQualityInBackground(
    VideoInfo video,
    VideoSourceAdapter adapter,
    int generation,
  ) async {
    try {
      final streams = await metadataCache.getOrLoadStreams(
        video.source,
        video.id,
        () => adapter.getStreams(video),
      );
      if (_disposed ||
          generation != _loadGeneration ||
          _currentVideo?.id != video.id) {
        return;
      }
      _availableStreams = StreamSelector.available(streams, streamPolicy);
      _considerQualityUpgrade(streams);
      if (_pendingUpgrade != null && snapshot.status == PlayerStatus.playing) {
        unawaited(_upgradeTo(_pendingUpgrade!, generation));
      }
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'background video quality resolution',
        ),
      );
    }
  }

  void _considerQualityUpgrade(List<MediaStreamInfo> streams) {
    if (_manualQualitySelection) return;
    final current = _selectedStream;
    if (current == null) return;
    final best = StreamSelector.select(streams, streamPolicy).stream;
    if (best == null || !_isBetterQuality(best, current)) return;
    _pendingUpgrade = best;
  }

  bool _isBetterQuality(MediaStreamInfo candidate, MediaStreamInfo current) {
    final candidateHeight = candidate.resolutionHeight ?? 0;
    final currentHeight = current.resolutionHeight ?? 0;
    if (candidateHeight != currentHeight) {
      return candidateHeight > currentHeight;
    }
    return (candidate.bitrateBitsPerSecond ?? 0) >
        (current.bitrateBitsPerSecond ?? 0);
  }

  @override
  Future<void> selectStream(MediaStreamInfo stream) async {
    _ensureOpen();
    if (!_availableStreams.contains(stream)) {
      throw ArgumentError.value(stream, 'stream', 'Stream is not available.');
    }
    _manualQualitySelection = true;
    _pendingUpgrade = null;
    final activeUpgrade = _upgradeTask;
    if (activeUpgrade != null) await activeUpgrade;
    if (stream == _selectedStream) return;
    await _replaceStream(stream);
  }

  Future<void> _replaceStream(MediaStreamInfo stream) async {
    await mediaPlayer.replaceStream(stream.url, audioUri: stream.audioUrl);
    _selectedStream = stream;
  }

  Future<void> _upgradeTo(MediaStreamInfo stream, int generation) async {
    if (_disposed ||
        _upgradeInProgress ||
        _manualQualitySelection ||
        generation != _loadGeneration ||
        _currentVideo == null ||
        !_isBetterQuality(stream, _selectedStream ?? stream) ||
        (stream.expiresAt != null &&
            !stream.expiresAt!.isAfter(DateTime.now()))) {
      return;
    }
    _upgradeInProgress = true;
    late final Future<void> task;
    task = _performUpgrade(stream, generation).whenComplete(() {
      if (identical(_upgradeTask, task)) _upgradeTask = null;
      _upgradeInProgress = false;
    });
    _upgradeTask = task;
    await task;
  }

  Future<void> _performUpgrade(MediaStreamInfo stream, int generation) async {
    try {
      final position = await mediaPlayer.currentPosition;
      final duration = snapshot.duration;
      if (duration > Duration.zero &&
          duration - position < const Duration(seconds: 3)) {
        _pendingUpgrade = null;
        return;
      }
      await _replaceStream(stream);
      if (generation == _loadGeneration) _pendingUpgrade = null;
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'background video quality upgrade',
        ),
      );
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
  Future<void> play() async {
    await mediaPlayer.play();
    final pending = _pendingUpgrade;
    if (pending != null) unawaited(_upgradeTo(pending, _loadGeneration));
  }

  @override
  Future<void> pause() => mediaPlayer.pause();

  @override
  Future<void> seekTo(Duration position) => mediaPlayer.seekTo(position);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      mediaPlayer.setPlaybackSpeed(speed);

  @override
  Future<Duration> get currentPosition => mediaPlayer.currentPosition;

  void _ensureOpen() {
    if (_disposed) throw StateError('Playback controller has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait(_backgroundTasks.toList(growable: false));
    final activeUpgrade = _upgradeTask;
    if (activeUpgrade != null) await activeUpgrade;
    await mediaPlayer.dispose();
    await sources.dispose();
  }
}
