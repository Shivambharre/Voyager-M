# Implementation Status

This is the current source of truth for progress against
[`development-roadmap.md`](development-roadmap.md). Work is intentionally done
one roadmap phase at a time. A phase is not complete just because part of its
UI or interface exists.

## Current checkpoint

| Roadmap phase | Status | Evidence / remaining work |
| --- | --- | --- |
| 0.1 Repository and documentation | Complete for the current foundation | Flutter Android project, web target, architecture, module, design, database, data-flow, media, player, content-policy, ad-handling, testing, workflow, AI rules, and decision documentation exist. |
| 0.2 Interfaces and dependency injection | Complete for mock mode | Domain contracts and mock implementations exist for roadmaps/topics, library videos/playlists, notes, progress/bookmarks, settings, media provider, player engine, content policy, and file storage. GetIt wires in-memory implementations centrally. |
| 1.1 Design system | Complete as a UI prototype | Central Neo-Brutalist tokens/theme, reusable components, and the showcase screen are implemented. |
| 1.2 App shell | Complete as a UI prototype | Home, Roadmaps, Library, Notes, Settings, and a mock learning-player screen are navigable. Interactions that need persistence or real media are illustrative only. |
| 2.1 SQLite implementation | Not started | `sqflite` is present in the dependency manifest, but the database adapter is a placeholder. No schema, migrations, or SQLite-backed repositories have been implemented. |
| 2.2 Device file storage | Not started | Only the mock in-memory storage adapter exists; attachments are not persisted on device. |
| 3.1 Learning library | Not started | The UI and contracts exist. Link resolution, persistence, duplicate/error handling, and real library records are not connected. |
| 3.2 Custom roadmap builder | Not started | Roadmap models/repository contracts and a roadmap display exist. Create/edit/reorder/section flows and item-level completion are not implemented. |
| 4.1 NewPipe Extractor integration | Not started | No production media extraction is implemented. |
| 4.2 Android Media3/ExoPlayer player | Not started | Player UI and mock engine contract exist; there is no production playback engine. |
| 5.1 Content-policy subsystem | Interface/mock only | A replaceable decision contract and basic mock policy exist. It is not connected to library import or playback flows. |
| 5.2 Ad/distraction handling | Not started | The UI omits discovery feeds. No provider-specific ad handling or bypass is implemented. |
| 6.1 Notes | UI/mock only | Notes UI supports temporary in-memory edits in its screen; repository contracts and a mock repository exist, but the screen does not yet persist through them. Attachments are placeholders. |
| 6.2 Progress and resume | UI/mock only | Progress/bookmark contracts and mock repository exist. Progress shown on screens is sample data and is not connected to playback lifecycle. |
| 7.1 Local search | UI prototype only | The Library screen filters sample rows in memory. There is no repository-wide search across saved learning data. |
| 7.2 Offline-first behavior | Foundation only | The app starts in mock mode without a backend, but user data and media are not durable offline yet. |
| 7.3 UI/performance polish | Deferred | Do after core persistence and playback flows stabilize. |

## Verified development targets

- `flutter analyze` passes.
- `flutter test` passes, including mock-mode contract tests and app navigation/player widget tests.
- `flutter build web` passes. Flutter web support was enabled so the prototype can be tested in Chrome.
- `flutter build apk --debug` passed for the UI prototype before the latest interface-only additions; rerun it when making an Android release or platform integration change.
- The Chrome preview was launched locally at `http://localhost:53917` during UI validation. The debug-run process may need to be started again after the session ends.

## Known boundaries

- The dependency-injection container selects in-memory implementations. It does not silently fall back from a failed database or media service because production adapters are not wired yet.
- The current player is a screen-level UI prototype. Its controls do not drive `PlayerEngine`.
- The demo notes, progress values, and library entries are not persisted.
- Chrome is useful for UI iteration, but it does not validate Android media plugins, SQLite driver behavior, or device file permissions.
- `AppDatabase`/`SqfliteAppDatabase` in `lib/core/database/database.dart` is currently only a placeholder.

## Next work

Start Phase 2.1 as a separate checkpoint: define and test the SQLite schema and migrations before wiring repositories.
