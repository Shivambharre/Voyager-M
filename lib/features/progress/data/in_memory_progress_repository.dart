import '../domain/learning_progress.dart';
import '../domain/progress_repository.dart';

class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, LearningProgress> _progressByVideo = {};
  final Map<String, LearningBookmark> _bookmarksById = {};

  @override
  Future<LearningProgress?> getProgress(String videoId) async =>
      _progressByVideo[videoId];

  @override
  Future<List<LearningProgress>> getAllProgress() async {
    final progress = _progressByVideo.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return List.unmodifiable(progress);
  }

  @override
  Future<void> saveProgress(LearningProgress progress) async {
    _progressByVideo[progress.videoId] = progress;
  }

  @override
  Future<List<LearningBookmark>> getBookmarks(String videoId) async {
    final bookmarks =
        _bookmarksById.values
            .where((bookmark) => bookmark.videoId == videoId)
            .toList()
          ..sort(
            (first, second) =>
                first.positionSeconds.compareTo(second.positionSeconds),
          );
    return List.unmodifiable(bookmarks);
  }

  @override
  Future<List<LearningBookmark>> getAllBookmarks() async {
    final bookmarks = _bookmarksById.values.toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return List.unmodifiable(bookmarks);
  }

  @override
  Future<void> saveBookmark(LearningBookmark bookmark) async {
    _bookmarksById[bookmark.id] = bookmark;
  }

  @override
  Future<void> deleteBookmark(String id) async {
    _bookmarksById.remove(id);
  }
}
