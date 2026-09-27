# Testing and Validation

## Commands

Run from the project root:

```powershell
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Existing coverage

- `test/architecture/mock_mode_test.dart` checks central mock registrations,
  repository create/read/delete behavior, and media/player/policy/storage
  contracts.
- `test/widget_test.dart` checks the Home-to-player flow and primary
  navigation/showcase. The Home/player flow constrains the viewport to a
  360-by-800 phone-sized display.

## Platform validation

- Chrome: web target has been enabled and `flutter build web` has passed.
  Browser testing checks presentation and navigation, not Android-specific
  plugins.
- Android: a debug APK build has passed for the initial UI prototype. Repeat
  after plugin, database, or platform integration changes.
- No automated migration, durable storage, or real playback tests exist yet.

## Testing rules

- Test domain behavior independently from Flutter widgets.
- Test adapters against their repository/service contract.
- Keep mocks deterministic and avoid network access in default tests.
- Add restart/migration tests when SQLite and device storage are implemented.
- Test error, empty, loading, unavailable, and accessibility states as features
  become connected.
