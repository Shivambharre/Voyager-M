import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/core/media/newpipe_youtube_adapter.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/video_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.voyager/newpipe');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('maps NewPipe metadata to the app video model', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'resolveVideo');
          expect(
            (call.arguments as Map<Object?, Object?>)['url'],
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          );
          return <String, Object?>{
            'id': 'dQw4w9WgXcQ',
            'title': 'Example lesson',
            'durationSeconds': 95,
            'author': 'Voyager',
            'thumbnailUrl': 'https://example.com/thumbnail.jpg',
          };
        });

    final source = SourceDetector.detect(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    )!;
    final video = await NewPipeYoutubeAdapter().getVideoInfo(source);

    expect(video.id, 'dQw4w9WgXcQ');
    expect(video.source, VideoSourceKind.youtubeVideo);
    expect(video.title, 'Example lesson');
    expect(video.duration, const Duration(seconds: 95));
    expect(video.author, 'Voyager');
    expect(video.thumbnailUrl, Uri.parse('https://example.com/thumbnail.jpg'));
    expect(video.streams, isEmpty);
  });

  test('maps NewPipe playlist pages to ordered lecture entries', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'resolvePlaylist');
          return <String, Object?>{
            'id': 'PL1234567890ABC',
            'url': 'https://www.youtube.com/playlist?list=PL1234567890ABC',
            'title': 'Example course',
            'author': 'Voyager',
            'description': 'A playlist description',
            'thumbnailUrl': 'https://example.com/course.jpg',
            'entries': <Map<String, Object?>>[
              <String, Object?>{
                'title': 'Lecture one',
                'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                'durationSeconds': 95,
                'thumbnailUrl': 'https://example.com/lecture-one.jpg',
              },
              <String, Object?>{
                'title': 'Lecture two',
                'url': 'https://youtu.be/abcdefghijk',
              },
            ],
          };
        });

    final source = SourceDetector.detect(
      'https://www.youtube.com/playlist?list=PL1234567890ABC',
    )!;
    final playlist = await NewPipeYoutubeAdapter().getPlaylistInfo(source);

    expect(playlist.id, 'PL1234567890ABC');
    expect(playlist.title, 'Example course');
    expect(playlist.author, 'Voyager');
    expect(playlist.entries, hasLength(2));
    expect(playlist.entries[0].position, 0);
    expect(playlist.entries[0].videoId, 'dQw4w9WgXcQ');
    expect(playlist.entries[0].duration, const Duration(seconds: 95));
    expect(playlist.entries[1].position, 1);
    expect(playlist.entries[1].videoId, 'abcdefghijk');
  });
}