import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/share/shared_youtube_link.dart';

void main() {
  test('extracts a YouTube video link from shared text', () {
    expect(
      SharedYoutubeLink.extract(
        'Watch this lesson: https://youtu.be/dQw4w9WgXcQ?t=42\nShared from YouTube',
      ),
      'https://youtu.be/dQw4w9WgXcQ?t=42',
    );
  });

  test('extracts playlist links and removes surrounding punctuation', () {
    expect(
      SharedYoutubeLink.extract(
        'Course playlist (https://www.youtube.com/playlist?list=PL1234567890ABC).',
      ),
      'https://www.youtube.com/playlist?list=PL1234567890ABC',
    );
  });

  test('rejects unrelated and lookalike links', () {
    expect(
      SharedYoutubeLink.extract(
        'https://youtube.com.evil.example/watch?v=dQw4w9WgXcQ',
      ),
      isNull,
    );
    expect(SharedYoutubeLink.extract('https://example.com/video'), isNull);
  });
}
