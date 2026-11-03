import assert from 'node:assert/strict';
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { getComponentDefinitions } from '../scripts/architecture.mjs';
import {
  buildFloorplan,
  buildGraph,
  buildRecentWork,
  sanitizeForExport,
  validateArchitecture,
} from '../scripts/build.mjs';
import { scanRepository } from '../scripts/analyze.mjs';

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

test('builds graph imports and preserves line evidence for each edge', async () => {
  const temp = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-graph-'));
  try {
    await mkdir(path.join(temp, 'lib', 'core'), { recursive: true });
    await mkdir(path.join(temp, 'lib', 'core', 'database'), { recursive: true });
    await mkdir(path.join(temp, 'android', 'app'), { recursive: true });
    await writeFile(path.join(temp, 'pubspec.yaml'), 'name: fixture\ndependencies:\n  http: ^1.0.0\n');
    await writeFile(path.join(temp, 'lib', 'main.dart'), [
      "import 'package:fixture/core/service.dart';",
      "import 'package:http/http.dart' as http;",
      'class FixtureApp {}',
    ].join('\n'));
    await writeFile(path.join(temp, 'lib', 'core', 'service.dart'), 'class FixtureService {}');
    await writeFile(path.join(temp, 'lib', 'core', 'database', 'database.dart'), `
const int schemaVersion = 1;
CREATE TABLE roadmaps (
  id TEXT PRIMARY KEY
)
''');
CREATE TABLE topics (
  id TEXT PRIMARY KEY,
  roadmap_id TEXT REFERENCES roadmaps(id) ON DELETE CASCADE
)
''');
`);
    await writeFile(path.join(temp, 'android', 'app', 'build.gradle.kts'), `
dependencies {
  implementation("androidx.media3:media3-exoplayer:1.9.2")
}
`);
    const scan = await scanRepository(temp);
    const components = getComponentDefinitions().map((component) => ({
      ...component,
      files: scan.files.filter((file) => file.path.startsWith(component.path)).map((file) => file.path),
    }));
    const descriptions = new Map(scan.files.map((file) => [
      file.path,
      { name: file.path, simple: 'Description', developer: 'Technical description', status: 'Implemented' },
    ]));
    const graph = buildGraph(scan, components, descriptions);
    const edge = graph.edges.find((item) =>
      item.type === 'import' &&
      item.source === 'file:lib/main.dart' &&
      item.target === 'file:lib/core/service.dart');
    assert.ok(edge);
    assert.equal(edge.evidence[0].file, 'lib/main.dart');
    assert.equal(edge.evidence[0].line, 1);
    assert.equal(graph.searchIndex.some((entry) => entry.name === 'FixtureService'), true);
    assert.ok(graph.nodes.some((node) => node.id === 'package:http' && node.constraint === '^1.0.0'));
    assert.ok(graph.nodes.some((node) => node.id === 'package:gradle:androidx.media3:media3-exoplayer:1.9.2'));
    assert.ok(graph.edges.some((item) =>
      item.source === 'file:pubspec.yaml' && item.target === 'package:http' && item.label === 'declares package'));
    assert.ok(graph.edges.some((item) =>
      item.source === 'table:topics' && item.target === 'table:roadmaps' && item.label === 'foreign key'));
    assert.ok(graph.edges.some((item) =>
      item.source === 'file:android/app/build.gradle.kts' && item.label === 'declares package'));
  } finally {
    await rm(temp, { recursive: true, force: true });
  }
});

test('validates hierarchy assignments and rejects edges without evidence', async () => {
  const temp = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-validation-'));
  try {
    await mkdir(path.join(temp, 'lib'));
    await writeFile(path.join(temp, 'pubspec.yaml'), 'name: fixture\n');
    await writeFile(path.join(temp, 'lib', 'main.dart'), 'void main() {}');
    const scan = await scanRepository(temp);
    const architecture = {
      components: getComponentDefinitions(),
      fileAssignments: Object.fromEntries(scan.files.map((file) => [file.path, 'runtime'])),
    };
    const graph = { nodes: [{ id: 'one' }, { id: 'two' }], edges: [] };
    assert.equal(validateArchitecture(architecture, graph, scan).valid, true);
    architecture.fileAssignments = {};
    graph.edges.push({ id: 'bad', source: 'one', target: 'two', evidence: [] });
    const result = validateArchitecture(architecture, graph, scan);
    assert.equal(result.valid, false);
    assert.ok(result.errors.some((error) => error.includes('Unassigned file')));
    assert.ok(result.errors.some((error) => error.includes('no source evidence')));
  } finally {
    await rm(temp, { recursive: true, force: true });
  }
});

test('detects file adds, removals, renames, and structural changes without inventing reasons', () => {
  const previous = {
    files: [
      { path: 'lib/old.dart', fingerprint: 'same', structuralSignature: 'shape-a', symbols: [], imports: [], routes: [] },
      { path: 'lib/changed.dart', fingerprint: 'before', structuralSignature: 'shape-a', symbols: [{ kind: 'class', name: 'Before' }], imports: [], routes: [] },
      { path: 'lib/deleted.dart', fingerprint: 'gone', structuralSignature: 'shape-a', symbols: [], imports: [], routes: [] },
    ],
  };
  const current = {
    files: [
      { path: 'lib/new.dart', fingerprint: 'same', structuralSignature: 'shape-a', symbols: [], imports: [], routes: [] },
      { path: 'lib/changed.dart', fingerprint: 'after', structuralSignature: 'shape-b', symbols: [{ kind: 'class', name: 'After' }], imports: [{ specifier: 'package:x/y.dart' }], routes: [{ kind: 'push' }] },
      { path: 'lib/added.dart', fingerprint: 'new', structuralSignature: 'shape-a', symbols: [], imports: [], routes: [] },
    ],
  };
  const result = buildRecentWork(previous, current);
  assert.equal(result.baseline, false);
  assert.equal(result.changes.find((item) => item.type === 'renamed').from, 'lib/old.dart');
  const changed = result.changes.find((item) => item.path === 'lib/changed.dart');
  assert.equal(changed.structuralChange, true);
  assert.deepEqual(changed.changedSymbols, { added: ['class:After'], removed: ['class:Before'] });
  assert.equal(changed.reason, null);
  assert.ok(result.changes.some((item) => item.type === 'deleted' && item.path === 'lib/deleted.dart'));
  assert.ok(result.changes.some((item) => item.type === 'added' && item.path === 'lib/added.dart'));
});

test('reports package version and Android coordinate changes in recent work', () => {
  const result = buildRecentWork({
    files: [{
      path: 'pubspec.yaml',
      fingerprint: 'before',
      structuralSignature: 'old',
      symbols: [],
      imports: [],
      routes: [],
      declaredDependencies: [{ name: 'http', constraint: '^1.0.0' }],
    }, {
      path: 'android/app/build.gradle.kts',
      fingerprint: 'gradle-before',
      structuralSignature: 'old-gradle',
      symbols: [],
      imports: [],
      routes: [],
      nativeDependencies: [{ coordinate: 'androidx.media3:media3-exoplayer:1.9.2' }],
    }],
  }, {
    files: [{
      path: 'pubspec.yaml',
      fingerprint: 'after',
      structuralSignature: 'new',
      symbols: [],
      imports: [],
      routes: [],
      declaredDependencies: [{ name: 'http', constraint: '^2.0.0' }],
    }, {
      path: 'android/app/build.gradle.kts',
      fingerprint: 'gradle-after',
      structuralSignature: 'new-gradle',
      symbols: [],
      imports: [],
      routes: [],
      nativeDependencies: [{ coordinate: 'androidx.media3:media3-exoplayer:1.10.0' }],
    }],
  });
  const pubspecChange = result.changes.find((item) => item.path === 'pubspec.yaml');
  assert.deepEqual(pubspecChange.dependenciesChanged.added, ['package:http ^2.0.0']);
  assert.deepEqual(pubspecChange.dependenciesChanged.removed, ['package:http ^1.0.0']);
  const gradleChange = result.changes.find((item) => item.path === 'android/app/build.gradle.kts');
  assert.deepEqual(gradleChange.dependenciesChanged.added, ['gradle:androidx.media3:media3-exoplayer:1.10.0']);
  assert.deepEqual(gradleChange.dependenciesChanged.removed, ['gradle:androidx.media3:media3-exoplayer:1.9.2']);
});

test('sanitizes exports and excludes absolute roots and scan fingerprints', () => {
  const sanitized = sanitizeForExport({
    scan: { root: 'D:\\private\\workspace', repository: { absolutePath: 'D:\\private\\workspace' } },
    architecture: { repository: { name: 'VoyagerM', branch: 'private-branch', commit: 'abc123' }, components: [{ notes: ['note'] }] },
    graph: { repository: { name: 'VoyagerM', branch: 'private-branch', commit: 'abc123' }, nodes: [{ path: 'lib/main.dart', fingerprint: 'secret-hash', structuralSignature: 'signature' }], workflows: [{ id: 'flow' }] },
    recentWork: { changes: [{ path: 'lib/main.dart' }] },
    health: { findings: [{ file: 'lib/main.dart' }] },
  }, { includeFlows: false, includeNotes: false, includeRecentWork: false, includeHealth: false });
  const serialized = JSON.stringify(sanitized);
  assert.equal(serialized.includes('D:\\private'), false);
  assert.equal(serialized.includes('secret-hash'), false);
  assert.equal(serialized.includes('private-branch'), false);
  assert.equal(sanitized.graph.workflows.length, 0);
  assert.deepEqual(sanitized.architecture.repository, { name: 'VoyagerM' });
});

test('builds file descriptions, architecture data, and a self-contained viewer without changing app files', async () => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-integration-'));
  const destination = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-output-'));
  try {
    await mkdir(path.join(root, 'lib', 'features', 'library'), { recursive: true });
    await mkdir(path.join(destination, 'scripts'), { recursive: true });
    await cp(path.join(projectRoot, 'floorplan', 'scripts', 'viewer-template.html'), path.join(destination, 'scripts', 'viewer-template.html'));
    await writeFile(path.join(root, 'pubspec.yaml'), 'name: fixture\n');
    await writeFile(path.join(root, 'lib', 'main.dart'), "import 'features/library/library.dart';\nclass FixtureApp {}\n");
    await writeFile(path.join(root, 'lib', 'features', 'library', 'library.dart'), 'class LibraryFeature {}');

    const first = await buildFloorplan(root, destination);
    assert.equal(first.validation.valid, true);
    assert.equal(first.descriptionCount, first.scan.files.length);
    assert.equal(first.recentWork.baseline, true);
    const output = await readFile(path.join(destination, 'index.html'), 'utf8');
    assert.ok(output.includes('VoyagerM · Floorplan'));
    assert.ok(output.includes('application/json'));
    assert.ok(!output.includes('@@FLOORPLAN_DATA@@'));
    const description = JSON.parse(await readFile(
      path.join(destination, 'descriptions', `f-${Buffer.from('lib/main.dart').toString('base64url')}.json`),
      'utf8',
    ));
    assert.ok(description.simple.length > 40);

    const before = description.simple;
    await writeFile(path.join(root, 'lib', 'features', 'library', 'library.dart'), '// an ordinary comment change\nclass LibraryFeature {}');
    const second = await buildFloorplan(root, destination);
    const preserved = JSON.parse(await readFile(
      path.join(destination, 'descriptions', `f-${Buffer.from('lib/features/library/library.dart').toString('base64url')}.json`),
      'utf8',
    ));
    assert.equal(second.recentWork.changes.some((change) => change.path === 'lib/features/library/library.dart'), true);
    assert.equal(preserved.simple.includes('library feature'), true);
    assert.ok(before.includes('Starts Flutter'));
  } finally {
    await rm(root, { recursive: true, force: true });
    await rm(destination, { recursive: true, force: true });
  }
});
