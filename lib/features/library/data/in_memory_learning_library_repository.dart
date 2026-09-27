import '../domain/learning_content.dart';
import '../domain/learning_library_repository.dart';

class InMemoryLearningLibraryRepository implements LearningLibraryRepository {
  final Map<String, LearningVideo> _videos = {};
  final Map<String, LearningPlaylist> _playlists = {};
  final Map<String, List<PlaylistEntry>> _entries = {};

  @override
  Future<List<LearningVideo>> getVideos() async => List.unmodifiable(_videos.values);

  @override
  Future<LearningVideo?> getVideo(String id) async => _videos[id];

  @override
  Future<void> saveVideo(LearningVideo video) async {
    _videos[video.id] = video;
  }

  @override
  Future<void> deleteVideo(String id) async {
    _videos.remove(id);
    for (final playlistId in _entries.keys.toList()) {
      _entries[playlistId] = _entries[playlistId]!
          .where((entry) => entry.videoId != id)
          .toList();
    }
  }

  @override
  Future<List<LearningPlaylist>> getPlaylists() async =>
      List.unmodifiable(_playlists.values);

  @override
  Future<LearningPlaylist?> getPlaylist(String id) async => _playlists[id];

  @override
  Future<void> savePlaylist(LearningPlaylist playlist) async {
    _playlists[playlist.id] = playlist;
  }

  @override
  Future<void> deletePlaylist(String id) async {
    _playlists.remove(id);
    _entries.remove(id);
  }

  @override
  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId) async =>
      List.unmodifiable(_entries[playlistId] ?? const []);

  @override
  Future<void> savePlaylistEntries(
    String playlistId,
    List<PlaylistEntry> entries,
  ) async {
    if (!_playlists.containsKey(playlistId)) {
      throw StateError('Playlist "$playlistId" does not exist.');
    }
    for (final entry in entries) {
      if (entry.playlistId != playlistId) {
        throw ArgumentError.value(
          entry.playlistId,
          'entries',
          'Every entry must belong to playlist "$playlistId".',
        );
      }
      if (!_videos.containsKey(entry.videoId)) {
        throw StateError('Video "${entry.videoId}" does not exist.');
      }
    }
    _entries[playlistId] = List.of(entries)
      ..sort((first, second) => first.position.compareTo(second.position));
  }
}
