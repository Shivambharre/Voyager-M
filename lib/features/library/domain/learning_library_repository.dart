import 'learning_content.dart';

abstract interface class LearningLibraryRepository {
  Future<List<LearningVideo>> getVideos();
  Future<LearningVideo?> getVideo(String id);
  Future<void> saveVideo(LearningVideo video);
  Future<void> deleteVideo(String id);

  Future<List<LearningPlaylist>> getPlaylists();
  Future<LearningPlaylist?> getPlaylist(String id);
  Future<void> savePlaylist(LearningPlaylist playlist);
  Future<void> deletePlaylist(String id);

  Future<List<PlaylistEntry>> getPlaylistEntries(String playlistId);
  Future<void> savePlaylistEntries(
    String playlistId,
    List<PlaylistEntry> entries,
  );
}
