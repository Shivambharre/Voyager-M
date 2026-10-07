import '../../../core/database/database.dart';
import '../domain/learning_content.dart';
import '../domain/learning_library_repository.dart';

class SqliteLearningLibraryRepository implements LearningLibraryRepository {
  const SqliteLearningLibraryRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<LearningVideo>> getVideos() async {
    final rows = await _database.query('videos', orderBy: 'title COLLATE NOCASE');
    return rows.map(_videoFromRow).toList(growable: false);
  }

  @override
  Future<LearningVideo?> getVideo(String id) async {
    final rows = await _database.query('videos', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _videoFromRow(rows.first);
  }

  @override
  Future<void> saveVideo(LearningVideo video) async {
    await _database.upsert('videos', {
      'id': video.id,
      'source_id': video.sourceId,
      'source_url': video.sourceUrl,
      'title': video.title,
      'creator': video.creator,
      'duration_seconds': video.durationSeconds,
      'thumbnail_url': video.thumbnailUrl,
    }, keyWhere: 'id = ?', keyArgs: [video.id]);
  }

  @override
  Future<void> deleteVideo(String id) async {
    await _database.delete('videos', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<LearningPlaylist>> getPlaylists() async {
    final rows = await _database.query(
      'playlists',
      orderBy: 'title COLLATE NOCASE',
    );
    return rows.map(_playlistFromRow).toList(growable: false);
  }

  @override
  Future<LearningPlaylist?> getPlaylist(String id) async {
    final rows = await _database.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : _playlistFromRow(rows.first);
  }

  @override
  Future<void> savePlaylist(LearningPlaylist playlist) async {
    await _database.upsert('playlists', {
      'id': playlist.id,
      'source_id': playlist.sourceId,
      'source_url': playlist.sourceUrl,
      'title': playlist.title,
      'creator': playlist.creator,
      'description': playlist.description,
    }, keyWhere: 'id = ?', keyArgs: [playlist.id]);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _database.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) async {
    final rows = await _database.query(
      'playlist_entries',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position',
    );
    return rows
        .map(
          (row) => PlaylistEntry(
            playlistId: row['playlist_id']! as String,
            videoId: row['video_id']! as String,
            position: row['position']! as int,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> savePlaylistEntries(
    String playlistId,
    List<PlaylistEntry> entries,
  ) async {
    for (final entry in entries) {
      if (entry.playlistId != playlistId) {
        throw ArgumentError.value(
          entry.playlistId,
          'entries',
          'Every entry must belong to playlist "$playlistId".',
        );
      }
    }
    await _database.transaction((transaction) async {
      final playlists = await transaction.query(
        'playlists',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      if (playlists.isEmpty) {
        throw StateError('Playlist "$playlistId" does not exist.');
      }
      await transaction.delete(
        'playlist_entries',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      for (final entry in entries) {
        await transaction.insert('playlist_entries', {
          'playlist_id': playlistId,
          'video_id': entry.videoId,
          'position': entry.position,
        });
      }
    });
  }

  LearningVideo _videoFromRow(Map<String, Object?> row) => LearningVideo(
        id: row['id']! as String,
        sourceId: row['source_id']! as String,
        sourceUrl: row['source_url']! as String,
        title: row['title']! as String,
        creator: row['creator']! as String,
        durationSeconds: row['duration_seconds']! as int,
        thumbnailUrl: row['thumbnail_url'] as String?,
      );

  LearningPlaylist _playlistFromRow(Map<String, Object?> row) =>
      LearningPlaylist(
        id: row['id']! as String,
        sourceId: row['source_id']! as String,
        sourceUrl: row['source_url']! as String,
        title: row['title']! as String,
        creator: row['creator']! as String,
        description: row['description']! as String,
      );
}
