import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const defaultRoot = path.resolve(scriptDir, '..', '..');
const ignoredDirectories = new Set([
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  '.vscode',
  'build',
  'node_modules',
  'coverage',
  'floorplan',
  'graphify-out',
]);
const extensions = new Map([
  ['.dart', 'Dart'],
  ['.kt', 'Kotlin'],
  ['.kts', 'Kotlin DSL'],
  ['.java', 'Java'],
  ['.js', 'JavaScript'],
  ['.mjs', 'JavaScript'],
  ['.ts', 'TypeScript'],
  ['.html', 'HTML'],
  ['.xml', 'XML'],
  ['.yaml', 'YAML'],
  ['.yml', 'YAML'],
  ['.json', 'JSON'],
  ['.md', 'Markdown'],
  ['.properties', 'Properties'],
  ['.gradle', 'Gradle'],
]);

function posix(filePath) {
  return filePath.split(path.sep).join('/');
}

function lineAt(source, index) {
  let line = 1;
  for (let cursor = 0; cursor < index; cursor += 1) {
    if (source.charCodeAt(cursor) === 10) line += 1;
  }
  return line;
}

function maskCommentsAndStrings(source) {
  const chars = source.split('');
  let state = 'code';
  let quote = '';
  let raw = false;
  let escaped = false;

  for (let index = 0; index < chars.length; index += 1) {
    const current = chars[index];
    const next = chars[index + 1];
    if (state === 'line-comment') {
      if (current === '\n') state = 'code';
      else chars[index] = ' ';
      continue;
    }
    if (state === 'block-comment') {
      if (current === '*' && next === '/') {
        chars[index] = ' ';
        chars[index + 1] = ' ';
        index += 1;
        state = 'code';
      } else if (current !== '\n') {
        chars[index] = ' ';
      }
      continue;
    }
    if (state === 'string') {
      if (current === '\n' && quote.length < 3) {
        state = 'code';
        escaped = false;
      } else if (!raw && escaped) {
        escaped = false;
      } else if (!raw && current === '\\') {
        escaped = true;
      } else if (source.startsWith(quote, index)) {
        for (let offset = 0; offset < quote.length; offset += 1) {
          if (chars[index + offset] !== '\n') chars[index + offset] = ' ';
        }
        index += quote.length - 1;
        state = 'code';
        continue;
      }
      if (current !== '\n') chars[index] = ' ';
      continue;
    }

    if (current === '/' && next === '/') {
      chars[index] = ' ';
      chars[index + 1] = ' ';
      index += 1;
      state = 'line-comment';
    } else if (current === '/' && next === '*') {
      chars[index] = ' ';
      chars[index + 1] = ' ';
      index += 1;
      state = 'block-comment';
    } else if (current === "'" || current === '"') {
      raw = index > 0 && source[index - 1] === 'r';
      const triple = source.startsWith(current.repeat(3), index);
      quote = current.repeat(triple ? 3 : 1);
      if (raw) chars[index - 1] = ' ';
      state = 'string';
    }
  }
  return chars.join('');
}

function parseGitIgnore(contents, base = '') {
  return contents
    .split(/\r?\n/u)
    .map((entry) => entry.trim())
    .filter((entry) => entry && !entry.startsWith('#'))
    .map((entry) => {
      const negated = entry.startsWith('!');
      let pattern = negated ? entry.slice(1) : entry;
      if (!pattern) return null;
      pattern = pattern.replace(/^\/+|\/+$/gu, '');
      const anchored = entry.startsWith('/') || pattern.includes('/');
      const escaped = pattern
        .replace(/[.+^${}()|[\]\\]/gu, '\\$&')
        .replace(/\*\*/gu, '\u0000')
        .replace(/\*/gu, '[^/]*')
        .replace(/\?/gu, '[^/]')
        .replace(/\u0000/gu, '.*');
      const prefix = base ? `${base}/` : '';
      return {
        negated,
        regex: new RegExp(
          anchored
            ? `^${prefix}${escaped}(?:/.*)?$`
            : `(?:^|/)${prefix}${escaped}(?:/.*)?$`,
          'u',
        ),
      };
    })
    .filter(Boolean);
}

function isIgnored(relativePath, isDirectory, rules) {
  const normalized = posix(relativePath);
  if (normalized.split('/').some((part) => ignoredDirectories.has(part))) {
    return true;
  }
  if (normalized === 'pubspec.lock' || normalized === 'android/local.properties') {
    return true;
  }
  if (normalized === 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java') {
    return true;
  }
  let ignored = false;
  for (const rule of rules) {
    if (rule.regex.test(normalized)) ignored = !rule.negated;
  }
  if (ignored) return true;
  if (isDirectory) return false;
  return extensions.has(path.extname(normalized)) ||
    ['README.md', 'TODO.md', 'pubspec.yaml', 'analysis_options.yaml'].includes(normalized)
    ? false
    : true;
}

async function collectFiles(root, directory = '', inheritedRules = []) {
  const absoluteDirectory = path.join(root, directory);
  const entries = await readdir(absoluteDirectory, { withFileTypes: true });
  let rules = inheritedRules;
  const ignorePath = path.join(absoluteDirectory, '.gitignore');
  try {
    rules = [
      ...rules,
      ...parseGitIgnore(await readFile(ignorePath, 'utf8'), posix(directory)),
    ];
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }

  const files = [];
  for (const entry of entries) {
    if (entry.name === '.gitignore') continue;
    const relative = path.join(directory, entry.name);
    if (isIgnored(relative, entry.isDirectory(), rules)) continue;
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(root, relative, rules)));
    } else if (entry.isFile() && extensions.has(path.extname(entry.name))) {
      files.push(posix(relative));
    }
  }
  return files;
}

function packageDeclarations(pubspec) {
  const dependencies = [];
  let section = '';
  const lines = pubspec.split(/\r?\n/u);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const sectionMatch = line.match(/^(dependencies|dev_dependencies):\s*$/u);
    if (sectionMatch) {
      section = sectionMatch[1];
      continue;
    }
    if (/^\S/u.test(line)) {
      section = '';
      continue;
    }
    if (!section) continue;
    const declaration = line.match(/^  ([A-Za-z0-9_]+):(?:\s*(.*))?$/u);
    if (!declaration || declaration[1] === 'flutter') continue;
    const properties = [];
    for (let nested = index + 1; nested < lines.length && /^ {4,}\S/u.test(lines[nested]); nested += 1) {
      const property = lines[nested].trim().replace(/\s+#.*$/u, '');
      if (property) properties.push(property);
    }
    const value = (declaration[2] ?? '').replace(/\s+#.*$/u, '').trim();
    dependencies.push({
      name: declaration[1],
      constraint: [value, ...properties].filter(Boolean).join('; ') || 'unspecified',
      scope: section === 'dependencies' ? 'runtime' : 'development',
      line: index + 1,
    });
  }
  return dependencies.sort((left, right) => left.name.localeCompare(right.name) || left.scope.localeCompare(right.scope));
}

function packageDependencies(pubspec) {
  return [...new Set(packageDeclarations(pubspec).map(({ name }) => name))].sort();
}

function gradleDependencies(source) {
  const dependencies = [];
  const pattern = /^\s*(implementation|api|runtimeOnly|compileOnly|coreLibraryDesugaring|testImplementation|androidTestImplementation)\s*(?:\(\s*)?["']([^"']+)["']\s*\)?/gmu;
  for (const match of source.matchAll(pattern)) {
    const parts = match[2].split(':');
    if (parts.length < 3) continue;
    dependencies.push({
      coordinate: match[2],
      group: parts[0],
      artifact: parts[1],
      version: parts.slice(2).join(':'),
      scope: match[1],
      line: lineAt(source, match.index),
    });
  }
  return dependencies;
}

function classifyFile(filePath) {
  if (filePath.startsWith('lib/core/di/')) return 'composition';
  if (filePath.startsWith('lib/core/database/')) return 'persistence';
  if (filePath.startsWith('lib/core/media/')) return 'media';
  if (filePath.startsWith('lib/core/design/')) return 'design';
  if (filePath.startsWith('lib/core/share/')) return 'sharing';
  if (filePath.startsWith('lib/core/config/')) return 'configuration';
  if (filePath.startsWith('lib/features/')) {
    const [, feature, layer] = filePath.split('/');
    return `feature:${feature}:${layer ?? 'other'}`;
  }
  if (filePath === 'lib/main.dart') return 'application-entry';
  if (filePath.startsWith('test/')) return 'tests';
  if (filePath.startsWith('android/')) return 'android-platform';
  if (filePath.startsWith('web/')) return 'web-platform';
  if (filePath.startsWith('docs/')) return 'documentation';
  if (filePath.startsWith('assets/')) return 'assets';
  return 'configuration';
}

function dartImports(filePath, source, packageName) {
  const imports = [];
  const pattern = /\b(import|export|part)\s+(?:[^;'"]*?\s+)?['"]([^'"]+)['"]/gu;
  for (const match of source.matchAll(pattern)) {
    const specifier = match[2];
    let target = null;
    let external = null;
    if (specifier.startsWith('package:')) {
      const [, packageNameFromUri, rest = ''] = specifier.match(/^package:([^/]+)\/?(.*)$/u) ?? [];
      if (packageNameFromUri === packageName && rest) target = posix(path.join('lib', rest));
      else if (!['flutter', 'dart'].includes(packageNameFromUri)) external = packageNameFromUri;
    } else if (specifier.startsWith('.')) {
      target = posix(path.normalize(path.join(path.dirname(filePath), specifier)));
      if (!path.extname(target)) target += '.dart';
    }
    imports.push({
      kind: match[1],
      specifier,
      target,
      external,
      line: lineAt(source, match.index),
    });
  }
  return imports;
}

function javaImports(source) {
  return [...source.matchAll(/^\s*import\s+(?:static\s+)?([\w.]+)(?:\.\*)?;\s*$/gmu)]
    .map((match) => ({ kind: 'import', specifier: match[1], line: lineAt(source, match.index) }));
}

function dartSymbols(source) {
  const code = maskCommentsAndStrings(source);
  const symbols = [];
  const seen = new Set();
  for (const match of code.matchAll(
    /^\s*(?:(?:abstract|base|final|sealed|interface)\s+)*(class|mixin|enum|extension|typedef)\s+([A-Za-z_]\w*)/gmu,
  )) {
    const key = `${match[1]}:${match[2]}`;
    if (!seen.has(key)) {
      seen.add(key);
      symbols.push({
        kind: match[1],
        name: match[2],
        line: lineAt(code, match.index),
      });
    }
  }
  for (const match of code.matchAll(
    /^\s*(?:(?:static|external|factory|abstract|const|final|late|override|async|sync)\s+)*(?:[\w.$<>?,\[\] ]+\s+)?([A-Za-z_]\w*)\s*(?:<[^>\n]+>)?\s*\(/gmu,
  )) {
    const name = match[1];
    if (new Set(['if', 'for', 'while', 'switch', 'catch', 'assert', 'return', 'super']).has(name)) continue;
    const line = lineAt(code, match.index);
    if (symbols.some((symbol) => symbol.name === name && symbol.line === line)) continue;
    symbols.push({ kind: 'callable', name, line });
  }
  return symbols.sort((left, right) => left.line - right.line);
}

function referencedIdentifiers(source) {
  const code = maskCommentsAndStrings(source);
  return [...new Set(
    [...code.matchAll(/\b[A-Z][A-Za-z0-9_]*\b/gu)].map((match) => match[0]),
  )].sort();
}

function referencedTables(source) {
  const tables = [];
  const pattern = /\b(query|insert|update|delete|upsert)\s*\(\s*['"]([a-z_]\w*)['"]/giu;
  for (const match of source.matchAll(pattern)) {
    tables.push({
      operation: match[1].toLowerCase(),
      name: match[2],
      line: lineAt(source, match.index),
    });
  }
  return tables;
}

function extractDatabase(source) {
  const schemaVersion = source.match(/schemaVersion\s*=\s*(\d+)/u)?.[1];
  const tables = [];
  const relationships = [];
  for (const match of source.matchAll(/CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["'`]?([\w]+)["'`]?\s*\(/giu)) {
    if (!tables.some((table) => table.name === match[1])) {
      tables.push({ name: match[1], line: lineAt(source, match.index) });
    }
    const bodyStart = match.index + match[0].length;
    const closing = source.slice(bodyStart).match(/\r?\n[ \t]*\)(?=\r?\n[ \t]*['"`])/u);
    if (!closing) continue;
    const body = source.slice(bodyStart, bodyStart + closing.index);
    for (const reference of body.matchAll(
      /^\s*([A-Za-z_]\w*)\s+[^,\n]*?\bREFERENCES\s+["'`]?([A-Za-z_]\w*)["'`]?\s*\(\s*([A-Za-z_]\w*)\s*\)/gmu,
    )) {
      relationships.push({
        fromTable: match[1],
        fromColumn: reference[1],
        toTable: reference[2],
        toColumn: reference[3],
        line: lineAt(source, bodyStart + reference.index),
      });
    }
  }
  const migrations = [...source.matchAll(/oldVersion\s*<\s*(\d+)/gu)]
    .map((match) => Number(match[1]))
    .filter((version, index, values) => values.indexOf(version) === index)
    .sort((left, right) => left - right);
  return {
    schemaVersion: schemaVersion ? Number(schemaVersion) : null,
    tables,
    relationships,
    migrations,
  };
}

function routeEvidence(filePath, source) {
  const routes = [];
  const routePatterns = [
    ['navigator-push', /Navigator(?:\.of\([^)]*\))?\.(?:push|pushNamed|pushReplacement|pushReplacementNamed)\s*</gu],
    ['material-route', /MaterialPageRoute(?:<[^>]+>)?\s*\(/gu],
    ['named-routes', /(?:routes|onGenerateRoute)\s*:/gu],
  ];
  for (const [kind, pattern] of routePatterns) {
    for (const match of source.matchAll(pattern)) {
      routes.push({ kind, file: filePath, line: lineAt(source, match.index) });
    }
  }
  return routes;
}

function channelEvidence(source) {
  const channels = [];
  const constants = new Map(
    [...source.matchAll(/\b(?:const\s+val|const)\s+([A-Z][A-Z0-9_]*|_[a-z][A-Za-z0-9_]*)\s*=\s*['"]([^'"]+)['"]/gu)]
      .map((match) => [match[1], match[2]]),
  );
  for (const match of source.matchAll(/\b(MethodChannel|EventChannel|BasicMessageChannel)\s*(?:<[^>]+>)?\s*\(([^)]*)\)/gu)) {
    const literal = match[2].match(/['"]([^'"]+)['"]/u)?.[1];
    const constant = match[2].match(/\b([A-Z][A-Z0-9_]*|_[a-z][A-Za-z0-9_]*)\b/gu)
      ?.map((name) => constants.get(name))
      .find(Boolean);
    const name = literal ?? constant;
    if (name) channels.push({ kind: match[1], name, line: lineAt(source, match.index) });
  }
  return channels;
}

function networkEvidence(source) {
  const hosts = new Set();
  for (const match of source.matchAll(/\bhttps?:\/\/([a-z0-9.-]+)(?::\d+)?/giu)) {
    try {
      hosts.add(new URL(match[0]).hostname.toLowerCase());
    } catch {
      // Invalid URL-like literals are not useful as verified hosts.
    }
  }
  const requests = [];
  const requestPattern = /\b(?:http|client|request|dio)\.(get|post|put|delete|patch|send|openConnection)\s*(?:<[^>]+>)?\s*\(/giu;
  for (const match of source.matchAll(requestPattern)) {
    requests.push({ operation: match[1].toLowerCase(), line: lineAt(source, match.index) });
  }
  return { hosts: [...hosts].sort(), requests };
}

function injectedTypes(source) {
  const registrations = [];
  const pattern = /(?:register(?:LazySingleton|Factory|Singleton)|_registerIfMissing)\s*<\s*([A-Za-z_]\w*)\s*>\s*\(/gu;
  for (const match of source.matchAll(pattern)) {
    const suffix = source.slice(match.index, match.index + 700);
    const implementation = suffix.match(/=>\s*([A-Z]\w*)\s*\(/u)?.[1] ??
      suffix.match(/([A-Z]\w*)\.new/u)?.[1] ??
      suffix.match(/:\s*([A-Z]\w*)\.new/u)?.[1];
    registrations.push({
      contract: match[1],
      implementation: implementation ?? null,
      line: lineAt(source, match.index),
    });
  }
  return registrations;
}

function repositoryImplementations(source, filePath) {
  const implementations = [];
  for (const match of source.matchAll(/\bclass\s+([A-Z]\w*)[\s\S]{0,200}?\bimplements\s+([A-Z]\w*Repository)\b/gu)) {
    implementations.push({
      className: match[1],
      contract: match[2],
      file: filePath,
      line: lineAt(source, match.index),
    });
  }
  return implementations;
}

function fileStats(source) {
  return {
    lines: source.length === 0 ? 0 : source.split(/\r?\n/u).length,
    bytes: Buffer.byteLength(source, 'utf8'),
    fingerprint: createHash('sha256').update(source).digest('hex'),
  };
}

function getGitMetadata(root) {
  try {
    const commit = execFileSync('git', ['rev-parse', '--short=12', 'HEAD'], {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    const branch = execFileSync('git', ['branch', '--show-current'], {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    return { commit, branch: branch || 'detached' };
  } catch {
    return { commit: null, branch: null };
  }
}

function createStructuralSignature(file) {
  return createHash('sha256')
    .update(JSON.stringify({
      imports: file.imports.map(({ specifier, kind }) => [kind, specifier]),
      symbols: file.symbols.map(({ kind, name }) => [kind, name]),
      routes: file.routes.map(({ kind }) => kind),
      tables: file.tables.map(({ name }) => name),
      relationships: file.databaseRelationships,
      registrations: file.registrations.map(({ contract, implementation }) => [contract, implementation]),
      channels: file.channels.map(({ kind, name }) => [kind, name]),
      declaredDependencies: file.declaredDependencies,
    }))
    .digest('hex');
}

export async function scanRepository(root = defaultRoot) {
  const normalizedRoot = path.resolve(root);
  const rootIgnore = await readFile(path.join(normalizedRoot, '.gitignore'), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const filesFound = (await collectFiles(normalizedRoot, '', parseGitIgnore(rootIgnore)))
    .sort((left, right) => left.localeCompare(right));
  const pubspecPath = path.join(normalizedRoot, 'pubspec.yaml');
  const pubspec = await readFile(pubspecPath, 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const packageName = pubspec.match(/^name:\s*([A-Za-z0-9_]+)/mu)?.[1] ?? '';
  const declaredDependencies = packageDeclarations(pubspec);
  const dependencies = [...new Set(declaredDependencies.map(({ name }) => name))].sort();
  const files = [];
  const warnings = [];

  for (const filePath of filesFound) {
    const absolute = path.join(normalizedRoot, filePath);
    const info = await stat(absolute);
    if (info.size > 2_000_000) {
      warnings.push({ file: filePath, message: 'File skipped because it exceeds the 2 MB text-analysis limit.' });
      continue;
    }
    const source = await readFile(absolute, 'utf8');
    const language = extensions.get(path.extname(filePath)) ?? 'Text';
    const isDart = path.extname(filePath) === '.dart';
    const imports = isDart ? dartImports(filePath, source, packageName) :
      ['.kt', '.kts', '.java'].includes(path.extname(filePath)) ? javaImports(source) : [];
    const declarations = isDart ? dartSymbols(source) : [];
    const screenSymbols = isDart
      ? declarations.filter(({ kind, name }) =>
        kind === 'class' && /\b(?:StatefulWidget|StatelessWidget)\b/u.test(source.slice(
          source.indexOf(`class ${name}`),
          source.indexOf(`class ${name}`) + 500,
        )) && /(?:Page|Screen|Showcase|Shell|App)$/u.test(name))
      : [];
    const routing = isDart ? routeEvidence(filePath, source) : [];
    const isSourceCode = ['Dart', 'Kotlin', 'Kotlin DSL', 'Java', 'JavaScript', 'TypeScript'].includes(language) &&
      !filePath.startsWith('test/');
    const channels = isSourceCode ? channelEvidence(source) : [];
    const network = isSourceCode ? networkEvidence(source) : { hosts: [], requests: [] };
    const isDatabase = filePath.endsWith('/database.dart') && filePath.includes('lib/core/database/');
    const database = isDatabase ? extractDatabase(source) : null;
    const nativeDependencies = ['.gradle', '.kts'].includes(path.extname(filePath)) &&
      filePath.startsWith('android/')
      ? gradleDependencies(source)
      : [];
    const registrations = isDart ? injectedTypes(source) : [];
    const repositories = isDart ? repositoryImplementations(source, filePath) : [];
    const structural = {
      imports,
      symbols: declarations,
      routes: routing,
      tables: database?.tables ?? [],
      databaseRelationships: database?.relationships ?? [],
      registrations,
      declaredDependencies: filePath === 'pubspec.yaml' ? declaredDependencies : [],
      nativeDependencies,
      channels,
    };
    const file = {
      path: filePath,
      language,
      classification: classifyFile(filePath),
      ...fileStats(source),
      imports,
      symbols: declarations,
      screens: screenSymbols.map(({ name, line }) => ({ name, line })),
      routes: routing,
      channels,
      networkHosts: network.hosts,
      networkRequests: network.requests,
      referencedTables: referencedTables(source),
      referencedIdentifiers: isDart ? referencedIdentifiers(source) : [],
      tables: database?.tables ?? [],
      schemaVersion: database?.schemaVersion ?? null,
      databaseRelationships: database?.relationships ?? [],
      registrations,
      declaredDependencies: filePath === 'pubspec.yaml' ? declaredDependencies : [],
      nativeDependencies,
      repositoryImplementations: repositories,
    };
    file.structuralSignature = createStructuralSignature(structural);
    files.push(file);
  }

  const paths = new Set(files.map((file) => file.path));
  for (const file of files) {
    for (const dependency of file.imports) {
      if (dependency.target && !paths.has(dependency.target)) {
        warnings.push({
          file: file.path,
          line: dependency.line,
          message: `Resolved import was not found: ${dependency.specifier}`,
        });
      }
    }
  }

  const allTables = files.flatMap((file) => file.tables.map((table) => ({ ...table, file: file.path })));
  const registrations = files.flatMap((file) => file.registrations.map((item) => ({ ...item, file: file.path })));
  const repositoryImplementationsFound = files.flatMap((file) => file.repositoryImplementations);
  const hosts = [...new Set(files.flatMap((file) => file.networkHosts))].sort();
  const channels = files.flatMap((file) => file.channels.map((channel) => ({ ...channel, file: file.path })));
  const nativeDependencyRecords = files.flatMap((file) => file.nativeDependencies.map((dependency) => ({
    ...dependency,
    file: file.path,
  })));

  return {
    schemaVersion: 2,
    repository: {
      name: packageName === 'voyager_learning' ? 'VoyagerM' : path.basename(normalizedRoot),
      ...getGitMetadata(normalizedRoot),
    },
    generatedAt: new Date().toISOString(),
    packageName,
    files,
    dependencies,
    declaredDependencies,
    nativeDependencies: nativeDependencyRecords,
    database: {
      schemaVersion: files.find((file) => file.schemaVersion !== null)?.schemaVersion ?? null,
      tables: allTables,
      relationships: files.flatMap((file) => file.databaseRelationships.map((relationship) => ({
        ...relationship,
        file: file.path,
      }))),
    },
    dependencyRegistrations: registrations,
    repositoryImplementations: repositoryImplementationsFound,
    networkHosts: hosts,
    platformChannels: channels,
    statistics: {
      fileCount: files.length,
      codeFileCount: files.filter((file) =>
        ['Dart', 'Kotlin', 'Kotlin DSL', 'Java', 'JavaScript', 'TypeScript'].includes(file.language)).length,
      linesOfCode: files
        .filter((file) => ['Dart', 'Kotlin', 'Kotlin DSL', 'Java', 'JavaScript', 'TypeScript'].includes(file.language))
        .reduce((total, file) => total + file.lines, 0),
      languages: Object.fromEntries([...new Set(files.map((file) => file.language))]
        .sort()
        .map((language) => [language, files.filter((file) => file.language === language).length])),
    },
    warnings,
  };
}

export {
  channelEvidence,
  classifyFile,
  dartImports,
  dartSymbols,
  extractDatabase,
  injectedTypes,
  gradleDependencies,
  isIgnored,
  packageDeclarations,
  packageDependencies,
  parseGitIgnore,
  referencedIdentifiers,
  referencedTables,
  repositoryImplementations,
  routeEvidence,
};

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const rootArgument = process.argv[2] && !process.argv[2].startsWith('--')
    ? process.argv[2]
    : defaultRoot;
  const result = await scanRepository(rootArgument);
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}
