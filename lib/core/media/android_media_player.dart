import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'media_player.dart';
import 'playback_state.dart';

class AndroidMediaPlayer implements MediaPlayer {
  AndroidMediaPlayer() {
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => unawaited(_refreshSnapshot()),
    );
  }

  static const _channel = MethodChannel('com.voyager/player');
  static const _viewType = 'com.voyager/player_view';

  final StreamController<PlayerSnapshot> _snapshots =
      StreamController<PlayerSnapshot>.broadcast();
  PlayerSnapshot _snapshot = const PlayerSnapshot.initial();
  late final Timer _pollTimer;
  bool _disposed = false;

  @override
  PlayerSnapshot get snapshot => _snapshot;

  @override
  Stream<PlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> load(Uri mediaUri, {Uri? audioUri}) async {
    _ensureOpen();
    _requireHttpUri(mediaUri, 'video');
    if (audioUri != null) _requireHttpUri(audioUri, 'audio');
    _emit(
      const PlayerSnapshot(
        status: PlayerStatus.loading,
        position: Duration.zero,
        duration: Duration.zero,
        playbackSpeed: 1,
      ),
    );
    await _channel.invokeMethod<void>('load', {
      'videoUrl': mediaUri.toString(),
      if (audioUri != null) 'audioUrl': audioUri.toString(),
    });
    for (var attempt = 0; attempt < 300; attempt++) {
      await _refreshSnapshot();
      if (_snapshot.status == PlayerStatus.ready ||
          _snapshot.status == PlayerStatus.paused) {
        return;
      }
      if (_snapshot.status == PlayerStatus.error) {
        throw StateError(
          _snapshot.errorMessage ?? 'Android media player failed to load.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException(
      'Timed out while preparing the Android media stream.',
    );
  }

  @override
  Future<void> replaceStream(Uri mediaUri, {Uri? audioUri}) async {
    _ensureOpen();
    _requireHttpUri(mediaUri, 'video');
    if (audioUri != null) _requireHttpUri(audioUri, 'audio');
    await _channel.invokeMethod<void>('replaceStream', {
      'videoUrl': mediaUri.toString(),
      if (audioUri != null) 'audioUrl': audioUri.toString(),
    });
  }

  @override
  Future<void> play() => _channel.invokeMethod<void>('play');

  @override
  Future<void> pause() => _channel.invokeMethod<void>('pause');

  @override
  Future<void> seekTo(Duration position) => _channel.invokeMethod<void>(
    'seekTo',
    {'positionMs': position.inMilliseconds},
  );

  @override
  Future<void> setPlaybackSpeed(double speed) {
    if (speed < 0.25 || speed > 3) {
      throw RangeError.value(speed, 'speed', 'Must be between 0.25 and 3.');
    }
    return _channel.invokeMethod<void>('setPlaybackSpeed', {'speed': speed});
  }

  @override
  Widget buildSurface() => AndroidView(
    viewType: _viewType,
    creationParamsCodec: const StandardMessageCodec(),
  );

  @override
  Future<Duration> get currentPosition async {
    final state = await _channel.invokeMapMethod<String, Object?>('getState');
    final position = state?['positionMs'];
    return Duration(milliseconds: position is num ? position.toInt() : 0);
  }

  Future<void> _refreshSnapshot() async {
    if (_disposed) return;
    final state = await _channel.invokeMapMethod<String, Object?>('getState');
    if (_disposed || state == null) return;
    final position = state['positionMs'];
    final duration = state['durationMs'];
    final speed = state['playbackSpeed'];
    final status = switch (state['status']) {
      'loading' => PlayerStatus.loading,
      'ready' => PlayerStatus.ready,
      'playing' => PlayerStatus.playing,
      'paused' => PlayerStatus.paused,
      'completed' => PlayerStatus.completed,
      'error' => PlayerStatus.error,
      _ => PlayerStatus.idle,
    };
    _emit(
      PlayerSnapshot(
        status: status,
        position: Duration(
          milliseconds: position is num ? position.toInt() : 0,
        ),
        duration: Duration(
          milliseconds: duration is num ? duration.toInt() : 0,
        ),
        playbackSpeed: speed is num ? speed.toDouble() : 1,
        errorMessage: state['errorMessage'] as String?,
      ),
    );
  }

  void _emit(PlayerSnapshot snapshot) {
    if (_snapshot.status == snapshot.status &&
        _snapshot.position == snapshot.position &&
        _snapshot.duration == snapshot.duration &&
        _snapshot.playbackSpeed == snapshot.playbackSpeed &&
        _snapshot.errorMessage == snapshot.errorMessage) {
      return;
    }
    _snapshot = snapshot;
    _snapshots.add(snapshot);
  }

  void _requireHttpUri(Uri uri, String track) {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(uri, track, 'Expected an HTTP(S) media URL.');
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Media player has been disposed.');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer.cancel();
    await _channel.invokeMethod<void>('pause');
    await _snapshots.close();
  }
}
