import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/config/app_config.dart';
import 'package:voyager_learning/core/content_filter/filter_engine.dart';
import 'package:voyager_learning/core/content_filter/filter_service.dart';
import 'package:voyager_learning/core/media/media_player.dart';
import 'package:voyager_learning/core/media/playback_controller.dart';
import 'package:voyager_learning/core/media/player_engine.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/stream_selector.dart';
import 'package:voyager_learning/core/media/video_metadata_cache.dart';
import 'package:voyager_learning/core/media/video_models.dart';
import 'package:voyager_learning/core/media/video_source_adapter.dart';
import 'package:voyager_learning/core/media/video_source_registry.dart';

void main() {
  late _FakeAdapter adapter;
  late _FakeMediaPlayer player;
  late DefaultPlaybackController controller;

  setUp(() {
    adapter = _FakeAdapter();
    player = _FakeMediaPlayer();
    controller = DefaultPlaybackController(
      sources: VideoSourceRegistry([adapter]),
      metadataCache: InMemoryVideoMetadataCache(),
      mediaPlayer: player,
      streamPolicy: const StreamSelectionPolicy(
        supportedMimeTypes: {'video/mp4'},
        maxResolutionHeight: 1080,
        networkQuality: NetworkQuality.fast,
      ),
      config: const AppConfig(),
      contentFilter: ContentFilterService(
        config: const AppConfig(),
        engine: NoOpContentFilterEngine(),
      ),
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  test(
    'video URL resolves, extracts, selects, then loads a media stream',
    () async {
      await controller.load('https://www.youtube.com/watch?v=dQw4w9WgXcQ');

      expect(controller.currentVideo?.id, 'dQw4w9WgXcQ');
      expect(adapter.videoInfoCalls, 1);
      expect(adapter.streamCalls, 1);
      expect(
        player.loadedUri,
        Uri.parse('https://media.example/combined-720.mp4'),
      );
      expect(
        player.loadedUri,
        isNot(Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ')),
      );
    },
  );

  test(
    'playlist load defers stream extraction until a lecture is selected',
    () async {
      await controller.load(
        'https://www.youtube.com/playlist?list=PL1234567890',
      );

      expect(controller.currentPlaylist?.entries, hasLength(1));
      expect(adapter.playlistCalls, 1);
      expect(adapter.streamCalls, 0);

      await controller.selectLecture(
        controller.currentPlaylist!.entries.single,
      );

      expect(adapter.streamCalls, 1);
      expect(
        player.loadedUri,
        Uri.parse('https://media.example/combined-720.mp4'),
      );
    },
  );

  test('switches to another available stream quality', () async {
    await controller.load('https://www.youtube.com/watch?v=dQw4w9WgXcQ');

    expect(controller.availableStreams, hasLength(2));
    final lowerQuality = controller.availableStreams.firstWhere(
      (stream) => stream.resolutionHeight == 360,
    );
    await controller.selectStream(lowerQuality);

    expect(controller.selectedStream, lowerQuality);
    expect(player.loadedUri, lowerQuality.url);
  });
}

class _FakeAdapter implements VideoSourceAdapter {
  int videoInfoCalls = 0;
  int playlistCalls = 0;
  int streamCalls = 0;

  @override
  bool canHandle(Uri url) => url.host.endsWith('youtube.com');

  @override
  Future<VideoInfo> getVideoInfo(SourceDescriptor source) async {
    videoInfoCalls++;
    return VideoInfo(
      id: source.contentId,
      source: VideoSourceKind.youtubeVideo,
      url: source.url,
      title: 'Test lecture',
      duration: const Duration(minutes: 10),
      streams: const [],
    );
  }

  @override
  Future<PlaylistInfo> getPlaylistInfo(SourceDescriptor source) async {
    playlistCalls++;
    return PlaylistInfo(
      id: source.contentId,
      source: VideoSourceKind.youtubePlaylist,
      url: source.url,
      title: 'Test playlist',
      entries: [
        PlaylistEntryInfo(
          videoId: 'dQw4w9WgXcQ',
          title: 'Test lecture',
          position: 0,
          url: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        ),
      ],
    );
  }

  @override
  Future<List<MediaStreamInfo>> getStreams(VideoInfo video) async {
    streamCalls++;
    return [
      MediaStreamInfo(
        url: Uri.parse('https://media.example/combined-720.mp4'),
        mimeType: 'video/mp4',
        container: 'mp4',
        resolutionHeight: 720,
        bitrateBitsPerSecond: 1500000,
        hasAudio: true,
        hasVideo: true,
      ),
      MediaStreamInfo(
        url: Uri.parse('https://media.example/combined-360.mp4'),
        mimeType: 'video/mp4',
        container: 'mp4',
        resolutionHeight: 360,
        bitrateBitsPerSecond: 500000,
        hasAudio: true,
        hasVideo: true,
      ),
    ];
  }

  @override
  Future<void> dispose() async {}
}

class _FakeMediaPlayer implements MediaPlayer {
  final _snapshots = StreamController<PlayerSnapshot>.broadcast();
  PlayerSnapshot _snapshot = const PlayerSnapshot.initial();
  Uri? loadedUri;

  @override
  PlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(Uri mediaUri) async {
    loadedUri = mediaUri;
    _snapshot = const PlayerSnapshot(
      status: PlayerStatus.ready,
      position: Duration.zero,
      duration: Duration(minutes: 10),
      playbackSpeed: 1,
    );
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  Widget buildSurface() => const SizedBox.shrink();

  @override
  Future<Duration> get currentPosition async => Duration.zero;

  @override
  Future<void> dispose() async => _snapshots.close();
}
