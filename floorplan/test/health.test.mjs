import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { scanRepository } from '../scripts/analyze.mjs';
import { getComponentDefinitions } from '../scripts/architecture.mjs';
import { runHealthChecks, detectCredentialIndicators, findCycles } from '../scripts/health.mjs';

test('secret indicators include only a type and source line, never matched values', () => {
  const secret = 'const apiKey = "abcdefghijklmnop_secret_value";';
  const indicators = detectCredentialIndicators(`// ${secret}\n${secret}`);
  assert.equal(indicators.length, 1);
  assert.equal(indicators[0].line, 2);
  assert.equal(indicators[0].type, 'credential-like assignment');
  assert.equal(JSON.stringify(indicators).includes('abcdefghijklmnop'), false);
});

test('finds cycles only among resolved library imports', () => {
  const files = [
    { path: 'lib/a.dart', language: 'Dart', imports: [{ target: 'lib/b.dart' }] },
    { path: 'lib/b.dart', language: 'Dart', imports: [{ target: 'lib/a.dart' }] },
    { path: 'test/a_test.dart', language: 'Dart', imports: [{ target: 'lib/a.dart' }] },
    { path: 'lib/c.dart', language: 'Dart', imports: [] },
  ];
  assert.deepEqual(findCycles(files), [['lib/a.dart', 'lib/b.dart']]);
});

test('health report identifies a credential indicator without disclosing it', async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-health-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  await mkdir(path.join(root, 'lib'));
  const secret = 'ghp_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKL';
  await writeFile(path.join(root, 'pubspec.yaml'), 'name: fixture\n');
  await writeFile(path.join(root, 'lib', 'config.dart'), `const token = "${secret}";`);
  const scan = await scanRepository(root);
  const report = await runHealthChecks(root, scan, { components: getComponentDefinitions() });
  const finding = report.findings.find((item) => item.title.includes('GitHub token'));
  assert.ok(finding);
  assert.equal(finding.file, 'lib/config.dart');
  assert.equal(JSON.stringify(report).includes(secret), false);
  assert.match(report.disclaimer, /not a professional security audit/u);
});

test('reports outdated settings claims and omitted note-image behavior precisely', async (t) => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-doc-drift-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  await mkdir(path.join(root, 'docs'), { recursive: true });
  await mkdir(path.join(root, 'lib', 'features', 'home', 'presentation'), { recursive: true });
  await mkdir(path.join(root, 'lib', 'features', 'notes', 'presentation'), { recursive: true });
  await mkdir(path.join(root, 'lib', 'features', 'notes', 'data'), { recursive: true });
  await writeFile(path.join(root, 'docs', 'development-roadmap.md'), 'The Settings screen does\nnot save settings.\n');
  await writeFile(path.join(root, 'docs', 'implementation-status.md'), 'Notes do not have file attachments.\n');
  await writeFile(path.join(root, 'lib', 'features', 'home', 'presentation', 'app_shell.dart'), 'class AppShell {}\n');
  await writeFile(path.join(root, 'lib', 'features', 'notes', 'presentation', 'note_editor_page.dart'), 'void _insertImage() {}\n');
  await writeFile(path.join(root, 'lib', 'features', 'notes', 'data', 'note_image_store.dart'), 'void pickAndStoreImage() {}\n');
  const report = await runHealthChecks(root, {
    files: [{
      path: 'lib/features/home/presentation/app_shell.dart',
      language: 'Dart',
      lines: 1,
      imports: [],
    }],
  }, {
    components: [{ id: 'feature-settings', status: 'Implemented' }],
  });
  assert.ok(report.findings.some((finding) => finding.title === 'Roadmap status conflicts with active settings wiring'));
  const noteFinding = report.findings.find((finding) => finding.title === 'Implementation status omits the note image workflow');
  assert.ok(noteFinding);
  assert.match(noteFinding.explanation, /arbitrary file attachments remains accurate/u);
});
