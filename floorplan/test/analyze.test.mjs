import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import {
  channelEvidence,
  dartImports,
  dartSymbols,
  extractDatabase,
  gradleDependencies,
  injectedTypes,
  packageDeclarations,
  packageDependencies,
  parseGitIgnore,
  referencedTables,
  repositoryImplementations,
  routeEvidence,
  scanRepository,
} from '../scripts/analyze.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

test('extracts relative and package Dart imports with source locations', () => {
  const source = [
    "import 'package:voyager_learning/core/media/playback_controller.dart';",
    "export '../domain/model.dart';",
    "import 'package:http/http.dart' as http;",
  ].join('\n');
  const imports = dartImports('lib/features/player/view.dart', source, 'voyager_learning');
  assert.deepEqual(imports.map(({ kind, target, external }) => ({ kind, target, external })), [
    { kind: 'import', target: 'lib/core/media/playback_controller.dart', external: null },
    { kind: 'export', target: 'lib/features/domain/model.dart', external: null },
    { kind: 'import', target: null, external: 'http' },
  ]);
  assert.deepEqual(imports.map((item) => item.line), [1, 2, 3]);
});

test('extracts Dart types, methods, Flutter screens, and navigation evidence', () => {
  const source = `
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}
class _LibraryPageState extends State<LibraryPage> {
  Future<void> openPlayer() async {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
    );
  }
}
`;
  const symbols = dartSymbols(source);
  assert.ok(symbols.some((symbol) => symbol.kind === 'class' && symbol.name === 'LibraryPage'));
  assert.ok(symbols.some((symbol) => symbol.name === 'openPlayer'));
  assert.ok(symbols.some((symbol) => symbol.name === 'createState'));
  assert.deepEqual(routeEvidence('lib/library/page.dart', source).map((route) => route.kind), [
    'navigator-push',
    'material-route',
  ]);
});

test('extracts GetIt registrations and repository implementations', () => {
  const di = `
serviceLocator.registerLazySingleton<LibraryRepository>(
  () => SqliteLibraryRepository(serviceLocator<AppDatabase>()),
);
_registerIfMissing<NotesRepository>(InMemoryNotesRepository.new);
`;
  assert.deepEqual(injectedTypes(di).map(({ contract, implementation }) => ({ contract, implementation })), [
    { contract: 'LibraryRepository', implementation: 'SqliteLibraryRepository' },
    { contract: 'NotesRepository', implementation: 'InMemoryNotesRepository' },
  ]);
  const implementation = 'class SqliteLibraryRepository implements LibraryRepository {';
  assert.deepEqual(repositoryImplementations(implementation, 'lib/library/data/sqlite.dart'), [
    {
      className: 'SqliteLibraryRepository',
      contract: 'LibraryRepository',
      file: 'lib/library/data/sqlite.dart',
      line: 1,
    },
  ]);
});

test('extracts platform channels, database schema, and repository table access', () => {
  const kotlin = `
private const val PLAYER_CHANNEL = "com.example/player"
MethodChannel(messenger, PLAYER_CHANNEL)
`;
  assert.deepEqual(channelEvidence(kotlin), [
    { kind: 'MethodChannel', name: 'com.example/player', line: 3 },
  ]);
  const schema = `
static const int schemaVersion = 4;
CREATE TABLE lessons (id TEXT PRIMARY KEY);
if (oldVersion < 3 && newVersion >= 3) { upgrade(); }
`;
  assert.deepEqual(extractDatabase(schema), {
    schemaVersion: 4,
    tables: [{ name: 'lessons', line: 3 }],
    relationships: [],
    migrations: [3],
  });
  assert.deepEqual(referencedTables("db.query('lessons'); transaction.insert('lessons', values);"), [
    { operation: 'query', name: 'lessons', line: 1 },
    { operation: 'insert', name: 'lessons', line: 1 },
  ]);
});

test('extracts SQLite foreign keys and Android Gradle package coordinates', () => {
  const database = extractDatabase(`
static const int schemaVersion = 4;
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
  assert.deepEqual(database.relationships, [{
    fromTable: 'topics',
    fromColumn: 'roadmap_id',
    toTable: 'roadmaps',
    toColumn: 'id',
    line: 9,
  }]);
  assert.deepEqual(gradleDependencies(`
dependencies {
  implementation("androidx.media3:media3-exoplayer:1.9.2")
  testImplementation("junit:junit:4.13.2")
}
`).map(({ coordinate, scope }) => ({ coordinate, scope })), [
    { coordinate: 'androidx.media3:media3-exoplayer:1.9.2', scope: 'implementation' },
    { coordinate: 'junit:junit:4.13.2', scope: 'testImplementation' },
  ]);
});

test('parses declared Dart dependencies and gitignore rules', () => {
  const pubspec = `
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  fake_async: ^1.3.0
`;
  assert.deepEqual(packageDependencies(pubspec), ['fake_async', 'flutter_test', 'http']);
  assert.deepEqual(packageDeclarations(pubspec), [
    { name: 'fake_async', constraint: '^1.3.0', scope: 'development', line: 9 },
    { name: 'flutter_test', constraint: 'sdk: flutter', scope: 'development', line: 7 },
    { name: 'http', constraint: '^1.0.0', scope: 'runtime', line: 5 },
  ]);
  const rules = parseGitIgnore('build/\n*.tmp\n!important.tmp\n');
  assert.equal(rules.length, 3);
  assert.equal(rules[0].regex.test('android/build/generated.txt'), true);
  assert.equal(rules[1].regex.test('notes.tmp'), true);
  assert.equal(rules[2].negated, true);
});

test('scans current project files and resolves verified app structure', async () => {
  const scan = await scanRepository(root);
  assert.ok(scan.files.length >= 100);
  assert.equal(scan.database.schemaVersion, 7);
  assert.ok(scan.database.tables.some((table) => table.name === 'watch_activity'));
  assert.ok(scan.files.some((file) => file.path === 'lib/features/notes/data/browser_note_storage_web.dart'));
  const shell = scan.files.find((file) => file.path === 'lib/features/home/presentation/app_shell.dart');
  assert.ok(shell.screens.some((screen) => screen.name === 'AppShell'));
  assert.ok(shell.routes.length > 0);
  assert.ok(scan.repositoryImplementations.some((implementation) =>
    implementation.contract === 'RoadmapRepository' &&
    implementation.className === 'SqliteRoadmapRepository'));
  assert.ok(scan.dependencies.includes('get_it'));
  assert.ok(scan.platformChannels.some((channel) => channel.name === 'com.voyager/player'));
  assert.equal(scan.repository.name, 'VoyagerM');
  assert.equal(scan.files.some((file) => file.path.startsWith('graphify-out/')), false);
  assert.ok(scan.database.relationships.some((relationship) => relationship.fromTable === 'playlist_entries'));
  assert.ok(scan.nativeDependencies.some((dependency) => dependency.coordinate.startsWith('androidx.media3:')));
  assert.equal(scan.files.some((file) => file.path.includes('.dart_tool/')), false);
  assert.equal(scan.files.some((file) => file.path === 'android/local.properties'), false);
});

test('honors ignore rules and does not read generated or ignored files', async (t) => {
  const temp = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-ignore-'));
  t.after(() => rm(temp, { recursive: true, force: true }));
  await mkdir(path.join(temp, 'build'));
  await mkdir(path.join(temp, 'lib'));
  await writeFile(path.join(temp, '.gitignore'), 'build/\n*.secret\n');
  await writeFile(path.join(temp, 'pubspec.yaml'), 'name: fixture\n');
  await writeFile(path.join(temp, 'build', 'generated.dart'), 'class Generated {}');
  await writeFile(path.join(temp, 'lib', 'main.dart'), 'class App {}');
  await writeFile(path.join(temp, 'lib', 'private.secret'), 'not source');
  const scan = await scanRepository(temp);
  assert.deepEqual(scan.files.map((file) => file.path), ['lib/main.dart', 'pubspec.yaml']);
});
