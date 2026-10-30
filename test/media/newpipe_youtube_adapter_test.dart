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
            'streams': <Map<String, Object?>>[
              <String, Object?>{
                'url': 'https://media.example/720.mp4',
                'mimeType': 'video/mp4',
                'container': 'mp4',
                'resolutionHeight': 720,
                'bitrateBitsPerSecond': 1500000,
                'audioUrl': 'https://media.example/audio.m4a',
                'hasAudio': true,
                'hasVideo': true,
              },
            ],
          };
        });

    final source = SourceDetector.detect(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    )!;
    final adapter = NewPipeYoutubeAdapter();
    addTearDown(adapter.dispose);
    final video = await adapter.getVideoInfo(source);

    expect(video.id, 'dQw4w9WgXcQ');
    expect(video.source, VideoSourceKind.youtubeVideo);
    expect(video.title, 'Example lesson');
    expect(video.duration, const Duration(seconds: 95));
    expect(video.author, 'Voyager');
    expect(video.thumbnailUrl, Uri.parse('https://example.com/thumbnail.jpg'));
    expect(video.streams, hasLength(1));
    expect(
      video.streams.single.url,
      Uri.parse('https://media.example/720.mp4'),
    );
    expect(
      video.streams.single.audioUrl,
      Uri.parse('https://media.example/audio.m4a'),
    );
    expect((await adapter.getStreams(video)).single.resolutionHeight, 720);
  });

  test('loads fresh streams for cached video metadata', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'resolveStreams');
          expect(
            (call.arguments as Map<Object?, Object?>)['url'],
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          );
          return <Map<String, Object?>>[
            <String, Object?>{
              'url': 'https://media.example/720.mp4',
              'mimeType': 'video/mp4',
              'container': 'mp4',
              'resolutionHeight': 720,
              'bitrateBitsPerSecond': 1500000,
              'audioUrl': 'https://media.example/audio.m4a',
              'hasAudio': true,
              'hasVideo': true,
            },
          ];
        });

    final video = VideoInfo(
      id: 'dQw4w9WgXcQ',
      source: VideoSourceKind.youtubeVideo,
      url: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      title: 'Cached lesson',
      duration: const Duration(minutes: 2),
      streams: const [],
    );
    final adapter = NewPipeYoutubeAdapter();
    addTearDown(adapter.dispose);
    final streams = await adapter.getStreams(video);

    expect(streams, hasLength(1));
    expect(streams.single.hasAudio, isTrue);
    expect(streams.single.hasVideo, isTrue);
    expect(streams.single.bitrateBitsPerSecond, 1500000);
    expect(
      streams.single.audioUrl,
      Uri.parse('https://media.example/audio.m4a'),
    );
  });

  test('resolves a playlist entry to a playable stream', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'resolvePlaylist':
              return <String, Object?>{
                'id': 'PL1234567890ABC',
                'title': 'Example course',
                'entries': <Map<String, Object?>>[
                  <String, Object?>{
                    'title': 'Lecture one',
                    'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                  },
                ],
              };
            case 'resolveVideo':
              return <String, Object?>{
                'id': 'dQw4w9WgXcQ',
                'title': 'Lecture one',
                'streams': <Map<String, Object?>>[
                  <String, Object?>{
                    'url': 'https://media.example/720.mp4',
                    'mimeType': 'video/mp4',
                    'container': 'mp4',
                    'resolutionHeight': 720,
                    'hasAudio': true,
                    'hasVideo': true,
                  },
                ],
              };
            default:
              fail('Unexpected NewPipe method: ${call.method}');
          }
        });

    final adapter = NewPipeYoutubeAdapter();
    addTearDown(adapter.dispose);
    final playlistSource = SourceDetector.detect(
      'https://www.youtube.com/playlist?list=PL1234567890ABC',
    )!;
    final playlist = await adapter.getPlaylistInfo(playlistSource);
    final lectureSource = SourceDetector.detect(
      playlist.entries.single.url.toString(),
    )!;
    final video = await adapter.getVideoInfo(lectureSource);
    final streams = await adapter.getStreams(video);

    expect(video.id, playlist.entries.single.videoId);
    expect(streams.single.hasAudio, isTrue);
    expect(streams.single.url, Uri.parse('https://media.example/720.mp4'));
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
