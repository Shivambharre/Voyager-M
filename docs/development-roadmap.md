# Development Roadmap

This document tracks the implementation sequence from
[`Distraction_Free_Learning_App_Roadmap_Plan.docx`](../PDFS/Distraction_Free_Learning_App_Roadmap_Plan.docx).
The DOCX remains the detailed source plan; current completion and evidence are
tracked in [`implementation-status.md`](implementation-status.md).

## Phase 0 — Architecture foundation

- **0.1 Repository and documentation — Complete.** Flutter project exists
  with `lib/`, `test/`, `docs/`, and Android/Web targets. Architecture,
  development workflow, AI rules, and design documentation exist. Dedicated
  module, data flow, database, media provider, player, content policy,
  ad-handling, testing, and decision records are documented.
- **0.2 Interfaces and dependency injection — Complete for mock mode.**
  Domain interfaces/models cover roadmaps/topics, videos/playlists,
  notes, progress/bookmarks, settings, media, player, content policy, and
  storage. GetIt selects in-memory mocks. Production adapters are not included.

## Phase 1 — UI/UX foundation

- **1.1 Design system — Complete as prototype.** Neo-Brutalist tokens, light
  and dark themes, shared components, and a showcase screen are implemented.
- **1.2 App shell — Complete as prototype.** Home, Roadmaps, Library, Notes,
  Settings, and a mock player can be navigated with mock/sample content.

## Phase 2 — Local data layer

- **2.1 SQLite — Core implemented.** Schema versioning, migration, and SQLite
  repository adapters exist for roadmaps, library, notes, progress, settings,
  and metadata. Additional edge-case coverage remains.
- **2.2 Device file storage — Not started.** Implement app-managed durable
  storage for images/PDFs after the structured data layer is underway.

## Phase 3 — Library and roadmap system

- **3.1 Learning library — Implemented in core workflow.** Saved playlists,
  playlist entries, and videos persist through the repository, and the app shell
  displays these records in Home and Library.
- **3.2 Roadmap builder — Partially implemented.** Roadmaps can be created,
  edited, deleted, activated, and organized with topics whose completion state
  drives displayed progress. Topic reordering, source-item linking, and
  continue/resume selection remain.

## Phase 4 — Real media

- **4.1 Source adapters and extraction — Implemented with limitations.** Source
  detection, YouTube video/playlist adapters, MIT OCW direct-media parsing, and
  stable metadata caching are implemented.
- **4.2 Playback controller — Implemented; validation pending.** The player
  retains supported stream options for quality switching, includes fullscreen
  and seek controls, and writes saved recipe data for library and note flows.

## Phase 5 — Distraction and content policy

- **5.1 Policy behavior — Interface/mock only.** Connect decisions to import
  and playback use cases and document provider limitations.
- **5.2 Ad/distraction handling — Filter boundary only.** Discovery and social
  surfaces remain absent; filtering is disabled by default and no native Rust
  bridge is packaged.

## Phase 6 — Study tools and progress

- **6.1 Notes — Repository-backed text notes.** Player notes and Notes-tab notes
  persist through `NotesRepository` with optional video/timestamp metadata.
- **6.2 Progress/resume — Contracts/mock only.** Connect player lifecycle,
  completion policy, roadmap calculations, and resume behavior.

## Phase 7 — Search, offline reliability, and polish

- **7.1 Search — Not implemented.** Add local search across persisted content.
- **7.2 Offline reliability — Foundation only.** Preserve organization and
  learning records offline; media availability depends on provider policy.
- **7.3 Final polish — Deferred.** Audit performance, accessibility, errors,
  device behavior, and release builds after core features stabilize.

## One-phase-at-a-time rule

Complete the current phase's checkpoint and tests before beginning the next
implementation phase. See [`development-workflow.md`](development-workflow.md)
for the everyday workflow and [`testing.md`](testing.md) for validation.
