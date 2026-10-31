# Development Workflow

## Before work

1. Read [implementation-status.md](implementation-status.md).
2. Read [development-roadmap.md](development-roadmap.md).
3. Check the source and tests for the behavior you plan to change.
4. Choose one active flow.

## Add a feature

1. Define or update the domain model and contract.
2. Add a data implementation behind the contract when the feature needs
   storage.
3. Register the implementation in the dependency-injection setup.
4. Add the user interface through the app shell and shared design system.
5. Add unit, repository, or widget tests for the changed behavior.
6. Update the relevant documentation after the tests pass.

Do not add a repository or a service layer if the feature does not need it.
Do not connect a placeholder control to behavior that has not been approved.

## Platform behavior

Web uses in-memory repositories by default. Android uses SQLite repositories.
Playback needs a network connection. Android uses NewPipe and Media3 for
YouTube extraction and playback. Other platforms use the Dart extractor and
`video_player`.

A Web build checks Flutter Web compilation. It does not test Android plugins,
SQLite, or native playback.

## Validation

Use the commands in [testing.md](testing.md). Run focused tests first. Run
broader checks when a change affects multiple modules or app wiring.

## Change discipline

- Keep changes focused.
- Keep feature rules independent from platform APIs.
- Use repository and media contracts at module boundaries.
- State known test gaps and platform limits.
- Do not describe a prototype or stored data model as an active user feature.
