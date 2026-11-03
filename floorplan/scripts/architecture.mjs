const componentDefinitions = [
  {
    id: 'runtime',
    parentId: 'app',
    name: 'Startup & dependency wiring',
    kind: 'infrastructure',
    path: 'lib/main.dart',
    summary: 'Initializes Flutter, registers app services, loads settings, and creates the root app shell.',
    developerSummary: 'The composition root configures GetIt, resolves initial settings, and constructs VoyagerApp/AppShell.',
    status: 'Implemented',
    evidence: ['lib/main.dart', 'lib/core/di/service_locator.dart'],
  },
  {
    id: 'feature-home',
    parentId: 'app',
    name: 'Home & navigation',
    kind: 'ui',
    path: 'lib/features/home/',
    summary: 'Hosts the main tabs and opens the app’s library, history, progress, bookmarks, profile, and player flows.',
    developerSummary: 'AppShell owns tab selection and routes secondary screens through Navigator/MaterialPageRoute.',
    status: 'Implemented',
    evidence: ['lib/features/home/presentation/app_shell.dart'],
  },
  {
    id: 'feature-roadmap',
    parentId: 'app',
    name: 'Roadmaps',
    kind: 'domain',
    path: 'lib/features/roadmap/',
    summary: 'Creates and edits roadmaps and their learning topics through a repository contract.',
    developerSummary: 'RoadmapsPage uses RoadmapRepository for roadmap/topic CRUD and completion confirmation.',
    status: 'Implemented',
    evidence: ['lib/features/roadmap/domain/roadmap_repository.dart', 'lib/features/roadmap/presentation/roadmaps_page.dart'],
  },
  {
    id: 'feature-library',
    parentId: 'app',
    name: 'Learning library',
    kind: 'data',
    path: 'lib/features/library/',
    summary: 'Stores saved videos and playlists and opens playlist entries in the learning player.',
    developerSummary: 'The library contract has SQLite and in-memory implementations; screens save and resolve content through it.',
    status: 'Implemented',
    evidence: ['lib/features/library/domain/learning_library_repository.dart', 'lib/features/library/presentation/playlist_detail_page.dart'],
  },
  {
    id: 'feature-notes',
    parentId: 'app',
    name: 'Study notes',
    kind: 'data',
    path: 'lib/features/notes/',
    summary: 'Creates, edits, organizes, and retrieves local study notes, including timestamped notes and embedded images.',
    developerSummary: 'NotesRepository is used by NotesHomePage, NoteEditorPage, and the player; images are stored as local files on IO platforms and inline data URLs in Web notes.',
    status: 'Implemented',
    evidence: ['lib/features/notes/domain/notes_repository.dart', 'lib/features/notes/presentation/note_editor_page.dart'],
    notes: [
      'Image embeds are implemented: IO platforms save image files under the application documents directory; Web stores image data URLs with browser-local notes.',
      'This does not imply support for arbitrary file attachments.',
    ],
  },
  {
    id: 'feature-progress',
    parentId: 'app',
    name: 'Progress & bookmarks',
    kind: 'data',
    path: 'lib/features/progress/',
    summary: 'Saves playback progress and completion and lists or removes saved playback moments.',
    developerSummary: 'ProgressRepository has SQLite/in-memory implementations; player writes progress, but no active player call creates bookmarks.',
    status: 'Partial',
    evidence: ['lib/features/progress/domain/progress_repository.dart', 'lib/features/home/presentation/app_shell.dart'],
    notes: ['Bookmark listing/deletion is wired in the home shell; no saveBookmark call is present in the current player screen.'],
  },
  {
    id: 'feature-history',
    parentId: 'app',
    name: 'Recent watch history',
    kind: 'data',
    path: 'lib/features/history/',
    summary: 'Records recently loaded lessons and presents the recent list from Home.',
    developerSummary: 'RecentWatchHistoryRepository is injected into the player and read by the home history page.',
    status: 'Implemented',
    evidence: ['lib/features/history/domain/recent_watch_history_repository.dart', 'lib/features/player/presentation/learning_player_screen.dart'],
  },
  {
    id: 'feature-goals',
    parentId: 'app',
    name: 'Daily goals',
    kind: 'data',
    path: 'lib/features/goals/',
    summary: 'Tracks today’s eligible playback time and manually completed lessons against local goals.',
    developerSummary: 'DailyGoalRepository is registered centrally, updated by player activity/completion, and read by Home/Settings.',
    status: 'Implemented',
    evidence: ['lib/features/goals/domain/daily_goal_repository.dart', 'lib/features/player/presentation/learning_player_screen.dart'],
  },
  {
    id: 'feature-watch-activity',
    parentId: 'app',
    name: 'Watch activity & streaks',
    kind: 'domain',
    path: 'lib/features/watch_activity/',
    summary: 'Accumulates eligible watch time by local date and calculates streaks and activity summaries.',
    developerSummary: 'WatchActivityTracker consumes player snapshots; repositories persist date-keyed totals and WatchStreakCalculator derives streaks.',
    status: 'Implemented',
    evidence: ['lib/features/watch_activity/domain/watch_activity_tracker.dart', 'lib/features/watch_activity/domain/watch_streak_calculator.dart'],
  },
  {
    id: 'feature-profile',
    parentId: 'app',
    name: 'Local profile',
    kind: 'data',
    path: 'lib/features/profile/',
    summary: 'Stores a local display name and username and shows watch activity; there is no cloud account.',
    developerSummary: 'ProfilePage composes LocalProfileRepository with WatchActivityRepository and WatchStreakCalculator.',
    status: 'Implemented',
    evidence: ['lib/features/profile/domain/local_profile_repository.dart', 'lib/features/profile/presentation/profile_page.dart'],
  },
  {
    id: 'feature-settings',
    parentId: 'app',
    name: 'Settings',
    kind: 'configuration',
    path: 'lib/features/settings/',
    summary: 'Persists appearance, playback, resume, completion-confirmation, and daily-goal preferences locally.',
    developerSummary: 'SettingsRepository is loaded before runApp and updated by the settings screen through VoyagerApp.',
    status: 'Implemented',
    evidence: ['lib/features/settings/domain/settings_repository.dart', 'lib/main.dart'],
  },
  {
    id: 'feature-player',
    parentId: 'app',
    name: 'Learning player',
    kind: 'ui',
    path: 'lib/features/player/',
    summary: 'Connects lesson loading, playback controls, note saving, history, progress, and eligible watch-time tracking.',
    developerSummary: 'LearningPlayerScreen is the UI boundary around PlaybackController and injected repository contracts.',
    status: 'Implemented',
    evidence: ['lib/features/player/presentation/learning_player_screen.dart'],
  },
  {
    id: 'media',
    parentId: 'app',
    name: 'Media source & playback',
    kind: 'infrastructure',
    path: 'lib/core/media/',
    summary: 'Recognizes supported links, resolves YouTube/OCW content, selects streams, and drives the platform player.',
    developerSummary: 'DefaultPlaybackController composes SourceDetector, VideoSourceRegistry, adapters, StreamSelectionPolicy, cache, and MediaPlayer.',
    status: 'Implemented',
    evidence: ['lib/core/media/playback_controller.dart', 'lib/core/media/source_detector.dart', 'lib/core/media/video_source_registry.dart'],
    external: ['YouTube', 'MIT OpenCourseWare'],
  },
  {
    id: 'persistence',
    parentId: 'app',
    name: 'SQLite & persistence',
    kind: 'data',
    path: 'lib/core/database/',
    summary: 'Provides the app-owned database contract and SQLite schema/migrations used by local repositories.',
    developerSummary: 'AppDatabase abstracts sqflite; SqfliteAppDatabase owns schema version 7, migrations, indexes, and transactions.',
    status: 'Implemented',
    evidence: ['lib/core/database/database.dart'],
    external: ['SQLite'],
  },
  {
    id: 'design',
    parentId: 'app',
    name: 'Design system',
    kind: 'ui',
    path: 'lib/core/design/',
    summary: 'Defines shared colors, typography, themes, reusable controls, and a debug showcase.',
    developerSummary: 'DesignTokens feeds AppTheme and shared controls; DesignSystemShowcase is opened only in debug builds.',
    status: 'Implemented',
    evidence: ['lib/core/design/design_tokens.dart', 'lib/core/design/app_theme.dart'],
  },
  {
    id: 'sharing',
    parentId: 'app',
    name: 'Shared links',
    kind: 'infrastructure',
    path: 'lib/core/share/',
    summary: 'Parses incoming shared YouTube links and bridges Android share intents into Flutter.',
    developerSummary: 'SharedYoutubeLink validates supported links; AndroidSharedVideoIntentSource consumes the EventChannel contract.',
    status: 'Implemented',
    evidence: ['lib/core/share/shared_youtube_link.dart', 'lib/core/share/shared_video_intent_source.dart'],
  },
  {
    id: 'configuration',
    parentId: 'app',
    name: 'App configuration',
    kind: 'configuration',
    path: 'lib/core/config/',
    summary: 'Reads build-time configuration used to enable or disable supported media extraction.',
    developerSummary: 'AppConfig reads compile-time environment values; it does not define a server or cloud configuration.',
    status: 'Implemented',
    evidence: ['lib/core/config/app_config.dart'],
  },
  {
    id: 'android',
    parentId: 'app',
    name: 'Android platform',
    kind: 'infrastructure',
    path: 'android/',
    summary: 'Implements native Media3 playback, NewPipe extraction, platform channels, and incoming share intents.',
    developerSummary: 'MainActivity registers player/extractor/share channels and a platform view; Gradle adds Media3 and NewPipe.',
    status: 'Implemented',
    evidence: ['android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt', 'android/app/src/main/AndroidManifest.xml'],
    external: ['Android Media3', 'NewPipe Extractor'],
  },
  {
    id: 'web',
    parentId: 'app',
    name: 'Web preview',
    kind: 'infrastructure',
    path: 'web/',
    summary: 'Provides Flutter Web bootstrap assets; repository selection uses in-memory stores on Web by default.',
    developerSummary: 'Web is a Flutter target; this directory does not contain a separate backend or custom web API.',
    status: 'Implemented',
    evidence: ['web/index.html', 'lib/core/di/service_locator.dart'],
  },
  {
    id: 'tests',
    parentId: 'app',
    name: 'Automated tests',
    kind: 'test',
    path: 'test/',
    summary: 'Exercises repository behavior, media rules, app flows, and selected widgets with controlled inputs.',
    developerSummary: 'Flutter tests use fakes/in-memory repositories; live provider extraction and Android device playback are not established by these tests.',
    status: 'Implemented',
    evidence: ['test/architecture/mock_mode_test.dart', 'test/media/playback_controller_test.dart'],
  },
  {
    id: 'project-config',
    parentId: 'app',
    name: 'Project configuration & docs',
    kind: 'configuration',
    path: '',
    summary: 'Holds package/platform build configuration and explanatory documents; docs can lag behind active source.',
    developerSummary: 'Includes pubspec/analyzer configuration, platform build files, and project documentation. Documentation is not treated as proof of execution.',
    status: 'Verified in part',
    evidence: ['pubspec.yaml', 'analysis_options.yaml'],
    notes: ['docs/development-roadmap.md conflicts with currently wired progress/settings flows; source and tests are treated as authoritative.'],
  },
];

const workflows = [
  {
    id: 'startup',
    name: 'Application startup',
    summary: 'Flutter initializes, repositories and media services are registered, saved settings are loaded, and the app shell is shown.',
    status: 'Implemented',
    steps: [
      { title: 'Initialize Flutter', simple: 'Prepare Flutter before the app uses plugins.', developer: 'main() calls WidgetsFlutterBinding.ensureInitialized().', filePaths: ['lib/main.dart'], componentIds: ['runtime'] },
      { title: 'Register services', simple: 'Choose app storage and create the media services the screens will use.', developer: 'configureDependencies() registers in-memory or SQLite repositories and a PlaybackController factory in GetIt.', filePaths: ['lib/core/di/service_locator.dart'], componentIds: ['runtime', 'persistence', 'media'] },
      { title: 'Load settings', simple: 'Read the saved appearance and playback preferences.', developer: 'main() resolves SettingsRepository and awaits getSettings() before runApp.', filePaths: ['lib/main.dart', 'lib/features/settings/domain/settings_repository.dart'], componentIds: ['runtime', 'feature-settings'] },
      { title: 'Build the UI', simple: 'Show VoyagerApp and its main navigation shell.', developer: 'VoyagerApp builds MaterialApp and AppShell with the selected settings and repositories.', filePaths: ['lib/main.dart', 'lib/features/home/presentation/app_shell.dart'], componentIds: ['runtime', 'feature-home', 'design'] },
    ],
  },
  {
    id: 'storage-selection',
    name: 'Select local storage',
    summary: 'The composition root chooses in-memory repositories for Web/mock mode and SQLite otherwise.',
    status: 'Implemented',
    steps: [
      { title: 'Choose mode', simple: 'Web uses temporary in-memory data by default; tests can request the same mode.', developer: 'shouldUseMocks is useMocks ?? kIsWeb; this is not a blanket “all non-Android is Web” check.', filePaths: ['lib/core/di/service_locator.dart'], componentIds: ['runtime', 'web'] },
      { title: 'Register store implementations', simple: 'The app connects each repository contract to an in-memory or SQLite implementation.', developer: 'GetIt registrations pair feature repository interfaces with implementations; SQLite initialization is skipped in mock mode.', filePaths: ['lib/core/di/service_locator.dart'], componentIds: ['runtime', 'feature-roadmap', 'feature-library', 'feature-notes', 'feature-progress', 'feature-settings', 'feature-history', 'feature-goals', 'feature-watch-activity', 'feature-profile', 'persistence'] },
      { title: 'Initialize SQLite when selected', simple: 'The SQLite branch opens the versioned local database.', developer: 'SqfliteAppDatabase.initialize() opens the v7 database with foreign keys enabled and upgrade callbacks.', filePaths: ['lib/core/database/database.dart'], componentIds: ['persistence'] },
    ],
  },
  {
    id: 'roadmap',
    name: 'Open roadmaps',
    summary: 'The main shell shows RoadmapsPage with the roadmap repository selected during app setup.',
    status: 'Implemented',
    steps: [
      { title: 'Select Roadmaps', simple: 'Choose the Roadmaps tab in the main navigation.', developer: 'AppShell selects RoadmapsPage in the tab list and passes its repository and completion setting.', filePaths: ['lib/features/home/presentation/app_shell.dart'], componentIds: ['feature-home', 'feature-roadmap'] },
      { title: 'Read or update topics', simple: 'The page loads roadmaps and saves topic changes through its repository.', developer: 'RoadmapsPage calls RoadmapRepository; it does not issue SQLite queries directly.', filePaths: ['lib/features/roadmap/presentation/roadmaps_page.dart', 'lib/features/roadmap/domain/roadmap_repository.dart'], componentIds: ['feature-roadmap'] },
      { title: 'Persist through the selected implementation', simple: 'The selected repository stores changes in memory or SQLite.', developer: 'The composition root registers InMemoryRoadmapRepository or SqliteRoadmapRepository backed by AppDatabase.', filePaths: ['lib/core/di/service_locator.dart', 'lib/features/roadmap/data/sqlite_roadmap_repository.dart', 'lib/features/roadmap/data/in_memory_roadmap_repository.dart'], componentIds: ['runtime', 'feature-roadmap', 'persistence'] },
    ],
  },
  {
    id: 'save-playlist',
    name: 'Save a playlist',
    summary: 'The player resolves playlist metadata and entries, then saves them via the learning-library contract.',
    status: 'Implemented',
    steps: [
      { title: 'Load playlist source', simple: 'Paste or open a supported playlist link in the player.', developer: 'LearningPlayerScreen delegates source loading to PlaybackController and handles PlaylistInfo.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/core/media/playback_controller.dart'], componentIds: ['feature-player', 'media'] },
      { title: 'Resolve entries', simple: 'The selected adapter turns the provider response into app-owned playlist and video models.', developer: 'The source registry selects an adapter; platform-specific extraction is hidden behind VideoSourceAdapter.', filePaths: ['lib/core/media/video_source_registry.dart', 'lib/core/media/video_source_adapter.dart', 'lib/core/media/newpipe_youtube_adapter.dart'], componentIds: ['media', 'android'] },
      { title: 'Save library records', simple: 'The player writes the playlist, its videos, and their order through the library repository.', developer: 'The player calls LearningLibraryRepository methods; the selected implementation stores the playlist and ordered entries.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/features/library/domain/learning_library_repository.dart', 'lib/features/library/data/sqlite_learning_library_repository.dart'], componentIds: ['feature-player', 'feature-library', 'persistence'] },
    ],
  },
  {
    id: 'play-video',
    name: 'Load and play a lesson',
    summary: 'A supported YouTube or MIT OCW URL is identified, resolved, converted into a selected stream, and sent to a platform player.',
    status: 'Implemented',
    steps: [
      { title: 'Accept a supported link', simple: 'The player checks the pasted link and recognizes supported YouTube or MIT OCW sources.', developer: 'LearningPlayerScreen calls DefaultPlaybackController; SourceDetector validates the URL and produces a SourceDescriptor.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/core/media/source_detector.dart'], componentIds: ['feature-player', 'media'] },
      { title: 'Select a provider adapter', simple: 'The registry chooses the adapter that understands this source.', developer: 'VideoSourceRegistry selects NewPipeYoutubeAdapter or MitOcwAdapter through VideoSourceAdapter.', filePaths: ['lib/core/media/video_source_registry.dart', 'lib/core/media/newpipe_youtube_adapter.dart', 'lib/core/media/mit_ocw_adapter.dart'], componentIds: ['media', 'android'] },
      { title: 'Choose a playable stream', simple: 'The app picks a supported stream with the required audio/video tracks.', developer: 'StreamSelectionPolicy filters supported MIME types/resolution and PlaybackController requests stream replacement when needed.', filePaths: ['lib/core/media/stream_selector.dart', 'lib/core/media/playback_controller.dart'], componentIds: ['media'] },
      { title: 'Start platform playback', simple: 'Android uses the native Media3 player; other configured targets use video_player.', developer: 'service_locator selects AndroidMediaPlayer only for Android outside mock mode; otherwise it creates FlutterMediaPlayer.', filePaths: ['lib/core/di/service_locator.dart', 'lib/core/media/android_media_player.dart', 'lib/core/media/media_player.dart', 'android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt'], componentIds: ['runtime', 'media', 'android'] },
      { title: 'Record stable learning activity', simple: 'The player records loaded-video history and eligible playback totals, not temporary media URLs.', developer: 'LearningPlayerScreen writes RecentWatchHistoryRepository and WatchActivityTracker data; metadata cache keeps stable details.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/features/history/domain/recent_watch_history_repository.dart', 'lib/features/watch_activity/domain/watch_activity_tracker.dart', 'lib/core/media/video_metadata_cache.dart'], componentIds: ['feature-player', 'feature-history', 'feature-watch-activity', 'media'] },
    ],
  },
  {
    id: 'save-note',
    name: 'Save a timestamped note',
    summary: 'A player note is linked to the active video and playback position, then written through NotesRepository.',
    status: 'Implemented',
    steps: [
      { title: 'Capture the current lesson', simple: 'The note editor receives the active video and the current playback time.', developer: 'LearningPlayerScreen prepares a StudyNote with videoId and timestampSeconds.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/features/notes/domain/study_note.dart'], componentIds: ['feature-player', 'feature-notes'] },
      { title: 'Save through the note contract', simple: 'The player asks NotesRepository to save the note.', developer: 'The player calls NotesRepository; it does not write SQL directly.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/features/notes/domain/notes_repository.dart'], componentIds: ['feature-player', 'feature-notes'] },
      { title: 'Persist locally', simple: 'The selected notes store saves the note on device or in the current in-memory store.', developer: 'DI selects SQLite, in-memory, or browser-backed note storage according to platform/mode.', filePaths: ['lib/core/di/service_locator.dart', 'lib/features/notes/data/sqlite_notes_repository.dart', 'lib/features/notes/data/in_memory_notes_repository.dart', 'lib/features/notes/data/browser_note_storage_web.dart'], componentIds: ['runtime', 'feature-notes', 'persistence', 'web'] },
    ],
  },
  {
    id: 'note-image',
    name: 'Insert an image in a note',
    summary: 'The note editor embeds a picked image; storage differs between IO platforms and Web.',
    status: 'Implemented',
    steps: [
      { title: 'Choose an image', simple: 'The note editor opens the system image picker.', developer: 'NoteEditorPage._insertImage() asks NoteImageStore to pick an image from the gallery.', filePaths: ['lib/features/notes/presentation/note_editor_page.dart', 'lib/features/notes/data/note_image_store.dart'], componentIds: ['feature-notes'] },
      { title: 'Store for the current platform', simple: 'Web embeds the image data in the note; other IO platforms write a file in app documents.', developer: 'NoteImageStore returns a data URL for Web and delegates to the IO implementation, which writes under notes/images and returns that local path.', filePaths: ['lib/features/notes/data/note_image_store.dart', 'lib/features/notes/data/note_image_store_io.dart', 'lib/features/notes/data/note_image_store_stub.dart'], componentIds: ['feature-notes', 'web'] },
      { title: 'Save the note and its image reference', simple: 'The note repository stores the editor document locally; unused IO image files are cleaned after note changes.', developer: 'The note Delta is saved through NotesRepository. IO cleanup retains referenced file paths and deletes unreferenced files; Web data URLs are stored with browser-backed notes.', filePaths: ['lib/features/notes/presentation/note_editor_page.dart', 'lib/features/notes/domain/notes_repository.dart', 'lib/features/notes/data/sqlite_notes_repository.dart', 'lib/features/notes/data/browser_note_storage_web.dart', 'lib/features/notes/data/note_image_store_io.dart'], componentIds: ['feature-notes', 'persistence', 'web'] },
    ],
  },
  {
    id: 'progress',
    name: 'Save playback progress',
    summary: 'The player saves the current position and completion state, and Home can reopen an incomplete lesson.',
    status: 'Implemented',
    steps: [
      { title: 'Observe lesson position', simple: 'The player reads the playback position while the lesson is open.', developer: 'LearningPlayerScreen calls PlaybackController.currentPosition and saves LearningProgress during activity flush/cleanup.', filePaths: ['lib/features/player/presentation/learning_player_screen.dart', 'lib/core/media/playback_controller.dart'], componentIds: ['feature-player', 'media'] },
      { title: 'Store progress through its contract', simple: 'The progress repository saves the position and completion state.', developer: 'ProgressRepository abstracts SQLite and in-memory stores; metadata is stored so progress has a stable video record.', filePaths: ['lib/features/progress/domain/progress_repository.dart', 'lib/features/progress/data/sqlite_progress_repository.dart', 'lib/features/library/domain/learning_library_repository.dart'], componentIds: ['feature-progress', 'feature-library', 'persistence'] },
      { title: 'Resume from Home', simple: 'Home opens the saved position without starting playback automatically.', developer: 'AppShell resolves the latest incomplete LearningProgress and opens LearningPlayerScreen with initialPosition.', filePaths: ['lib/features/home/presentation/app_shell.dart', 'lib/features/player/presentation/learning_player_screen.dart'], componentIds: ['feature-home', 'feature-player', 'feature-progress'] },
    ],
  },
  {
    id: 'bookmarks',
    name: 'Browse bookmarks (creation is not wired)',
    summary: 'The app can list, open, and delete existing bookmarks; the current player has no active call that creates one.',
    status: 'Partial',
    steps: [
      { title: 'Read bookmark records', simple: 'The Home bookmark page reads saved moments from ProgressRepository.', developer: 'AppShell._BookmarksPageState queries getAllBookmarks and joins each record with library video metadata.', filePaths: ['lib/features/home/presentation/app_shell.dart', 'lib/features/progress/domain/progress_repository.dart'], componentIds: ['feature-home', 'feature-progress', 'feature-library'] },
      { title: 'Open or delete a moment', simple: 'Selecting a record reopens its saved time; the delete action removes it.', developer: 'The screen passes initialPosition to the player and calls deleteBookmark; no saveBookmark call is wired in the current player.', filePaths: ['lib/features/home/presentation/app_shell.dart', 'lib/features/player/presentation/learning_player_screen.dart'], componentIds: ['feature-home', 'feature-player', 'feature-progress'] },
    ],
  },
];

const packageLabels = {
  cupertino_icons: 'Cupertino Icons',
  get_it: 'GetIt',
  sqflite: 'sqflite',
  path_provider: 'Path Provider',
  path: 'Path',
  html: 'HTML parser',
  http: 'HTTP client',
  video_player: 'video_player',
  youtube_explode_dart: 'youtube_explode_dart',
  flutter_quill: 'Flutter Quill',
  flutter_quill_extensions: 'Flutter Quill extensions',
  flutter_highlight: 'Flutter Highlight',
  image_picker: 'Image Picker',
  highlight: 'Highlight',
  web: 'Web interop',
  flutter_lints: 'Flutter lints',
  sqflite_common_ffi: 'sqflite FFI',
};

function moduleForPath(filePath) {
  if (filePath === 'lib/main.dart' || filePath.startsWith('lib/core/di/')) return 'runtime';
  if (filePath.startsWith('lib/features/home/')) return 'feature-home';
  const feature = filePath.match(/^lib\/features\/([^/]+)\//u)?.[1];
  if (feature) return `feature-${feature.replaceAll('_', '-')}`;
  if (filePath.startsWith('lib/core/database/')) return 'persistence';
  if (filePath.startsWith('lib/core/media/')) return 'media';
  if (filePath.startsWith('lib/core/design/')) return 'design';
  if (filePath.startsWith('lib/core/share/')) return 'sharing';
  if (filePath.startsWith('lib/core/config/')) return 'configuration';
  if (filePath.startsWith('android/')) return 'android';
  if (filePath.startsWith('web/')) return 'web';
  if (filePath.startsWith('test/')) return 'tests';
  return 'project-config';
}

export function getComponentDefinitions() {
  return componentDefinitions;
}

export function getWorkflows() {
  return workflows;
}

export function getPackageLabel(packageName) {
  return packageLabels[packageName] ?? packageName;
}

export function getModuleForPath(filePath) {
  const id = moduleForPath(filePath);
  return componentDefinitions.some((component) => component.id === id) ? id : 'project-config';
}
