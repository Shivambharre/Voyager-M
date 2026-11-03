import { mkdir, readFile, readdir, rename, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getComponentDefinitions, getModuleForPath, getPackageLabel, getWorkflows } from './architecture.mjs';
import { scanRepository } from './analyze.mjs';
import { runHealthChecks } from './health.mjs';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const floorplanDir = path.resolve(scriptDir, '..');
const defaultRoot = path.resolve(floorplanDir, '..');
const cacheDir = path.join(floorplanDir, '.cache');
const fileId = (filePath) => `file:${filePath}`;
const externalId = (name) => `external:${name}`;
const safeJson = (value) => `${JSON.stringify(value, null, 2)}\n`;
const encodePath = (filePath) => Buffer.from(filePath, 'utf8').toString('base64url');

function descriptionRole(file) {
  const moduleId = getModuleForPath(file.path);
  const layer = file.classification.split(':').at(-1);
  const names = file.symbols
    .filter((symbol) => ['class', 'abstract', 'mixin', 'enum', 'extension'].includes(symbol.kind))
    .map((symbol) => symbol.name);
  const primaryName = names[0] ?? path.basename(file.path, path.extname(file.path));
  const directory = file.path.split('/').slice(-2, -1)[0] ?? 'project';
  const moduleNames = {
    runtime: 'application setup',
    persistence: 'database boundary',
    media: 'media pipeline',
    design: 'shared visual system',
    sharing: 'shared-link integration',
    configuration: 'build-time configuration',
    tests: 'automated tests',
    web: 'web platform configuration',
    android: 'Android platform integration',
    'project-config': 'project documentation and configuration',
  };
  const scope = moduleNames[moduleId] ?? `${directory.replaceAll('_', ' ')} feature`;
  if (file.path === 'lib/main.dart') {
    return {
      name: 'Application entry point',
      simple: 'Starts Flutter, prepares app services and saved preferences, then shows the main VoyagerM interface.',
      developer: 'Initializes Flutter bindings, calls configureDependencies(), loads SettingsRepository, and constructs VoyagerApp.',
    };
  }
  if (file.path.endsWith('service_locator.dart')) {
    return {
      name: 'Dependency composition root',
      simple: 'Connects app-owned service contracts to the correct local storage and media implementations.',
      developer: 'Registers GetIt factories/singletons, selects in-memory versus SQLite repositories, and configures PlaybackController.',
    };
  }
  if (file.path.endsWith('database.dart')) {
    return {
      name: 'SQLite schema and adapter',
      simple: 'Defines the local database contract, tables, transactions, and schema upgrades.',
      developer: `Implements AppDatabase through sqflite; the current schema is version ${file.schemaVersion ?? 'unknown'} and its migrations are extracted from the source.`,
    };
  }
  if (file.path.includes('/domain/') && names.some((name) => name.endsWith('Repository'))) {
    return {
      name: `${primaryName} contract`,
      simple: `Defines the operations that the ${directory.replaceAll('_', ' ')} feature needs without choosing a storage engine.`,
      developer: `Declares the ${names.join(', ')} app-owned contract; implementations are registered in the composition root.`,
    };
  }
  if (file.path.includes('/data/')) {
    const repositoryType = file.path.includes('sqlite')
      ? 'SQLite-backed repository'
      : file.path.includes('in_memory')
        ? 'in-memory repository'
        : file.path.includes('browser')
          ? 'browser storage adapter'
          : 'feature data adapter';
    const tables = file.referencedTables.map((table) => table.name);
    return {
      name: `${primaryName} data adapter`,
      simple: `Implements or supports the ${directory.replaceAll('_', ' ')} feature’s local data access${tables.length ? ` for ${[...new Set(tables)].join(', ')}` : ''}.`,
      developer: `${repositoryType} in the ${directory.replaceAll('_', ' ')} feature. ${tables.length ? `Observed database tables: ${[...new Set(tables)].join(', ')}.` : 'Storage calls are delegated through the feature boundary.'}`,
    };
  }
  if (file.screens.length > 0) {
    const screenNames = file.screens.map((screen) => screen.name);
    return {
      name: screenNames[0],
      simple: `Presents the ${directory.replaceAll('_', ' ')} experience and forwards user actions to the app’s domain or repository contracts.`,
      developer: `Flutter presentation code in ${scope}; detected screen/widget types: ${screenNames.join(', ')}.`,
    };
  }
  if (file.path.startsWith('test/')) {
    return {
      name: `${primaryName.replaceAll('_', ' ')} test`,
      simple: `Checks selected behavior around ${directory.replaceAll('_', ' ')} using controlled inputs instead of relying on live services.`,
      developer: `Test source with ${file.symbols.filter((symbol) => symbol.kind === 'callable').length} detected test/helper declarations and ${file.imports.length} imports.`,
    };
  }
  if (file.path.startsWith('docs/')) {
    return {
      name: `${primaryName.replaceAll('-', ' ')} documentation`,
      simple: `Explains project behavior and development guidance for ${primaryName.replaceAll('-', ' ')}; statements should be checked against current code.`,
      developer: `Markdown documentation file. It is context, not execution evidence; the map cross-checks claims against scanned source and tests.`,
    };
  }
  if (file.path.startsWith('android/') || file.path.startsWith('web/')) {
    return {
      name: `${primaryName.replaceAll('_', ' ')} platform configuration`,
      simple: `Configures the ${file.path.startsWith('android/') ? 'Android' : 'Web'} build or runtime integration used by VoyagerM.`,
      developer: `${file.language} platform/configuration file associated with ${scope}.`,
    };
  }
  return {
    name: primaryName.replaceAll('_', ' '),
    simple: `Supports the ${scope} by defining ${names.length ? names.join(', ') : 'project configuration or documentation'}.`,
    developer: `${file.language} file classified as ${file.classification}; detected declarations: ${names.length ? names.join(', ') : 'none'}.`,
  };
}

function moduleStatusForFile(file, component) {
  if (file.path.startsWith('docs/')) return 'Unverified';
  if (component.status === 'Partial' && file.path.startsWith('lib/features/progress/')) return 'Partial';
  if (file.path.startsWith('test/')) return 'Implemented';
  return component.status === 'Verified in part' ? 'Unverified' : component.status;
}

function createDescription(file, component, prior, preserve) {
  if (prior && preserve) {
    return {
      ...prior,
      sourcePath: file.path,
      lastScannedFingerprint: file.fingerprint,
      dependencies: file.imports
        .filter((item) => item.target)
        .map((item) => item.target),
      symbols: file.symbols,
      screens: file.screens,
      status: moduleStatusForFile(file, component),
    };
  }
  const role = descriptionRole(file);
  return {
    schemaVersion: 1,
    sourcePath: file.path,
    name: role.name,
    simple: role.simple,
    developer: role.developer,
    responsibility: component.summary,
    status: moduleStatusForFile(file, component),
    importantDependencies: file.imports
      .filter((item) => item.target || item.external)
      .map((item) => item.target ?? `package:${item.external}`),
    dependencies: file.imports.filter((item) => item.target).map((item) => item.target),
    dependents: [],
    symbols: file.symbols,
    screens: file.screens,
    notes: component.notes ?? [],
    lastScannedFingerprint: file.fingerprint,
  };
}

function createEdge(source, target, type, evidence, label) {
  return {
    id: `${type}:${source}->${target}:${evidence.file}:${evidence.line ?? 0}`,
    source,
    target,
    type,
    label,
    evidence: [{
      file: evidence.file,
      line: evidence.line ?? null,
      detail: evidence.detail,
    }],
    confidence: evidence.confidence ?? 'verified',
  };
}

function addEdge(edges, edge) {
  if (!edges.has(edge.id)) edges.set(edge.id, edge);
}

function buildGraph(scan, components, descriptions) {
  const nodes = [];
  const edges = new Map();
  const componentMap = new Map(components.map((component) => [component.id, component]));
  const filesByPath = new Map(scan.files.map((file) => [file.path, file]));

  nodes.push({
    id: 'app',
    parentId: null,
    name: scan.repository.name || 'VoyagerM',
    kind: 'application',
    type: 'application',
    summary: 'A local-first Flutter learning app for roadmaps, saved learning material, notes, and supported media playback.',
    developerSummary: 'Flutter/Dart client with a GetIt composition root, repository contracts, local SQLite/in-memory storage, and platform-specific media services.',
    status: 'Implemented',
    path: null,
  });
  for (const component of components) {
    nodes.push({
      ...component,
      type: 'component',
      path: component.path || null,
      files: scan.files.filter((file) => getModuleForPath(file.path) === component.id).map((file) => file.path),
    });
  }

  for (const file of scan.files) {
    const parentId = getModuleForPath(file.path);
    const description = descriptions.get(file.path);
    const fileNode = {
      id: fileId(file.path),
      parentId,
      name: description?.name ?? path.basename(file.path),
      kind: componentMap.get(parentId)?.kind ?? 'configuration',
      type: 'file',
      path: file.path,
      language: file.language,
      lines: file.lines,
      bytes: file.bytes,
      fingerprint: file.fingerprint,
      structuralSignature: file.structuralSignature,
      summary: description?.simple ?? '',
      developerSummary: description?.developer ?? '',
      status: description?.status ?? 'Unverified',
      symbols: file.symbols,
      screens: file.screens,
      routes: file.routes,
      dependencies: file.imports.filter((item) => item.target).map((item) => item.target),
      dependents: [],
    };
    nodes.push(fileNode);
    for (const symbol of file.symbols) {
      nodes.push({
        id: `symbol:${encodePath(file.path)}:${symbol.line}:${encodeURIComponent(symbol.name)}`,
        parentId: fileNode.id,
        name: symbol.name,
        kind: symbol.kind === 'callable' ? 'domain' : 'configuration',
        type: 'symbol',
        path: file.path,
        line: symbol.line,
        summary: `${symbol.kind} declaration in ${file.path}.`,
        developerSummary: `${symbol.kind} ${symbol.name} declared at ${file.path}:${symbol.line}.`,
        status: fileNode.status,
        symbolKind: symbol.kind,
      });
    }
  }

  const externalGroupId = 'integrations';
  nodes.push({
    id: externalGroupId,
    parentId: 'app',
    name: 'External dependencies & services',
    kind: 'external',
    type: 'component',
    summary: 'Third-party packages and outside services named or imported by the project.',
    developerSummary: 'Declared package dependencies and service references found in current source; not a backend boundary.',
    status: 'Implemented',
    path: null,
    files: [],
  });
  const packageNodeIds = new Map();
  for (const declaration of scan.declaredDependencies) {
    const packageName = declaration.name;
    const id = `package:${packageName}`;
    packageNodeIds.set(packageName, id);
    nodes.push({
      id,
      parentId: externalGroupId,
      name: getPackageLabel(packageName),
      kind: 'external',
      type: 'package',
      summary: `Declared package dependency: ${packageName} (${declaration.constraint}).`,
      developerSummary: `${declaration.scope} dependency declared in pubspec.yaml: ${packageName} ${declaration.constraint}.`,
      status: 'Implemented',
      path: 'pubspec.yaml',
      scope: declaration.scope,
      constraint: declaration.constraint,
    });
  }

  const nativePackageNodeIds = new Map();
  for (const dependency of scan.nativeDependencies) {
    const id = `package:gradle:${dependency.coordinate}`;
    if (nativePackageNodeIds.has(dependency.coordinate)) continue;
    nativePackageNodeIds.set(dependency.coordinate, id);
    nodes.push({
      id,
      parentId: externalGroupId,
      name: `${dependency.artifact} · ${dependency.version}`,
      kind: 'external',
      type: 'package',
      summary: `Android Gradle dependency: ${dependency.coordinate}.`,
      developerSummary: `${dependency.scope} dependency declared in ${dependency.file}:${dependency.line}.`,
      status: 'Implemented',
      path: dependency.file,
      coordinate: dependency.coordinate,
      scope: dependency.scope,
    });
  }

  const tableNodeIds = new Map();
  for (const table of scan.database.tables) {
    const id = `table:${table.name}`;
    tableNodeIds.set(table.name, id);
    nodes.push({
      id,
      parentId: 'persistence',
      name: table.name,
      kind: 'data',
      type: 'table',
      summary: `SQLite table declared in the app schema at ${table.file}:${table.line}.`,
      developerSummary: `Table in schema version ${scan.database.schemaVersion}; relations are extracted only where SQL declares them.`,
      status: 'Implemented',
      path: table.file,
      line: table.line,
    });
  }

  const serviceNodes = new Map();
  const serviceNames = new Set(components.flatMap((component) => component.external ?? []));
  for (const host of scan.networkHosts) serviceNames.add(host);
  for (const serviceName of serviceNames) {
    const id = externalId(serviceName);
    serviceNodes.set(serviceName.toLowerCase(), id);
    const parentId = /sqlite/i.test(serviceName)
      ? 'persistence'
      : /media3|newpipe|android/i.test(serviceName)
        ? 'android'
        : /youtube|open.?courseware|mit/i.test(serviceName)
          ? 'media'
          : externalGroupId;
    nodes.push({
      id,
      parentId,
      name: serviceName,
      kind: 'external',
      type: 'service',
      summary: `External service or host referenced by verified configuration or source.`,
      developerSummary: `Service label grounded in architecture metadata or a literal host; no server/API is inferred from this label.`,
      status: 'Implemented',
      path: null,
    });
  }

  const channelsByName = new Map();
  for (const channel of scan.platformChannels) {
    if (channelsByName.has(channel.name)) continue;
    const id = `channel:${encodeURIComponent(channel.name)}`;
    channelsByName.set(channel.name, id);
    nodes.push({
      id,
      parentId: 'android',
      name: channel.name,
      kind: 'infrastructure',
      type: 'channel',
      summary: 'Named Flutter/native platform channel used to exchange method or event messages.',
      developerSummary: `Channel name found in ${channel.file}:${channel.line}; the matching endpoint is shown where both sides register the same name.`,
      status: 'Implemented',
      path: channel.file,
    });
  }

  for (const file of scan.files) {
    const sourceId = fileId(file.path);
    for (const dependency of file.declaredDependencies) {
      const target = packageNodeIds.get(dependency.name);
      if (!target) continue;
      addEdge(edges, createEdge(sourceId, target, 'dependency', {
        file: file.path,
        line: dependency.line,
        detail: `${dependency.name} ${dependency.constraint} (${dependency.scope})`,
      }, 'declares package'));
    }

    for (const dependency of file.nativeDependencies) {
      const target = nativePackageNodeIds.get(dependency.coordinate);
      if (!target) continue;
      addEdge(edges, createEdge(sourceId, target, 'dependency', {
        file: file.path,
        line: dependency.line,
        detail: `${dependency.scope}("${dependency.coordinate}")`,
      }, 'declares package'));
    }

    for (const dependency of file.imports) {
      if (dependency.target && filesByPath.has(dependency.target)) {
        addEdge(edges, createEdge(sourceId, fileId(dependency.target), 'import', {
          file: file.path,
          line: dependency.line,
          detail: `${dependency.kind} ${dependency.specifier}`,
        }, 'imports'));
      } else if (dependency.external && packageNodeIds.has(dependency.external)) {
        addEdge(edges, createEdge(sourceId, packageNodeIds.get(dependency.external), 'dependency', {
          file: file.path,
          line: dependency.line,
          detail: `Imports declared package ${dependency.external}`,
        }, 'uses package'));
      }

      for (const relationship of scan.database.relationships) {
        const source = tableNodeIds.get(relationship.fromTable);
        const target = tableNodeIds.get(relationship.toTable);
        if (!source || !target) continue;
        addEdge(edges, createEdge(source, target, 'data', {
          file: relationship.file,
          line: relationship.line,
          detail: `${relationship.fromTable}.${relationship.fromColumn} REFERENCES ${relationship.toTable}.${relationship.toColumn}`,
        }, 'foreign key'));
      }

      if (!dependency.target || !filesByPath.has(dependency.target)) continue;
      const targetFile = filesByPath.get(dependency.target);
      const usedSymbols = targetFile.symbols.filter((symbol) =>
        ['class', 'mixin', 'enum'].includes(symbol.kind) &&
        file.referencedIdentifiers.includes(symbol.name));
      for (const symbol of usedSymbols) {
        if (targetFile.screens.some((screen) => screen.name === symbol.name) &&
            file.routes.length > 0) {
          addEdge(edges, createEdge(sourceId, fileId(targetFile.path), 'navigation', {
            file: file.path,
            line: file.routes[0].line,
            detail: `Navigation expression and reference to ${symbol.name}`,
            confidence: 'source-reference',
          }, `opens ${symbol.name}`));
        }
      }
    }

    for (const reference of file.referencedTables) {
      const target = tableNodeIds.get(reference.name);
      if (!target) continue;
      addEdge(edges, createEdge(sourceId, target, 'data', {
        file: file.path,
        line: reference.line,
        detail: `${reference.operation}("${reference.name}") in database repository code`,
      }, reference.operation));
    }

    for (const channel of file.channels) {
      addEdge(edges, createEdge(sourceId, channelsByName.get(channel.name), 'platform-integration', {
        file: file.path,
        line: channel.line,
        detail: `${channel.kind}("${channel.name}")`,
      }, 'platform channel'));
    }

    if (file.networkRequests.length > 0) {
      for (const host of file.networkHosts) {
        const target = serviceNodes.get(host.toLowerCase());
        if (!target) continue;
        addEdge(edges, createEdge(sourceId, target, 'http', {
          file: file.path,
          line: file.networkRequests[0].line,
          detail: `Network request detected; host literal: ${host}`,
          confidence: 'source-reference',
        }, file.networkRequests[0].operation));
      }
    }
  }

  for (const registration of scan.dependencyRegistrations) {
    if (!registration.implementation) continue;
    const implementation = scan.repositoryImplementations.find((item) =>
      item.className === registration.implementation);
    if (!implementation) continue;
    const contract = scan.files.find((file) =>
      file.symbols.some((symbol) => symbol.name === registration.contract));
    if (!contract) continue;
    addEdge(edges, createEdge(
      fileId(registration.file),
      fileId(implementation.file),
      'service',
      {
        file: registration.file,
        line: registration.line,
        detail: `GetIt registration maps ${registration.contract} to ${registration.implementation}`,
      },
      'registers',
    ));
    addEdge(edges, createEdge(
      fileId(implementation.file),
      fileId(contract.path),
      'service',
      {
        file: implementation.file,
        line: implementation.line,
        detail: `${registration.implementation} implements ${registration.contract}`,
      },
      'implements',
    ));
  }

  const channelEndpoints = new Map();
  for (const file of scan.files) {
    for (const channel of file.channels) {
      const endpoints = channelEndpoints.get(channel.name) ?? [];
      endpoints.push({ file, channel });
      channelEndpoints.set(channel.name, endpoints);
    }
  }
  for (const [channelName, endpoints] of channelEndpoints) {
    if (endpoints.length < 2) continue;
    const dart = endpoints.find(({ file }) => file.language === 'Dart');
    const native = endpoints.find(({ file }) => file.language === 'Kotlin');
    if (!dart || !native) continue;
    addEdge(edges, createEdge(fileId(dart.file.path), fileId(native.file.path), 'platform-integration', {
      file: dart.file.path,
      line: dart.channel.line,
      detail: `Dart and Kotlin register the matching channel "${channelName}"`,
    }, 'bridges to native'));
  }

  for (const serviceName of serviceNames) {
    const lower = serviceName.toLowerCase();
    const candidatePath = lower.includes('youtube')
      ? 'lib/core/media/newpipe_youtube_adapter.dart'
      : lower.includes('courseware') || lower.includes('mit')
        ? 'lib/core/media/mit_ocw_adapter.dart'
        : lower.includes('media3')
          ? 'android/app/src/main/kotlin/com/voyager/voyager_learning/MainActivity.kt'
          : lower.includes('newpipe')
            ? 'lib/core/media/newpipe_youtube_adapter.dart'
            : lower.includes('sqlite')
              ? 'lib/core/database/database.dart'
              : null;
    const file = candidatePath ? filesByPath.get(candidatePath) : null;
    const target = serviceNodes.get(lower);
    if (!file || !target) continue;
    const symbol = file.symbols.find((item) => item.kind === 'class') ?? file.symbols[0];
    addEdge(edges, createEdge(fileId(file.path), target, 'service', {
      file: file.path,
      line: symbol?.line ?? null,
      detail: `Source component is the adapter or implementation for ${serviceName}`,
    }, 'integrates with'));
  }

  const edgeList = [...edges.values()];
  const componentEdges = new Map();
  for (const edge of edgeList) {
    const sourceNode = nodes.find((node) => node.id === edge.source);
    const targetNode = nodes.find((node) => node.id === edge.target);
    if (!sourceNode || !targetNode || !sourceNode.parentId || !targetNode.parentId) continue;
    if (sourceNode.parentId === targetNode.parentId) continue;
    const key = `${sourceNode.parentId}->${targetNode.parentId}:${edge.type}`;
    const current = componentEdges.get(key) ?? {
      id: `aggregate:${key}`,
      source: sourceNode.parentId,
      target: targetNode.parentId,
      type: edge.type,
      label: edge.type,
      count: 0,
      evidence: [],
      confidence: 'aggregated from verified file relationships',
    };
    current.count += 1;
    if (current.evidence.length < 3) current.evidence.push(...edge.evidence);
    componentEdges.set(key, current);
  }

  const allEdges = [...edgeList, ...componentEdges.values()];
  const outgoing = new Map();
  const incoming = new Map();
  for (const edge of allEdges) {
    outgoing.set(edge.source, [...(outgoing.get(edge.source) ?? []), edge]);
    incoming.set(edge.target, [...(incoming.get(edge.target) ?? []), edge]);
  }
  for (const node of nodes) {
    node.outgoing = outgoing.get(node.id) ?? [];
    node.incoming = incoming.get(node.id) ?? [];
    if (node.type === 'file') {
      node.dependents = [...new Set(node.incoming
        .filter((edge) => edge.type === 'import')
        .map((edge) => nodes.find((candidate) => candidate.id === edge.source)?.path)
        .filter(Boolean))];
    }
  }

  const componentSummaries = components.map((component) => ({
    ...component,
    files: scan.files.filter((file) => getModuleForPath(file.path) === component.id).map((file) => file.path),
    incoming: componentEdges.size
      ? [...componentEdges.values()].filter((edge) => edge.target === component.id)
      : [],
    outgoing: componentEdges.size
      ? [...componentEdges.values()].filter((edge) => edge.source === component.id)
      : [],
  }));
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    repository: scan.repository,
    nodes,
    edges: allEdges,
    components: componentSummaries,
    workflows: getWorkflows(),
    searchIndex: nodes
      .filter((node) => node.type !== 'component' || node.id !== 'integrations')
      .map((node) => ({
        id: node.id,
        name: node.name,
        path: node.path,
        kind: node.kind,
        type: node.type,
        parentId: node.parentId,
        symbols: node.symbols?.map((symbol) => symbol.name) ?? [],
        searchText: [
          node.name,
          node.summary,
          node.developerSummary,
          node.path,
          ...(node.symbols?.map((symbol) => symbol.name) ?? []),
        ].filter(Boolean).join(' ').toLowerCase(),
      })),
  };
}

function symbolsFrom(file) {
  return file.symbols.map((symbol) => `${symbol.kind}:${symbol.name}`).sort();
}

function setDifference(left, right) {
  return [...left].filter((value) => !right.has(value)).sort();
}

export function buildRecentWork(previous, current) {
  if (!previous) {
    return {
      schemaVersion: 1,
      generatedAt: new Date().toISOString(),
      baseline: true,
      summary: 'Initial architecture snapshot; no earlier scan was available for comparison.',
      changes: [],
      affectedComponents: [],
    };
  }
  const previousFiles = new Map(previous.files.map((file) => [file.path, file]));
  const currentFiles = new Map(current.files.map((file) => [file.path, file]));
  const removed = [...previousFiles.values()].filter((file) => !currentFiles.has(file.path));
  const added = [...currentFiles.values()].filter((file) => !previousFiles.has(file.path));
  const changes = [];
  const matchedAdded = new Set();
  const matchedRemoved = new Set();

  for (const oldFile of removed) {
    const match = added.find((file) =>
      !matchedAdded.has(file.path) && file.fingerprint === oldFile.fingerprint);
    if (!match) continue;
    matchedAdded.add(match.path);
    matchedRemoved.add(oldFile.path);
    changes.push({
      type: 'renamed',
      from: oldFile.path,
      path: match.path,
      reason: null,
      affectedComponents: [...new Set([getModuleForPath(oldFile.path), getModuleForPath(match.path)])],
      changedSymbols: { added: [], removed: [] },
    });
  }
  for (const file of added) {
    if (matchedAdded.has(file.path)) continue;
    changes.push({
      type: 'added',
      path: file.path,
      reason: null,
      affectedComponents: [getModuleForPath(file.path)],
      changedSymbols: { added: symbolsFrom(file), removed: [] },
    });
  }
  for (const file of removed) {
    if (matchedRemoved.has(file.path)) continue;
    changes.push({
      type: 'deleted',
      path: file.path,
      reason: null,
      affectedComponents: [getModuleForPath(file.path)],
      changedSymbols: { added: [], removed: symbolsFrom(file) },
    });
  }
  for (const [filePath, file] of currentFiles) {
    const oldFile = previousFiles.get(filePath);
    if (!oldFile || oldFile.fingerprint === file.fingerprint) continue;
    const oldSymbols = new Set(symbolsFrom(oldFile));
    const newSymbols = new Set(symbolsFrom(file));
    const changedSymbols = {
      added: setDifference(newSymbols, oldSymbols),
      removed: setDifference(oldSymbols, newSymbols),
    };
    const structureChanged = oldFile.structuralSignature !== file.structuralSignature;
    changes.push({
      type: 'modified',
      path: filePath,
      reason: null,
      affectedComponents: [getModuleForPath(filePath)],
      structuralChange: structureChanged,
      changedSymbols,
      routesChanged: {
        before: oldFile.routes.map((route) => route.kind),
        after: file.routes.map((route) => route.kind),
      },
        dependenciesChanged: {
        added: setDifference(
            new Set([
              ...file.imports.map((item) => `import:${item.specifier}`),
              ...(file.declaredDependencies ?? []).map((item) => `package:${item.name} ${item.constraint}`),
              ...(file.nativeDependencies ?? []).map((item) => `gradle:${item.coordinate}`),
            ]),
            new Set([
              ...oldFile.imports.map((item) => `import:${item.specifier}`),
              ...(oldFile.declaredDependencies ?? []).map((item) => `package:${item.name} ${item.constraint}`),
              ...(oldFile.nativeDependencies ?? []).map((item) => `gradle:${item.coordinate}`),
            ]),
          ),
          removed: setDifference(
            new Set([
              ...oldFile.imports.map((item) => `import:${item.specifier}`),
              ...(oldFile.declaredDependencies ?? []).map((item) => `package:${item.name} ${item.constraint}`),
              ...(oldFile.nativeDependencies ?? []).map((item) => `gradle:${item.coordinate}`),
            ]),
            new Set([
              ...file.imports.map((item) => `import:${item.specifier}`),
              ...(file.declaredDependencies ?? []).map((item) => `package:${item.name} ${item.constraint}`),
              ...(file.nativeDependencies ?? []).map((item) => `gradle:${item.coordinate}`),
            ]),
          ),
        },
    });
  }

  changes.sort((left, right) =>
    left.path.localeCompare(right.path) || left.type.localeCompare(right.type));
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    baseline: false,
    summary: `${changes.length} file-level change${changes.length === 1 ? '' : 's'} detected since the previous scan.`,
    changes,
    affectedComponents: [...new Set(changes.flatMap((change) => change.affectedComponents))].sort(),
  };
}

export function validateArchitecture(architecture, graph, scan) {
  const errors = [];
  const ids = new Set();
  for (const node of architecture.components) {
    if (ids.has(node.id)) errors.push(`Duplicate component ID: ${node.id}`);
    ids.add(node.id);
    if (node.parentId && node.parentId !== 'app' &&
        !architecture.components.some((candidate) => candidate.id === node.parentId)) {
      errors.push(`Missing component parent for ${node.id}: ${node.parentId}`);
    }
  }
  for (const file of scan.files) {
    if (!architecture.fileAssignments[file.path]) errors.push(`Unassigned file: ${file.path}`);
  }
  const graphIds = new Set(graph.nodes.map((node) => node.id));
  for (const edge of graph.edges) {
    if (!graphIds.has(edge.source)) errors.push(`Unknown edge source: ${edge.source}`);
    if (!graphIds.has(edge.target)) errors.push(`Unknown edge target: ${edge.target}`);
    if (!edge.evidence?.length) errors.push(`Edge has no source evidence: ${edge.id}`);
  }
  const codeFiles = scan.files.filter((file) => file.language === 'Dart' || file.language === 'Kotlin');
  const unassigned = codeFiles.filter((file) => !architecture.fileAssignments[file.path]).length;
  const unassignedRatio = codeFiles.length === 0 ? 0 : unassigned / codeFiles.length;
  if (unassignedRatio >= 0.1) errors.push(`Unassigned code file ratio is ${(unassignedRatio * 100).toFixed(1)}%.`);
  return { valid: errors.length === 0, errors, unassignedCodeRatio: unassignedRatio };
}

export function sanitizeForExport(model, options = {}) {
  const includeFlows = options.includeFlows !== false;
  const includeNotes = options.includeNotes !== false;
  const includeRecentWork = options.includeRecentWork !== false;
  const includeHealth = options.includeHealth !== false;
  const clone = structuredClone(model);
  if (!includeFlows) clone.graph.workflows = [];
  if (!includeNotes) {
    clone.architecture.components = clone.architecture.components.map((component) => ({
      ...component,
      notes: [],
    }));
    clone.graph.nodes = clone.graph.nodes.map((node) => ({ ...node, notes: [] }));
  }
  if (!includeRecentWork) {
    clone.recentWork = { baseline: true, summary: 'Recent-work details were excluded from this export.', changes: [], affectedComponents: [] };
  }
  if (!includeHealth) {
    clone.health = { disclaimer: 'Health findings were excluded from this export.', findings: [], summary: {} };
  }
  clone.architecture.repository = { name: clone.architecture.repository.name };
  clone.graph.repository = { name: clone.graph.repository.name };
  delete clone.scan;
  for (const node of clone.graph.nodes) {
    delete node.fingerprint;
    delete node.structuralSignature;
  }
  return clone;
}

async function writeAtomic(filePath, contents) {
  const temporaryPath = `${filePath}.tmp`;
  await writeFile(temporaryPath, contents, 'utf8');
  await rename(temporaryPath, filePath);
}

async function readJsonIfExists(filePath) {
  try {
    return JSON.parse(await readFile(filePath, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return null;
    throw new Error(`Could not read ${path.relative(floorplanDir, filePath)}: ${error.message}`, { cause: error });
  }
}

async function writeDescriptions(files, components, previousScan, previousDescriptions, targetDir) {
  const outputDescriptionsDir = path.join(targetDir, 'descriptions');
  await mkdir(outputDescriptionsDir, { recursive: true });
  const componentMap = new Map(components.map((component) => [component.id, component]));
  const priorByFingerprint = new Map();
  for (const oldFile of previousScan?.files ?? []) {
    const description = previousDescriptions.get(oldFile.path);
    if (description) priorByFingerprint.set(oldFile.fingerprint, description);
  }
  const descriptions = new Map();
  const expectedNames = new Set();

  for (const file of files) {
    const component = componentMap.get(getModuleForPath(file.path));
    const oldFile = previousScan?.files.find((item) => item.path === file.path);
    const prior = previousDescriptions.get(file.path) ??
      (!oldFile ? priorByFingerprint.get(file.fingerprint) : null);
    const preserve = Boolean(prior && (
      !oldFile ||
      oldFile.structuralSignature === file.structuralSignature
    ));
    const description = createDescription(file, component, prior, preserve);
    description.dependents = files
      .filter((candidate) => candidate.imports.some((item) => item.target === file.path))
      .map((candidate) => candidate.path);
    descriptions.set(file.path, description);
    const name = `f-${encodePath(file.path)}.json`;
    expectedNames.add(name);
    await writeAtomic(path.join(outputDescriptionsDir, name), safeJson(description));
  }

  for (const name of await readdir(outputDescriptionsDir)) {
    if (/^f-[A-Za-z0-9_-]+\.json$/u.test(name) && !expectedNames.has(name)) {
      await unlink(path.join(outputDescriptionsDir, name));
    }
  }
  return descriptions;
}

export async function buildFloorplan(root = defaultRoot, destination = floorplanDir) {
  const normalizedRoot = path.resolve(root);
  const normalizedDestination = path.resolve(destination);
  const destinationCache = path.join(normalizedDestination, '.cache');
  const destinationDescriptions = path.join(normalizedDestination, 'descriptions');
  await mkdir(destinationCache, { recursive: true });
  await mkdir(destinationDescriptions, { recursive: true });
  const previousScanPath = path.join(destinationCache, 'scan.json');
  const cachedScan = await readJsonIfExists(previousScanPath);
  const scan = await scanRepository(normalizedRoot);
  const previous = cachedScan?.schemaVersion === scan.schemaVersion ? cachedScan : null;
  const components = getComponentDefinitions().map((component) => ({
    ...component,
    files: scan.files
      .filter((file) => getModuleForPath(file.path) === component.id)
      .map((file) => file.path),
  }));

  const previousDescriptions = new Map();
  for (const oldFile of previous?.files ?? []) {
    const descriptionPath = path.join(destinationDescriptions, `f-${encodePath(oldFile.path)}.json`);
    const description = await readJsonIfExists(descriptionPath);
    if (description) previousDescriptions.set(oldFile.path, description);
  }
  const descriptions = await writeDescriptions(
    scan.files,
    components,
    previous,
    previousDescriptions,
    normalizedDestination,
  );
  const graph = buildGraph(scan, components, descriptions);
  const fileAssignments = Object.fromEntries(scan.files.map((file) => [
    file.path,
    getModuleForPath(file.path),
  ]));
  const architecture = {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    repository: scan.repository,
    project: {
      name: 'VoyagerM',
      summary: 'A local-first Flutter learning app for roadmaps, saved learning materials, study notes, and supported YouTube/MIT OpenCourseWare playback.',
      architectureNote: 'No backend service or REST API is inferred; storage and playback boundaries are local repositories and platform media integrations.',
      explanationModes: ['simple', 'developer'],
      evidencePolicy: 'Source imports, declarations, repository registrations, platform channels, and schema statements are source-backed. Curated workflows are marked partial where source wiring is incomplete.',
    },
    components,
    fileAssignments,
    workflows: getWorkflows(),
    tour: [
      { title: 'Start at the app shell', componentId: 'app' },
      { title: 'Inspect the composition root', componentId: 'runtime' },
      { title: 'Follow a feature contract', componentId: 'feature-library' },
      { title: 'Trace media to the platform', componentId: 'media' },
      { title: 'Check the local data boundary', componentId: 'persistence' },
    ],
    externalDependencies: [
      ...scan.declaredDependencies.map((dependency) => ({
        name: dependency.name,
        label: getPackageLabel(dependency.name),
        category: 'package',
        declaredIn: 'pubspec.yaml',
        scope: dependency.scope,
        constraint: dependency.constraint,
      })),
      ...scan.nativeDependencies.map((dependency) => ({
        name: dependency.artifact,
        label: dependency.coordinate,
        category: 'Android Gradle package',
        declaredIn: dependency.file,
        scope: dependency.scope,
        version: dependency.version,
      })),
    ],
    database: scan.database,
    implementationNotes: [
      {
        status: 'Partial',
        title: 'Bookmark creation is not wired in the player',
        explanation: 'Current source lists, opens, and deletes bookmarks, but no player call creates them.',
        evidence: ['lib/features/home/presentation/app_shell.dart', 'lib/features/progress/domain/progress_repository.dart'],
      },
      {
        status: 'Documentation drift',
        title: 'Development roadmap has stale status claims',
        explanation: 'It still says settings and progress are not saved/connected, while current source wires settings persistence and playback progress.',
        evidence: ['docs/development-roadmap.md', 'lib/features/home/presentation/app_shell.dart', 'lib/features/player/presentation/learning_player_screen.dart'],
      },
      {
        status: 'Documentation drift',
        title: 'Note image embeds are missing from the implementation status',
        explanation: 'The note editor can insert images. IO platforms store image files under app documents; Web embeds data URLs with browser-local notes. This does not establish arbitrary file attachment support.',
        evidence: ['docs/implementation-status.md', 'lib/features/notes/presentation/note_editor_page.dart', 'lib/features/notes/data/note_image_store_io.dart', 'lib/features/notes/data/browser_note_storage_web.dart'],
      },
      {
        status: 'Unverified',
        title: 'Provider availability is not established by unit tests',
        explanation: 'Controlled tests do not guarantee live YouTube/OCW extraction or device playback will keep working.',
        evidence: ['docs/implementation-status.md', 'test/media/newpipe_youtube_adapter_test.dart'],
      },
    ],
  };
  const validation = validateArchitecture(architecture, graph, scan);
  if (!validation.valid) {
    throw new Error(`Architecture validation failed:\n${validation.errors.map((error) => `- ${error}`).join('\n')}`);
  }
  const recentWork = buildRecentWork(previous, scan);
  const health = await runHealthChecks(normalizedRoot, scan, architecture);
  architecture.healthSummary = health.summary;

  const output = {
    scan,
    architecture,
    graph,
    recentWork,
    health,
    validation,
  };
  const outputPaths = [
    ['architecture.json', safeJson(architecture)],
    ['graph.json', safeJson(graph)],
    ['recent-work.json', safeJson(recentWork)],
    ['health.json', safeJson(health)],
  ];
  await writeAtomic(previousScanPath, safeJson(scan));
  for (const [name, contents] of outputPaths) {
    await writeAtomic(path.join(normalizedDestination, name), contents);
  }
  const templatePath = path.join(normalizedDestination, 'scripts', 'viewer-template.html');
  const template = await readFile(templatePath, 'utf8');
  const embedded = safeJson(sanitizeForExport(output)).replace(/</gu, '\\u003c');
  await writeAtomic(path.join(normalizedDestination, 'index.html'), template.replace('@@FLOORPLAN_DATA@@', embedded));

  return {
    ...output,
    descriptionCount: descriptions.size,
    destination: normalizedDestination,
  };
}

export { buildGraph };

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const rootArg = process.argv[2] && !process.argv[2].startsWith('--')
    ? process.argv[2]
    : defaultRoot;
  try {
    const result = await buildFloorplan(rootArg);
    process.stdout.write([
      `Built architecture map for ${result.scan.repository.name}.`,
      `${result.scan.statistics.fileCount} files scanned; ${result.descriptionCount} descriptions.`,
      `${result.graph.edges.length} evidence-backed graph edges; ${result.health.findings.length} health findings.`,
      `Output: ${path.relative(rootArg, result.destination) || '.'}`,
    ].join('\n') + '\n');
  } catch (error) {
    process.stderr.write(`Floorplan build failed: ${error.message}\n`);
    process.exitCode = 1;
  }
}
