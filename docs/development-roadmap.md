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

- **2.1 SQLite — Not started.** Build schema/versioning/migrations and
  repository adapters behind existing contracts. Do not treat the current
  `SqfliteAppDatabase` placeholder or dependency as completed persistence.
- **2.2 Device file storage — Not started.** Implement app-managed durable
  storage for images/PDFs after the structured data layer is underway.

## Phase 3 — Library and roadmap system

- **3.1 Learning library — Not started.** Implement persistent references and
  provider metadata resolution.
- **3.2 Roadmap builder — Not started.** Add editing, sections, source items,
  ordering, completion, and continue/resume selection.

## Phase 4 — Real media

- **4.1 Provider integration — Not started.** Evaluate supported integration,
  license, maintenance, compatibility, service restrictions, and failure
  behavior before selecting an extractor.
- **4.2 Android player — Not started.** Implement an Android playback engine
  behind `PlayerEngine`, retaining the mock for tests.

## Phase 5 — Distraction and content policy

- **5.1 Policy behavior — Interface/mock only.** Connect decisions to import
  and playback use cases and document provider limitations.
- **5.2 Ad/distraction handling — Not started.** Keep discovery/social surfaces
  absent. Do not implement DRM circumvention or hidden provider bypasses.

## Phase 6 — Study tools and progress

- **6.1 Notes — UI/contracts/mock only.** Wire durable typed and timestamped
  notes, attachments, and note search.
- **6.2 Progress/resume — Contracts/mock only.** Connect player lifecycle,
  completion policy, roadmap calculations, and resume behavior.

## Phase 7 — Search, offline reliability, and polish

- **7.1 Search — UI sample only.** Add local search across persisted content.
- **7.2 Offline reliability — Not complete.** Preserve organization and
  learning records offline; media availability depends on provider policy.
- **7.3 Final polish — Deferred.** Audit performance, accessibility, errors,
  device behavior, and release builds after core features stabilize.

## One-phase-at-a-time rule

Complete the current phase's checkpoint and tests before beginning the next
implementation phase. See [`development-workflow.md`](development-workflow.md)
for the everyday workflow and [`testing.md`](testing.md) for validation.
