# Testing and Validation

## Commands

Run from the project root:

```powershell
flutter analyze
flutter test
flutter build web
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.incremental=false'
flutter build apk --debug
```

## Existing coverage

- `test/architecture/mock_mode_test.dart` checks repository registration and
  in-memory repository create/read/delete behavior.
- `test/widget_test.dart` checks the Home-to-player flow and primary
  navigation/showcase, plus roadmap create/edit/topic-status/progress/delete
  flows and opening recent watch history. The Home/player flow constrains the
  viewport to a 360-by-800 phone-sized display.
- `test/media/player_features_test.dart` covers playlist saving, note saving,
  available quality switching, controls fading on compact and fullscreen
  layouts, and exiting fullscreen via its control or system Back.

## Platform validation

- Chrome: web target has been enabled and `flutter build web` has passed.
  Browser testing checks presentation and navigation, not Android-specific
  plugins.
- Android: a debug APK build passed after YouTube platform integration. On
  this Windows workspace, set `GRADLE_OPTS` as shown above to work around
  Kotlin incremental compilation. Repeat after plugin, database, or platform
  integration changes.
- No live upstream extraction or physical-device playback tests exist yet.

## Testing rules

- Test domain behavior independently from Flutter widgets.
- Test adapters against their repository/service contract.
- Keep repository fakes deterministic and avoid network access in default tests.
- Add restart/migration tests when SQLite schemas or repositories change.
- Test error, empty, loading, unavailable, and accessibility states as features
  become connected.
