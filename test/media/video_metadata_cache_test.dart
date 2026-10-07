import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:voyager_learning/core/database/database.dart';
import 'package:voyager_learning/core/media/video_metadata_cache.dart';
import 'package:voyager_learning/core/media/video_models.dart';

void main() {
  late Directory directory;
  late SqfliteAppDatabase database;
  late SqliteVideoMetadataCache cache;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'voyager-metadata-cache-',
    );
    database = SqfliteAppDatabase(
      databasePathProvider: () async => directory.path,
      databaseFactory: databaseFactoryFfi,
    );
    await database.initialize();
    cache = SqliteVideoMetadataCache(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'caches stable video metadata but omits temporary stream URLs',
    () async {
      final video = VideoInfo(
        id: 'dQw4w9WgXcQ',
        source: VideoSourceKind.youtubeVideo,
        url: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        title: 'A lecture',
        duration: const Duration(minutes: 12),
        thumbnailUrl: Uri.parse(
          'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        ),
        author: 'Instructor',
        streams: [
          MediaStreamInfo(
            url: Uri.parse('https://media.example/temp?expire=1893456000'),
            mimeType: 'video/mp4',
            container: 'mp4',
            hasAudio: true,
            hasVideo: true,
          ),
        ],
      );
      await cache.putVideo(video);

      final restored = await cache.getVideo(video.source, video.id);
      final rows = await database.query(
        'video_metadata_cache',
        columns: ['payload'],
      );

      expect(restored?.title, video.title);
      expect(restored?.thumbnailUrl, video.thumbnailUrl);
      expect(restored?.duration, video.duration);
      expect(restored?.streams, isEmpty);
      expect(rows.single['payload'], isNot(contains('media.example')));
    },
  );

  test('preserves playlist ordering in cached metadata', () async {
    final playlist = PlaylistInfo(
      id: 'PL1234567890',
      source: VideoSourceKind.youtubePlaylist,
      url: Uri.parse('https://www.youtube.com/playlist?list=PL1234567890'),
      title: 'Course',
      entries: [
        PlaylistEntryInfo(
          videoId: 'firstVideo01',
          title: 'First',
          position: 0,
          url: Uri.parse('https://www.youtube.com/watch?v=firstVideo01'),
        ),
        PlaylistEntryInfo(
          videoId: 'secondVideo2',
          title: 'Second',
          position: 1,
          url: Uri.parse('https://www.youtube.com/watch?v=secondVideo2'),
        ),
      ],
    );
    await cache.putPlaylist(playlist);

    final restored = await cache.getPlaylist(playlist.source, playlist.id);

    expect(restored?.entries.map((entry) => entry.position), [0, 1]);
    expect(restored?.entries.map((entry) => entry.title), ['First', 'Second']);
  });

  test(
    'stores a playlist and a video independently when IDs collide',
    () async {
      const sharedId = 'same-content-id';
      final video = VideoInfo(
        id: sharedId,
        source: VideoSourceKind.youtubeVideo,
        url: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        title: 'Single video',
        duration: const Duration(seconds: 60),
        streams: const [],
      );
      final playlist = PlaylistInfo(
        id: sharedId,
        source: VideoSourceKind.youtubePlaylist,
        url: Uri.parse('https://www.youtube.com/playlist?list=PL1234567890'),
        title: 'Playlist',
        entries: const [],
      );
      await cache.putVideo(video);
      await cache.putPlaylist(playlist);

      expect(
        (await cache.getVideo(VideoSourceKind.youtubeVideo, sharedId))?.title,
        'Single video',
      );
      expect(
        (await cache.getPlaylist(
          VideoSourceKind.youtubePlaylist,
          sharedId,
        ))?.title,
        'Playlist',
      );
    },
  );
}
