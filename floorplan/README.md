# VoyagerM Floorplan

A local, offline architecture explorer for this Flutter repository. It scans
the current source tree, produces an evidence-linked dependency map, and
provides workflows, search, recent-work comparison, a preliminary health
check, question prompts for Copilot Chat, and a standalone HTML export.

The tool is independent of Claude Code, Codex, Flutter runtime dependencies,
and third-party services. It uses only Node.js built-ins and does not change
application code or send source to a network service.

## Generate the first map

From the repository root, with Node.js 18 or newer:

```powershell
node floorplan/scripts/build.mjs
```

Generated files include `index.html`, `graph.json`, `architecture.json`,
`recent-work.json`, `health.json`, and one JSON description per scanned file
under `descriptions/`. The private previous-scan cache is under `.cache/` and
is ignored by Git.

## Open and update

Open `floorplan/index.html` in a modern browser. It is self-contained and
works offline. For a local loopback server instead:

```powershell
node floorplan/serve.mjs
```

Then open `http://127.0.0.1:4173/`. The server is read-only, binds only to
`127.0.0.1`, exposes generated map outputs only, and stops cleanly with
**Ctrl+C**. If the port is occupied, choose another with
`node floorplan/serve.mjs --port 4174`.

Refresh the scan and map after source changes by running:

```powershell
node floorplan/scripts/build.mjs
```

The comparison reports added, removed, renamed, and modified files, symbol
and dependency changes, and affected components. It preserves an existing
description when the file's extracted structure is unchanged. It does not
invent a reason for a code change.

## Ask the map

In the viewer, choose **Ask the map**, enter a question, and prepare a
contextual prompt. The viewer can copy that prompt, or you can copy it
manually, into Copilot Chat. It does not access a Copilot session or invoke a
CLI. For a terminal answer and prompt:

```powershell
node floorplan/query.mjs "How does YouTube playback work?"
```

## Export

Choose **Export** in the viewer and select whether to include workflows,
component notes, recent work, and health findings. The downloaded HTML has
no runtime CDN dependencies, removes scan fingerprints and Git revision
metadata, and uses repository-relative paths only.

## Tests

Run the scanner, graph, refresh, health, export, and local-server tests with
Node's built-in test runner:

```powershell
node --test floorplan/test/analyze.test.mjs floorplan/test/build.test.mjs floorplan/test/health.test.mjs floorplan/test/server.test.mjs
```

The Flutter application remains separate. Its existing checks are
`flutter analyze` and `flutter test`.

## What the health check can establish

The checks report likely credential-shaped literals without storing or
displaying the matched value, non-local HTTP literals, import cycles, very
large Dart files, selected wiring/documentation gaps, and other source-backed
signals. Findings include evidence locations, confidence, and suggested
review actions.

This is an automated preliminary check, **not a security audit**. Heuristics
can miss secrets or vulnerabilities and can produce false positives. It does
not execute application code, contact external services, prove provider
availability, or automatically change code.

Architecture connections are derived from imports, explicit dependency
registrations, repository implementations, database references, navigation
expressions, declared pubspec and Android Gradle dependencies, SQLite foreign
keys, and matching platform channels. Generated `graphify-out/` and test-only
platform channels are excluded from the active implementation map. Recent-work
comparison includes dependency constraint and native coordinate changes.

The notes workflow includes embedded images: IO platforms save files under app
documents, while Web stores data URLs with browser-local notes. This does not
mean arbitrary file attachments are supported. The curated workflows are
reviewed against source; partial paths are labeled as such. Package or
documentation mentions alone are not treated as proof that a feature is
active.
