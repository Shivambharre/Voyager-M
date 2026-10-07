import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/youtube_video_id.dart';

void main() {
  group('YoutubeVideoId.fromUrl', () {
    test('accepts watch, short, embed, and shorts URLs', () {
      expect(
        YoutubeVideoId.fromUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeVideoId.fromUrl('https://youtu.be/dQw4w9WgXcQ?t=42'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeVideoId.fromUrl('https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeVideoId.fromUrl('https://m.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects other hosts and malformed video IDs', () {
      expect(
        YoutubeVideoId.fromUrl('https://example.com/watch?v=dQw4w9WgXcQ'),
        isNull,
      );
      expect(YoutubeVideoId.fromUrl('https://youtube.com/watch?v=short'), isNull);
      expect(YoutubeVideoId.fromUrl('not a URL'), isNull);
    });
  });
}