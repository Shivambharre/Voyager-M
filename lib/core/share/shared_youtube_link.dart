import '../media/source_detector.dart';
import '../media/video_models.dart';

abstract final class SharedYoutubeLink {
  static final _urlPattern = RegExp(r"""https?://[^\s<>"']+""");
  static final _trailingPunctuation = RegExp(r'[.,!?;:)\]}]+$');

  static String? extract(String text) {
    for (final match in _urlPattern.allMatches(text)) {
      final candidate = match.group(0)!.replaceFirst(_trailingPunctuation, '');
      final source = SourceDetector.detect(candidate);
      if (source?.kind == VideoSourceKind.youtubeVideo ||
          source?.kind == VideoSourceKind.youtubePlaylist) {
        return source!.url.toString();
      }
    }
    return null;
  }
}
