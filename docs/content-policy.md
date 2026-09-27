# Content Policy

## Contract and decisions

`ContentPolicy.evaluate(sourceUrl)` returns an app-owned `ContentDecision`:

- `allow`
- `block`
- `ignore`
- `unavailable`

## Current state

`LearningContentPolicy` is a simple mock rule: it parses the URI, blocks paths
whose segments are `shorts`, `trending`, or `recommended` (case-insensitive),
and marks invalid/non-scheme input unavailable. It does not inspect a remote
page, classify video contents, or control player UI.

The policy is not yet invoked by the library, player, or a feature use case.

## Boundary

Policy decisions belong in import/navigation/application logic, not inside
presentation widgets. Document which content surfaces the selected provider can
actually control. Keep unrelated provider behavior replaceable.
