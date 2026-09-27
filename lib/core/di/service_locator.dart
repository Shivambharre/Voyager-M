import 'package:get_it/get_it.dart';

import '../../features/library/data/in_memory_learning_library_repository.dart';
import '../../features/library/domain/learning_library_repository.dart';
import '../../features/notes/data/in_memory_notes_repository.dart';
import '../../features/notes/domain/notes_repository.dart';
import '../../features/progress/data/in_memory_progress_repository.dart';
import '../../features/progress/domain/progress_repository.dart';
import '../../features/roadmap/domain/roadmap_repository.dart';
import '../../features/settings/data/in_memory_settings_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../filtering/content_policy.dart';
import '../media/media_provider.dart';
import '../media/player_engine.dart';
import '../storage/local_file_storage.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies() async {
  _registerIfMissing<RoadmapRepository>(InMemoryRoadmapRepository.new);
  _registerIfMissing<LearningLibraryRepository>(
    InMemoryLearningLibraryRepository.new,
  );
  _registerIfMissing<NotesRepository>(InMemoryNotesRepository.new);
  _registerIfMissing<ProgressRepository>(InMemoryProgressRepository.new);
  _registerIfMissing<SettingsRepository>(InMemorySettingsRepository.new);
  _registerIfMissing<MediaProvider>(MockMediaProvider.new);
  _registerIfMissing<PlayerEngine>(MockPlayerEngine.new);
  _registerIfMissing<ContentPolicy>(LearningContentPolicy.new);
  _registerIfMissing<LocalFileStorage>(InMemoryFileStorage.new);
}

void _registerIfMissing<T extends Object>(T Function() create) {
  if (!serviceLocator.isRegistered<T>()) {
    serviceLocator.registerLazySingleton<T>(create);
  }
}
