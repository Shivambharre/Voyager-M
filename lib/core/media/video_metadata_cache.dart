import 'dart:convert';

import '../database/database.dart';
import 'video_models.dart';

abstract interface class VideoMetadataCache {
  Future<VideoInfo?> getVideo(VideoSourceKind source, String id);
  Future<void> putVideo(VideoInfo video);
  Future<List<MediaStreamInfo>> getOrLoadStreams(
    VideoSourceKind source,
    String id,
    Future<List<MediaStreamInfo>> Function() load,
  );
  Future<PlaylistInfo?> getPlaylist(VideoSourceKind source, String id);
  Future<void> putPlaylist(PlaylistInfo playlist);
}

class InMemoryVideoMetadataCache
    with _EphemeralStreamCache
    implements VideoMetadataCache {
  final Map<String, VideoInfo> _videos = {};
  final Map<String, PlaylistInfo> _playlists = {};

  String _key(VideoSourceKind source, String id) => '${source.name}:$id';

  @override
  Future<VideoInfo?> getVideo(VideoSourceKind source, String id) async =>
      _videos[_key(source, id)];

  @override
  Future<void> putVideo(VideoInfo video) async {
    _videos[_key(video.source, video.id)] = video.copyWith(streams: const []);
  }

  @override
  Future<PlaylistInfo?> getPlaylist(VideoSourceKind source, String id) async =>
      _playlists[_key(source, id)];

  @override
  Future<void> putPlaylist(PlaylistInfo playlist) async {
    _playlists[_key(playlist.source, playlist.id)] = playlist;
  }
}

class SqliteVideoMetadataCache
    with _EphemeralStreamCache
    implements VideoMetadataCache {
  SqliteVideoMetadataCache(this._database);

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

mixin _EphemeralStreamCache {
  static const _streamCacheLifetime = Duration(seconds: 60);
  static const _expirySafetyMargin = Duration(seconds: 30);

  final Map<String, _CachedStreams> _streams = {};
  final Map<String, Future<List<MediaStreamInfo>>> _pendingLoads = {};

  Future<List<MediaStreamInfo>> getOrLoadStreams(
    VideoSourceKind source,
    String id,
    Future<List<MediaStreamInfo>> Function() load,
  ) async {
    final key = '${source.name}:$id';
    final now = DateTime.now();
    final cached = _streams[key];
    if (cached != null && cached.validUntil.isAfter(now)) {
      return cached.streams;
    }

    final pending = _pendingLoads[key];
    if (pending != null) return pending;

    final request = load();
    _pendingLoads[key] = request;
    try {
      final streams = await request;
      final expiryTimes = streams
          .map((stream) => stream.expiresAt)
          .whereType<DateTime>()
          .toList(growable: false);
      var validUntil = now.add(_streamCacheLifetime);
      if (expiryTimes.isNotEmpty) {
        final earliestExpiry = expiryTimes.reduce(
          (left, right) => left.isBefore(right) ? left : right,
        );
        final safeExpiry = earliestExpiry.subtract(_expirySafetyMargin);
        if (safeExpiry.isBefore(validUntil)) validUntil = safeExpiry;
      }
      if (validUntil.isAfter(DateTime.now())) {
        _streams[key] = _CachedStreams(streams, validUntil);
      }
      return streams;
    } finally {
      if (identical(_pendingLoads[key], request)) {
        _pendingLoads.remove(key);
      }
    }
  }
}

class _CachedStreams {
  const _CachedStreams(this.streams, this.validUntil);

  final List<MediaStreamInfo> streams;
  final DateTime validUntil;
}
