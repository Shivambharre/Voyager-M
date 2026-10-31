# Modules

## App setup

| Location | Responsibility |
| --- | --- |
| `lib/main.dart` | Starts Flutter and builds `VoyagerApp`. |
| `lib/core/di/service_locator.dart` | Selects repositories and creates the playback controller. |

## Core modules

| Module | Responsibility | Current implementation |
| --- | --- | --- |
| `core/design` | Themes, colors, shared controls, and showcase | Active |
| `core/di` | Dependency registration | Active |
| `core/database` | SQLite database and schema | Schema version 3 |
| `core/media` | Source adapters, stream selection, and playback | Active player pipeline |
| `core/share` | Parse shared YouTube links and receive Android intents | Active on Android |

## Feature modules

| Feature | Data and domain | Screen use |
| --- | --- | --- |
| `features/home` | Main app shell and home data | Reads saved playlists, note counts, and watch history. |
| `features/roadmap` | Roadmap and topic contracts and repositories | Roadmap and topic flows are active. |
| `features/library` | Video and playlist models and repositories | Save, display, open, and delete flows are active. |
| `features/notes` | Note models and repositories | Notes screen and player note flows are active. |
| `features/history` | Recent-watch models and repositories | Home and player use recent history. |
| `features/progress` | Progress and bookmark data | Repositories exist, but active screens do not use them. |
| `features/settings` | Settings data and repository | Repository exists. The Settings screen does not persist settings. |
| `features/player` | Player screen | Uses the shared playback controller and repositories. |

## Dependency direction

Screens use domain contracts. Data implementations use the database boundary.
The composition root selects the implementations. Domain code must not import
SQLite, provider SDK, or platform player classes.

Do not add a module for an unused prototype. Add a module only when a real
feature needs a clear boundary.

## Main paths

- SQLite database: `lib/core/database/database.dart`
- Dependency setup: `lib/core/di/service_locator.dart`
- Android media and NewPipe bridge: `android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt`
- Main shell: `lib/features/home/presentation/app_shell.dart`
- Player screen: `lib/features/player/presentation/learning_player_screen.dart`

See [architecture.md](architecture.md) and [data-flow.md](data-flow.md).
