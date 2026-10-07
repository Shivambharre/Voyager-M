import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/video_models.dart';

void main() {
  group('SourceDetector.detect', () {
    test('detects YouTube videos and playlists', () {
      final video = SourceDetector.detect(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(video?.kind, VideoSourceKind.youtubeVideo);
      expect(video?.contentId, 'dQw4w9WgXcQ');

      final playlist = SourceDetector.detect(
        'https://www.youtube.com/playlist?list=PL1234567890ABC',
      );
      expect(playlist?.kind, VideoSourceKind.youtubePlaylist);
      expect(playlist?.contentId, 'PL1234567890ABC');

      expect(
        SourceDetector.detect('https://youtube.com/playlist?list=WL')?.kind,
        VideoSourceKind.youtubePlaylist,
      );
      expect(
        SourceDetector.detect(
          'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
        )?.kind,
        VideoSourceKind.youtubeVideo,
      );
    });

    test('detects MIT OCW pages', () {
      final source = SourceDetector.detect(
        'https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/',
      );
      expect(source?.kind, VideoSourceKind.mitOpenCourseware);
      expect(source?.contentId, '/courses/18-06-linear-algebra-spring-2010/');
    });

    test('rejects malformed URLs and lookalike hosts', () {
      expect(SourceDetector.detect('not a URL'), isNull);
      expect(
        SourceDetector.detect(
          'https://youtube.com.attacker.example/watch?v=dQw4w9WgXcQ',
        ),
        isNull,
      );
      expect(
        SourceDetector.detect('https://www.youtube.com/watch?v=not-an-id'),
        isNull,
      );
    });
  });
}
