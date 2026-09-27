# AI Development Rules

## General rules

- Prefer small, composable changes over large rewrites.
- Keep business logic free from platform-specific details.
- Never put SQLite, YouTube, or UI classes directly into feature/domain logic.
- Preserve replaceable boundaries by coding to interfaces and abstractions.
- Do not create cloud dependencies unless a feature clearly requires them.

## Architecture enforcement

When editing the project:

- Add new feature behavior behind domain contracts.
- Keep repository implementations behind repository interfaces.
- Keep media and filtering logic behind adapter interfaces.
- Keep UI logic and state management separate from persistence concerns.

## Refactoring rule

If a feature starts depending on a concrete implementation instead of an interface, stop and move that dependency behind an abstraction before continuing.

## Testing rule

Every new domain rule or repository contract should have a direct unit or widget test. App startup and wiring should be smoke-tested.

## Progress and phase rule

Before starting planned implementation, read `docs/implementation-status.md`
and `docs/development-roadmap.md`. Work on the next incomplete checkpoint only;
update the relevant module documentation and status after tests pass. Keep mock,
prototype, and production behavior clearly distinguished.

## Documentation rule

Any significant feature, architectural decision, or cross-cutting concern should be documented in the docs folder.
