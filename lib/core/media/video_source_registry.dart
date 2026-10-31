import 'source_detector.dart';
import 'video_models.dart';
import 'video_source_adapter.dart';

// This registry is the source picker.
// When the app finds a valid URL, it picks the right adapter for it.
class VideoSourceRegistry {
  VideoSourceRegistry(Iterable<VideoSourceAdapter> adapters)
    : _adapters = List.unmodifiable(adapters);

  final List<VideoSourceAdapter> _adapters;

  // Try each adapter until one says, "Yes, I know this source."
  VideoSourceAdapter resolve(SourceDescriptor source) {
    for (final adapter in _adapters) {
      if (adapter.canHandle(source.url)) return adapter;
    }
    throw const VideoSourceException(
      VideoSourceFailure.unsupportedSource,
      'This video source is not supported.',
    );
  }

  Future<void> dispose() async {
    for (final adapter in _adapters) {
      await adapter.dispose();
    }
  }
}

VideoSourceKind sourceKindFor(SourceDescriptor source) => source.kind;
