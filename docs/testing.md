# Testing

Run commands from the project root.

## Flutter checks

```powershell
flutter analyze
flutter test
flutter build web
```

## Android checks

The Android app is configured for ARM64 devices only. Build its profile APK
with:

```powershell
flutter build apk --profile --target-platform android-arm64
```

Use the Kotlin incremental setting shown below when the local Gradle build
fails while it closes Kotlin incremental caches:

```powershell
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.incremental=false'
flutter build apk --debug
```

Run Android unit tests with:

```powershell
.\android\gradlew.bat -p android testDebugUnitTest
```

The release command is:

```powershell
flutter build apk --release
```

The current release build reports missing `java.beans` classes from Rhino
during R8 processing. The release APK is not verified. Do not silence the
warning without reviewing the dependency and generated R8 rules.

## Existing tests

- `test/architecture/mock_mode_test.dart` checks repository registration and
  basic in-memory create, read, and delete behavior.
- `test/widget_test.dart` checks navigation and user flows, including
  roadmaps and recent history.
- `test/media/playback_controller_test.dart` checks playback controller
  behavior.
- `test/media/player_features_test.dart` checks playlist saving, note saving,
  stream selection, player controls, and fullscreen behavior.
- `test/media/newpipe_youtube_adapter_test.dart` checks the NewPipe adapter.
- `test/media/mit_ocw_adapter_test.dart` checks MIT page and media parsing.
- `test/media/source_detector_test.dart` and
  `test/media/stream_selector_test.dart` check URL detection and stream rules.
- `test/media/video_metadata_cache_test.dart` checks metadata caching.
- `test/core/shared_youtube_link_test.dart` checks shared-link parsing.
- `test/database/sqlite_repositories_test.dart` checks SQLite repositories,
  reopen behavior, and migration behavior.
- `android/app/src/test/kotlin/com/voyager/voyager_learning/AudioTrackSelectionTest.kt`
  checks audio-track selection.

## Platform limits

A Web build checks Web compilation. It does not test Android plugins,
SQLite, or native playback. Automated tests do not prove live provider
availability. Test live extraction and playback on a physical Android device
before release.
