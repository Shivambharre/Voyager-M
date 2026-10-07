import 'dart:convert';

import '../database/database.dart';
import 'video_models.dart';

abstract interface class VideoMetadataCache {
  Future<VideoInfo?> getVideo(VideoSourceKind source, String id);
  Future<void> putVideo(VideoInfo video);
  Future<PlaylistInfo?> getPlaylist(VideoSourceKind source, String id);
  Future<void> putPlaylist(PlaylistInfo playlist);
}

class InMemoryVideoMetadataCache implements VideoMetadataCache {
  final Map<String, VideoInfo> _videos = {};
  final Map<String, PlaylistInfo> _playlists = {};

  String _key(VideoSourceKind source, String id) => '${source.name}:$id';

  @override
  Future<VideoInfo?> getVideo(VideoSourceKind source, String id) async =>
      _videos[_key(source, id)];

  @override
  Future<void> putVideo(VideoInfo video) async {
    _videos[_key(video.source, video.id)] = VideoInfo(
      id: video.id,
      source: video.source,
      url: video.url,
      title: video.title,
      duration: video.duration,
      thumbnailUrl: video.thumbnailUrl,
      author: video.author,
      streams: const [],
    );
  }

  @override
  Future<PlaylistInfo?> getPlaylist(VideoSourceKind source, String id) async =>
      _playlists[_key(source, id)];

  @override
  Future<void> putPlaylist(PlaylistInfo playlist) async {
    _playlists[_key(playlist.source, playlist.id)] = playlist;
  }
}

class SqliteVideoMetadataCache implements VideoMetadataCache {
  const SqliteVideoMetadataCache(this._database);

  final AppDatabase _database;

  @override
  Future<VideoInfo?> getVideo(VideoSourceKind source, String id) async {
    final row = await _read(source, id, 'video');
    if (row == null) return null;
    try {
      final data = Map<String, Object?>.from(jsonDecode(row) as Map);
      return VideoInfo(
        id: data['id']! as String,
        source: source,
        url: Uri.parse(data['url']! as String),
        title: data['title']! as String,
        duration: Duration(seconds: data['durationSeconds']! as int),
        thumbnailUrl: _optionalUri(data['thumbnailUrl']),
        author: data['author'] as String?,
        streams: const [],
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> putVideo(VideoInfo video) async {
    await _write(video.source, video.id, 'video', {
      'id': video.id,
      'url': video.url.toString(),
      'title': video.title,
      'durationSeconds': video.duration.inSeconds,
      'thumbnailUrl': video.thumbnailUrl?.toString(),
      'author': video.author,
    });
  }

  @override
  Future<PlaylistInfo?> getPlaylist(VideoSourceKind source, String id) async {
    final row = await _read(source, id, 'playlist');
    if (row == null) return null;
    try {
      final data = Map<String, Object?>.from(jsonDecode(row) as Map);
      final entries = (data['entries']! as List)
          .map((entry) {
            final item = Map<String, Object?>.from(entry as Map);
            return PlaylistEntryInfo(
              videoId: item['videoId']! as String,
              title: item['title']! as String,
              position: item['position']! as int,
              url: Uri.parse(item['url']! as String),
              thumbnailUrl: _optionalUri(item['thumbnailUrl']),
              duration: item['durationSeconds'] == null
                  ? null
                  : Duration(seconds: item['durationSeconds']! as int),
            );
          })
          .toList(growable: false);
      return PlaylistInfo(
        id: data['id']! as String,
        source: source,
        url: Uri.parse(data['url']! as String),
        title: data['title']! as String,
        thumbnailUrl: _optionalUri(data['thumbnailUrl']),
        author: data['author'] as String?,
        description: data['description'] as String?,
        entries: entries,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> putPlaylist(PlaylistInfo playlist) async {
    await _write(playlist.source, playlist.id, 'playlist', {
      'id': playlist.id,
      'url': playlist.url.toString(),
      'title': playlist.title,
      'thumbnailUrl': playlist.thumbnailUrl?.toString(),
      'author': playlist.author,
      'description': playlist.description,
      'entries': playlist.entries
          .map(
            (entry) => {
              'videoId': entry.videoId,
              'title': entry.title,
              'position': entry.position,
              'url': entry.url.toString(),
              'thumbnailUrl': entry.thumbnailUrl?.toString(),
              'durationSeconds': entry.duration?.inSeconds,
            },
          )
          .toList(growable: false),
    });
  }

  Future<String?> _read(VideoSourceKind source, String id, String kind) async {
    final rows = await _database.query(
      'video_metadata_cache',
      columns: ['payload'],
      where: 'source = ? AND content_id = ? AND kind = ?',
      whereArgs: [source.name, id, kind],
    );
    return rows.isEmpty ? null : rows.single['payload'] as String?;
  }

  Future<void> _write(
    VideoSourceKind source,
    String id,
    String kind,
    Map<String, Object?> payload,
  ) async {
    await _database.upsert(
      'video_metadata_cache',
      {
        'source': source.name,
        'content_id': id,
        'kind': kind,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      keyWhere: 'source = ? AND content_id = ? AND kind = ?',
      keyArgs: [source.name, id, kind],
    );
  }

  Uri? _optionalUri(Object? value) =>
      value is String && value.isNotEmpty ? Uri.tryParse(value) : null;
}
