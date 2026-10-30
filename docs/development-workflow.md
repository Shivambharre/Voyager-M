# Development Workflow

## Local-first workflow

1. Add or update domain models and repository contracts.
2. Implement data adapters and storage integrations behind interfaces.
3. Wire implementations in the dependency injection container.
4. Build a feature screen using the Design System and app shell.
5. Validate with targeted widget or unit tests.

Mock/Web mode selects in-memory repositories. Media playback still requires
network access and uses the same player pipeline as Android.

## Current roadmap position

The phase-by-phase status and implementation evidence are maintained in
[`implementation-status.md`](implementation-status.md), with the ordered plan in
[`development-roadmap.md`](development-roadmap.md).

- Phase 0.1: complete — project skeleton and architecture documentation
- Phase 0.2: active repository interfaces and centralized platform-specific DI
- Phase 1.1–1.2: complete as UI prototypes
- Current: maintain and validate the SQLite-backed Android repository flow

## Validation commands

- `flutter analyze`
- `flutter test`
- `flutter run`

## Branching and change discipline

- Keep feature work small and focused.
- Prefer incremental changes to a module rather than broad edits across the app.
- Avoid introducing backend infrastructure unless explicitly justified.

## Current workflow

1. Read [`implementation-status.md`](implementation-status.md) and work only on
   the next incomplete checkpoint.
2. Preserve existing domain contracts; implement new infrastructure behind
   them.
3. Add targeted tests before wiring a production adapter into dependency
   injection.
4. Update the relevant module document and the implementation status after
   verification.
5. Do not start a later phase until the current checkpoint's tests pass.

## Production readiness checklist

- Keep interfaces only for active or implemented subsystem boundaries.
- No feature is hard-wired to SQLite or a single media provider.
- UI works through app state and domain contracts.
- Feature behavior is covered by tests.
- Production and mock implementations are clearly distinguished in docs.
