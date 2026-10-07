import 'video_models.dart';

enum NetworkQuality { constrained, moderate, fast }

enum StreamSelectionFailure {
  noCombinedAudioVideoStream,
  unsupportedMimeType,
  exceedsDeviceResolution,
  expiredStream,
}

class StreamSelectionPolicy {
  const StreamSelectionPolicy({
    required this.supportedMimeTypes,
    required this.maxResolutionHeight,
    required this.networkQuality,
  });

  final Set<String> supportedMimeTypes;
  final int maxResolutionHeight;
  final NetworkQuality networkQuality;

  int? get maxBitrateBitsPerSecond => switch (networkQuality) {
    NetworkQuality.constrained => 1500000,
    NetworkQuality.moderate => 5000000,
    NetworkQuality.fast => null,
  };
}

class StreamSelection {
  const StreamSelection._({this.stream, this.failure});

  const StreamSelection.selected(MediaStreamInfo stream)
    : this._(stream: stream);

  const StreamSelection.failed(StreamSelectionFailure failure)
    : this._(failure: failure);

  final MediaStreamInfo? stream;
  final StreamSelectionFailure? failure;

  bool get isSuccess => stream != null;
}

abstract final class StreamSelector {
  static String _normalizedMimeType(String mimeType) =>
      mimeType.split(';').first.trim().toLowerCase();

  static List<MediaStreamInfo> available(
    Iterable<MediaStreamInfo> streams,
    StreamSelectionPolicy policy,
  ) {
    final now = DateTime.now();
    final available = streams
        .where(
          (stream) =>
              stream.hasAudio &&
              stream.hasVideo &&
              policy.supportedMimeTypes.contains(
                _normalizedMimeType(stream.mimeType),
              ) &&
              (stream.resolutionHeight ?? 0) <= policy.maxResolutionHeight &&
              (stream.expiresAt == null || stream.expiresAt!.isAfter(now)),
        )
        .toList(growable: false);
    return List.unmodifiable(available);
  }

  static StreamSelection select(
    Iterable<MediaStreamInfo> streams,
    StreamSelectionPolicy policy,
  ) {
    final combined = streams
        .where((stream) => stream.hasAudio && stream.hasVideo)
        .toList(growable: false);
    if (combined.isEmpty) {
      return const StreamSelection.failed(
        StreamSelectionFailure.noCombinedAudioVideoStream,
      );
    }

    final fresh = combined
        .where(
          (stream) =>
              stream.expiresAt == null ||
              stream.expiresAt!.isAfter(DateTime.now()),
        )
        .toList(growable: false);
    if (fresh.isEmpty) {
      return const StreamSelection.failed(StreamSelectionFailure.expiredStream);
    }

    final supported = fresh
        .where(
          (stream) => policy.supportedMimeTypes.contains(
            _normalizedMimeType(stream.mimeType),
          ),
        )
        .toList(growable: false);
    if (supported.isEmpty) {
      return const StreamSelection.failed(
        StreamSelectionFailure.unsupportedMimeType,
      );
    }

    final withinResolution = supported
        .where(
          (stream) =>
              (stream.resolutionHeight ?? 0) <= policy.maxResolutionHeight,
        )
        .toList(growable: false);
    if (withinResolution.isEmpty) {
      return const StreamSelection.failed(
        StreamSelectionFailure.exceedsDeviceResolution,
      );
    }

    final maxBitrate = policy.maxBitrateBitsPerSecond;
    final withinNetworkBudget = maxBitrate == null
        ? withinResolution
        : withinResolution
              .where(
                (stream) =>
                    stream.bitrateBitsPerSecond == null ||
                    stream.bitrateBitsPerSecond! <= maxBitrate,
              )
              .toList(growable: false);
    final candidates = withinNetworkBudget.isEmpty
        ? [
            withinResolution.reduce(
              (current, candidate) =>
                  (candidate.bitrateBitsPerSecond ?? 0) <
                      (current.bitrateBitsPerSecond ?? 0)
                  ? candidate
                  : current,
            ),
          ]
        : withinNetworkBudget;
    final ranked = [...candidates]
      ..sort((left, right) {
        final resolutionOrder = (right.resolutionHeight ?? 0).compareTo(
          left.resolutionHeight ?? 0,
        );
        if (resolutionOrder != 0) return resolutionOrder;
        return (right.bitrateBitsPerSecond ?? 0).compareTo(
          left.bitrateBitsPerSecond ?? 0,
        );
      });
    return StreamSelection.selected(ranked.first);
  }
}
