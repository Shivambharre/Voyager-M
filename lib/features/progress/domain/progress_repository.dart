import 'learning_progress.dart';

abstract interface class ProgressRepository {
  Future<LearningProgress?> getProgress(String videoId);
  Future<void> saveProgress(LearningProgress progress);
  Future<List<LearningBookmark>> getBookmarks(String videoId);
  Future<void> saveBookmark(LearningBookmark bookmark);
  Future<void> deleteBookmark(String id);
}
