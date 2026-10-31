# Development Rules

## Before you change code

- Read [implementation-status.md](implementation-status.md) and
  [development-roadmap.md](development-roadmap.md).
- Check the current source and tests. Do not rely on old notes alone.
- Work on one active flow at a time.

## Architecture

- Keep platform code out of domain models and rules.
- Use repository contracts for stored data.
- Use media contracts for source extraction and playback.
- Register implementations in `lib/core/di/service_locator.dart`.
- Do not add a cloud service or a new architecture layer without a clear need.
- Do not keep unused prototypes in the active design.

## Tests

- Add a test for each new domain rule.
- Test repository behavior without a network connection.
- Add widget tests for user-visible behavior.
- Add migration tests when the database schema changes.
- Run the smallest relevant test set first. Run the full validation commands
  in [testing.md](testing.md) when needed.

## Documentation

- Update the relevant document when behavior or an architecture decision
  changes.
- State whether a feature is active, incomplete, or not connected to the UI.
- Use short sentences and direct instructions.
- Keep exact class, method, package, and file names when readers need them.
- Check every code path, command, and internal link before you publish a change.

## Complete a change

1. Implement the smallest complete change.
2. Run the related tests and checks.
3. Fix failures caused by the change.
4. Update the relevant documentation.
5. Report any known limitation that remains.
