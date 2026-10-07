import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video_player;

import 'player_engine.dart';
import 'video_source_adapter.dart';

abstract interface class MediaPlayer {
  PlayerSnapshot get snapshot;
  Stream<PlayerSnapshot> get snapshots;

  Future<void> load(Uri mediaUri);
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Widget buildSurface();
  Future<Duration> get currentPosition;
  Future<void> dispose();
}

class FlutterMediaPlayer implements MediaPlayer {
  final StreamController<PlayerSnapshot> _snapshots =
      StreamController<PlayerSnapshot>.broadcast();
  PlayerSnapshot _snapshot = const PlayerSnapshot.initial();
  video_player.VideoPlayerController? _controller;
  bool _disposed = false;

  @override
  PlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(Uri mediaUri) async {
    _ensureOpen();
    if (mediaUri.scheme != 'https' && mediaUri.scheme != 'http') {
      throw const VideoSourceException(
        VideoSourceFailure.unsupportedFormat,
        'The selected media URL is not an HTTP stream.',
      );
    }
    final previous = _controller;
    _controller = null;
    if (previous != null) {
      previous.removeListener(_onValueChanged);
      await previous.dispose();
    }
    _emit(
      const PlayerSnapshot(
        status: PlayerStatus.loading,
        position: Duration.zero,
        duration: Duration.zero,
        playbackSpeed: 1,
      ),
    );

    final controller = video_player.VideoPlayerController.networkUrl(mediaUri);
    _controller = controller;
    controller.addListener(_onValueChanged);
    try {
      await controller.initialize();
      if (!identical(_controller, controller)) return;
      _emit(
        PlayerSnapshot(
          status: PlayerStatus.ready,
          position: controller.value.position,
          duration: controller.value.duration,
          playbackSpeed: controller.value.playbackSpeed,
        ),
      );
    } on Object catch (error) {
      if (identical(_controller, controller)) {
        _emit(
          PlayerSnapshot(
            status: PlayerStatus.error,
            position: Duration.zero,
            duration: Duration.zero,
            playbackSpeed: 1,
            errorMessage: error.toString(),
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    final controller = _requireController();
    await controller.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    final controller = _requireController();
    final duration = controller.value.duration;
    final target = position < Duration.zero
        ? Duration.zero
        : position > duration
        ? duration
        : position;
    await controller.seekTo(target);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.25 || speed > 3) {
      throw RangeError.value(speed, 'speed', 'Must be between 0.25 and 3.');
    }
    await _requireController().setPlaybackSpeed(speed);
  }

  @override
  Widget buildSurface() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Icon(Icons.ondemand_video, color: Colors.white, size: 48),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: video_player.VideoPlayer(controller),
      ),
    );
  }

  @override
  Future<Duration> get currentPosition async =>
      _controller?.value.position ?? Duration.zero;

  void _onValueChanged() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    final status = value.hasError
        ? PlayerStatus.error
        : value.isCompleted
        ? PlayerStatus.completed
        : value.isPlaying
        ? PlayerStatus.playing
        : PlayerStatus.paused;
    _emit(
      PlayerSnapshot(
        status: status,
        position: value.position,
        duration: value.duration,
        playbackSpeed: value.playbackSpeed,
        errorMessage: value.hasError ? value.errorDescription : null,
      ),
    );
  }

  video_player.VideoPlayerController _requireController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Load playable media before using playback controls.');
    }
    return controller;
  }

  void _emit(PlayerSnapshot snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Media player has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onValueChanged);
      await controller.dispose();
    }
    await _snapshots.close();
  }
}
