import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

import '../../core/database/database.dart';
import '../../features/library/data/in_memory_learning_library_repository.dart';
import '../../features/library/data/sqlite_learning_library_repository.dart';
import '../../features/library/domain/learning_library_repository.dart';
import '../../features/history/data/in_memory_recent_watch_history_repository.dart';
import '../../features/history/data/sqlite_recent_watch_history_repository.dart';
import '../../features/history/domain/recent_watch_history_repository.dart';
import '../../features/goals/data/in_memory_daily_goal_repository.dart';
import '../../features/goals/data/sqlite_daily_goal_repository.dart';
import '../../features/goals/domain/daily_goal_repository.dart';
import '../../features/notes/data/in_memory_notes_repository.dart';
import '../../features/notes/data/sqlite_notes_repository.dart';
import '../../features/notes/domain/notes_repository.dart';
import '../../features/progress/data/in_memory_progress_repository.dart';
import '../../features/progress/data/sqlite_progress_repository.dart';
import '../../features/progress/domain/progress_repository.dart';
import '../../features/roadmap/data/in_memory_roadmap_repository.dart';
import '../../features/roadmap/data/sqlite_roadmap_repository.dart';
import '../../features/roadmap/domain/roadmap_repository.dart';
import '../../features/settings/data/in_memory_settings_repository.dart';
import '../../features/settings/data/sqlite_settings_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../config/app_config.dart';
import '../media/media_player.dart';
import '../media/android_media_player.dart';
import '../media/mit_ocw_adapter.dart';
import '../media/playback_controller.dart';
import '../media/stream_selector.dart';
import '../media/video_metadata_cache.dart';
import '../media/newpipe_youtube_adapter.dart';
import '../media/video_source_registry.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({bool? useMocks}) async {
  final shouldUseMocks = useMocks ?? kIsWeb;
  if (shouldUseMocks) {
    _registerIfMissing<RoadmapRepository>(InMemoryRoadmapRepository.new);
    _registerIfMissing<LearningLibraryRepository>(
      InMemoryLearningLibraryRepository.new,
    );
    _registerIfMissing<NotesRepository>(InMemoryNotesRepository.new);
    _registerIfMissing<ProgressRepository>(InMemoryProgressRepository.new);
    _registerIfMissing<SettingsRepository>(InMemorySettingsRepository.new);
    _registerIfMissing<RecentWatchHistoryRepository>(
      InMemoryRecentWatchHistoryRepository.new,
    );
    _registerIfMissing<DailyGoalRepository>(InMemoryDailyGoalRepository.new);
  } else if (!serviceLocator.isRegistered<AppDatabase>()) {
    final database = SqfliteAppDatabase();
    await database.initialize();
    serviceLocator.registerSingleton<AppDatabase>(
      database,
      dispose: (instance) => instance.close(),
    );
    serviceLocator.registerLazySingleton<RoadmapRepository>(
      () => SqliteRoadmapRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<LearningLibraryRepository>(
      () => SqliteLearningLibraryRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<NotesRepository>(
      () => SqliteNotesRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<ProgressRepository>(
      () => SqliteProgressRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<SettingsRepository>(
      () => SqliteSettingsRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<RecentWatchHistoryRepository>(
      () => SqliteRecentWatchHistoryRepository(serviceLocator<AppDatabase>()),
    );
    serviceLocator.registerLazySingleton<DailyGoalRepository>(
      () => SqliteDailyGoalRepository(serviceLocator<AppDatabase>()),
    );
  }
  _registerIfMissing<AppConfig>(() => AppConfig.fromEnvironment);
  _registerIfMissing<VideoMetadataCache>(
    shouldUseMocks
        ? InMemoryVideoMetadataCache.new
        : () => SqliteVideoMetadataCache(serviceLocator<AppDatabase>()),
  );
  if (!serviceLocator.isRegistered<PlaybackController>()) {
    serviceLocator.registerFactory<PlaybackController>(
      () => DefaultPlaybackController(
        sources: VideoSourceRegistry([
          NewPipeYoutubeAdapter(),
          MitOcwAdapter(),
        ]),
        metadataCache: serviceLocator<VideoMetadataCache>(),
        mediaPlayer:
            !shouldUseMocks &&
                !kIsWeb &&
                defaultTargetPlatform == TargetPlatform.android
            ? AndroidMediaPlayer()
            : FlutterMediaPlayer(),
        streamPolicy: const StreamSelectionPolicy(
          supportedMimeTypes: {'video/mp4', 'video/webm'},
          maxResolutionHeight: 1080,
          networkQuality: NetworkQuality.fast,
        ),
        config: serviceLocator<AppConfig>(),
      ),
    );
  }
}

void _registerIfMissing<T extends Object>(T Function() create) {
  if (!serviceLocator.isRegistered<T>()) {
    serviceLocator.registerLazySingleton<T>(create);
  }
}
