import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/stream_selector.dart';
import 'package:voyager_learning/core/media/video_models.dart';

void main() {
  const policy = StreamSelectionPolicy(
    supportedMimeTypes: {'video/mp4'},
    maxResolutionHeight: 1080,
    networkQuality: NetworkQuality.moderate,
  );

  MediaStreamInfo stream({
    required String path,
    required int height,
    required int bitrate,
    DateTime? expiresAt,
    bool hasAudio = true,
    bool hasVideo = true,
    String mimeType = 'video/mp4',
  }) => MediaStreamInfo(
    url: Uri.parse('https://media.example/$path'),
    mimeType: mimeType,
    container: 'mp4',
    resolutionHeight: height,
    bitrateBitsPerSecond: bitrate,
    hasAudio: hasAudio,
    hasVideo: hasVideo,
    expiresAt: expiresAt,
  );

  test('selects best supported combined stream within network budget', () {
    final selection = StreamSelector.select([
      stream(path: '360', height: 360, bitrate: 600000),
      stream(path: '720', height: 720, bitrate: 2500000),
      stream(path: '1080', height: 1080, bitrate: 6500000),
    ], policy);

    expect(selection.stream?.url.path, '/720');
  });

  test('keeps 3360p streams out of the available quality list', () {
    final streams = [
      stream(path: '1080', height: 1080, bitrate: 5000000),
      stream(path: '3360', height: 3360, bitrate: 15000000),
    ];
    const fastPolicy = StreamSelectionPolicy(
      supportedMimeTypes: {'video/mp4'},
      maxResolutionHeight: 1080,
      networkQuality: NetworkQuality.fast,
    );

    expect(
      StreamSelector.available(
        streams,
        fastPolicy,
      ).map((stream) => stream.resolutionHeight),
      [1080],
    );
    expect(
      StreamSelector.select(streams, fastPolicy).stream?.url.path,
      '/1080',
    );
  });

  test('normalizes MIME types before filtering and selecting', () {
    final streams = [
      MediaStreamInfo(
        url: Uri.parse('https://media.example/720'),
        mimeType: 'video/mp4; codecs="avc1.4d401f, mp4a.40.2"',
        container: 'mp4',
        resolutionHeight: 720,
        bitrateBitsPerSecond: 2500000,
        hasAudio: true,
        hasVideo: true,
      ),
      stream(path: '360', height: 360, bitrate: 600000),
    ];

    expect(StreamSelector.available(streams, policy), hasLength(2));
    expect(StreamSelector.select(streams, policy).stream?.url.path, '/720');
  });

  test('rejects separate audio and video streams without mux support', () {
    final selection = StreamSelector.select([
      stream(
        path: 'video-only',
        height: 1080,
        bitrate: 4000000,
        hasAudio: false,
      ),
      stream(path: 'audio-only', height: 0, bitrate: 128000, hasVideo: false),
    ], policy);

    expect(
      selection.failure,
      StreamSelectionFailure.noCombinedAudioVideoStream,
    );
  });

  test('rejects unsupported formats', () {
    final selection = StreamSelector.select([
      stream(
        path: 'webm',
        height: 360,
        bitrate: 500000,
        mimeType: 'video/webm',
      ),
    ], policy);

    expect(selection.failure, StreamSelectionFailure.unsupportedMimeType);
  });

  test('chooses the lowest bitrate when all streams exceed network budget', () {
    final selection = StreamSelector.select(
      [
        stream(path: '720', height: 720, bitrate: 2500000),
        stream(path: '360', height: 360, bitrate: 1800000),
      ],
      const StreamSelectionPolicy(
        supportedMimeTypes: {'video/mp4'},
        maxResolutionHeight: 1080,
        networkQuality: NetworkQuality.constrained,
      ),
    );

    expect(selection.stream?.url.path, '/360');
  });

  test('rejects an expired media stream', () {
    final selection = StreamSelector.select([
      stream(
        path: 'expired',
        height: 360,
        bitrate: 500000,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ], policy);

    expect(selection.failure, StreamSelectionFailure.expiredStream);
  });
}
