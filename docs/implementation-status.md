# Implementation Status

This is the current source of truth for progress against
[`development-roadmap.md`](development-roadmap.md). Work is intentionally done
one roadmap phase at a time. A phase is not complete just because part of its
UI or interface exists.

## Current checkpoint

| Roadmap phase | Status | Evidence / remaining work |
| --- | --- | --- |
| 0.1 Repository and documentation | Complete for the current foundation | Flutter Android project, web target, architecture, module, design, database, data-flow, media, player, content-policy, ad-handling, testing, workflow, AI rules, and decision documentation exist. |
| 0.2 Interfaces and dependency injection | Complete for mock mode | Domain contracts and mock implementations exist for roadmaps/topics, library videos/playlists, notes, progress/bookmarks, settings, media provider, player engine, content policy, and file storage. GetIt selects mock or SQLite repositories by runtime mode. |
| 1.1 Design system | Complete as a UI prototype | Central Neo-Brutalist tokens/theme, reusable components, and the showcase screen are implemented. |
| 1.2 App shell | Complete as a UI prototype | Home, Roadmaps, Library, Notes, Settings, and the learning-player screen are navigable. Screen-local demo lesson/library/note/attachment/storage values were removed; notes remain temporary session state. |
| 2.1 SQLite implementation | Core implemented | Versioned schema v2, v1-to-v2 migration preserving existing records, SQLite repositories, and close/reopen tests exist. Additional CRUD edge cases remain. |
| 2.2 Device file storage | Not started | Only the mock in-memory storage adapter exists; attachments are not persisted on device. |
| 3.1 Learning library | Partially implemented | Player can save playlist metadata, ordered entries, and videos; Home and Library display saved records and reopen source URLs. General import/search flows remain. |
| 3.2 Custom roadmap builder | Partially implemented | Roadmaps support create/edit/delete/activate; topics support add/delete/status updates and computed completion progress. Reordering, sections, source-item linking, and resume selection remain. The single demo roadmap is seeded only by the in-memory mock repository and can be deleted. |
| 4.1 Source adapters and extraction | Implemented with limitations | URL detection, YouTube video/playlist adapter, MIT OCW direct-media adapter, stable metadata cache, and lazy playlist stream loading are implemented. No live upstream extraction/device playback validation yet. |
| 4.2 Playback controller | Implemented; device validation pending | The player supports retained-stream quality selection, seek/play/speed controls, and immersive fullscreen. Notes save through the repository. Direct streams go to `video_player`/ExoPlayer on Android and the browser backend on Web; physical playback and split audio/video remain unvalidated/unsupported. |
| 5.1 Content-policy subsystem | Interface/mock only | A replaceable decision contract and basic mock policy exist. It is not connected to library import or playback flows. |
| 5.2 Ad/distraction handling | Filter boundary only | A disabled-by-default filter service/engine/MethodChannel contract exists. No Rust engine or Android native bridge is packaged; YouTube player and extracted-media requests are excluded. |
| 6.1 Notes | Repository-backed text notes | Notes from the player and Notes tab persist through `NotesRepository`; timestamp/video context is recorded for player notes. Attachments remain unimplemented. |
| 6.2 Progress and resume | UI/mock only | Progress/bookmark contracts and mock repository exist. Progress shown on screens is sample data and is not connected to playback lifecycle. |
| 7.1 Local search | UI prototype only | The Library screen filters sample rows in memory. There is no repository-wide search across saved learning data. |
| 7.2 Offline-first behavior | Foundation only | The app starts in mock mode without a backend, but user data and media are not durable offline yet. |
| 7.3 UI/performance polish | Deferred | Do after core persistence and playback flows stabilize. |

## Verified development targets

- `flutter analyze` passes.
- `flutter test` passes, including mock-mode contract tests and app navigation/player widget tests.
- `flutter build web` passes with `video_player_web`.
- `flutter build apk --debug` passes when Gradle Kotlin incremental compilation is disabled for this Windows cross-drive workspace: `$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.incremental=false'`.
- The Chrome preview was launched locally at `http://localhost:53917` during UI validation. The debug-run process may need to be started again after the session ends.

## Known boundaries

- Android DI selects SQLite repositories and metadata cache; Web/mock mode uses in-memory repositories/cache. Database failure does not silently fall back.
- YouTube stream extraction uses reverse-engineered endpoints and may fail or require service-terms review. No ad-request manipulation or offline copy path exists.
- `NativeFilterBridge` has no Android MethodChannel handler and `adblock-rust` is not integrated; filtering remains disabled by default.
- Android direct-stream playback and Web CORS/codec support have not been validated on physical devices/browsers.
- Production SQLite starts with no seeded roadmap/sample content. Web/mock repositories remain in-memory by design.
- Chrome is useful for UI iteration, but it does not validate Android media plugins, SQLite driver behavior, or device file permissions.
- `AppDatabase` uses schema version 2; device-file storage and screen-to-repository wiring remain incomplete.

## Next work

Continue Phase 2/3 by connecting progress/resume to playback lifecycle, adding roadmap topic reordering/source linking, and validating playback on a physical Android device/browser.
