import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:voyager_learning/core/media/mit_ocw_adapter.dart';
import 'package:voyager_learning/core/media/source_detector.dart';
import 'package:voyager_learning/core/media/video_models.dart';
import 'package:voyager_learning/core/media/video_source_adapter.dart';

void main() {
  test('extracts metadata and direct MIT-hosted media from OCW HTML', () async {
    final client = _StaticHttpClient('''
      <html>
        <head>
          <title>Linear Algebra Lecture 1</title>
          <meta property="og:title" content="Lecture One">
          <meta property="og:image" content="/images/lecture.jpg">
          <meta name="author" content="MIT OpenCourseWare">
          <meta property="video:duration" content="1800">
        </head>
        <body>
          <video><source src="/media/lecture.mp4" type="video/mp4"></video>
          <a href="https://media.example/third-party.mp4">External</a>
        </body>
      </html>
    ''');
    final adapter = MitOcwAdapter(client: client);
    final source = SourceDetector.detect(
      'https://ocw.mit.edu/courses/18-06/lecture-1/',
    )!;

    final video = await adapter.getVideoInfo(source);
    final streams = await adapter.getStreams(video);

    expect(video.title, 'Lecture One');
    expect(video.duration, const Duration(seconds: 1800));
    expect(
      video.thumbnailUrl,
      Uri.parse('https://ocw.mit.edu/images/lecture.jpg'),
    );
    expect(video.source, VideoSourceKind.mitOpenCourseware);
    expect(streams, hasLength(1));
    expect(
      streams.single.url,
      Uri.parse('https://ocw.mit.edu/media/lecture.mp4'),
    );
    expect(streams.single.hasAudio, isTrue);
    expect(streams.single.hasVideo, isTrue);

    await adapter.dispose();
    client.close();
  });

  test(
    'returns a useful unsupported result for OCW playlist requests',
    () async {
      final adapter = MitOcwAdapter(client: _StaticHttpClient(''));
      final source = SourceDetector.detect(
        'https://ocw.mit.edu/courses/18-06/',
      )!;

      await expectLater(
        adapter.getPlaylistInfo(source),
        throwsA(
          isA<VideoSourceException>().having(
            (error) => error.failure,
            'failure',
            VideoSourceFailure.unsupportedSource,
          ),
        ),
      );
      await adapter.dispose();
    },
  );
}

class _StaticHttpClient extends http.BaseClient {
  _StaticHttpClient(this._body);

  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(_body)),
      200,
      request: request,
      headers: const {'content-type': 'text/html; charset=utf-8'},
    );
  }
}
