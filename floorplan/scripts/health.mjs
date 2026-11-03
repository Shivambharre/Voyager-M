import { readFile } from 'node:fs/promises';
import path from 'node:path';

const sourceExtensions = new Set(['.dart', '.kt', '.kts', '.java', '.js', '.mjs', '.ts', '.xml', '.yaml', '.yml', '.properties']);

function lineNumber(source, index) {
  let line = 1;
  for (let cursor = 0; cursor < index; cursor += 1) {
    if (source[cursor] === '\n') line += 1;
  }
  return line;
}

function withoutComments(source, extension) {
  if (extension === '.xml') return source.replace(/<!--[\s\S]*?-->/gu, (text) => text.replace(/[^\n]/gu, ' '));
  if (['.yaml', '.yml', '.properties'].includes(extension)) {
    return source.replace(/^\s*#.*$/gmu, (text) => text.replace(/[^\n]/gu, ' '));
  }
  return source
    .replace(/\/\*[\s\S]*?\*\//gu, (text) => text.replace(/[^\n]/gu, ' '))
    .replace(/^\s*\/\/.*$/gmu, (text) => text.replace(/[^\n]/gu, ' '));
}

export function detectCredentialIndicators(source) {
  const findings = [];
  const patterns = [
    { type: 'private key material', pattern: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/gu },
    { type: 'AWS access key', pattern: /\bAKIA[0-9A-Z]{16}\b/gu },
    { type: 'GitHub token', pattern: /\bgh[pousr]_[A-Za-z0-9_]{30,}\b/gu },
    { type: 'live payment secret', pattern: /\bsk_live_[A-Za-z0-9]{16,}\b/gu },
    { type: 'credential-like assignment', pattern: /\b(?:api[_-]?key|client[_-]?secret|password|private[_-]?key|access[_-]?token)\s*[:=]\s*(['"])([^'"]{12,})\1/giu },
  ];
  const code = withoutComments(source, '.dart');
  for (const { type, pattern } of patterns) {
    for (const match of code.matchAll(pattern)) {
      const assigned = match[2] ?? match[0];
      if (/^(?:your[_ -]|example|sample|placeholder|changeme|replace[_ -]|test[_ -])/iu.test(assigned)) continue;
      findings.push({
        type,
        line: lineNumber(code, match.index),
      });
    }
  }
  return findings;
}

function severityWeight(severity) {
  return { critical: 0, high: 1, medium: 2, low: 3, informational: 4 }[severity] ?? 4;
}

function addFinding(findings, finding) {
  findings.push({
    id: `${finding.category}:${finding.file}:${finding.line ?? 0}:${finding.title}`,
    severity: finding.severity,
    category: finding.category,
    file: finding.file,
    line: finding.line ?? null,
    title: finding.title,
    explanation: finding.explanation,
    whyItMatters: finding.whyItMatters,
    remediation: finding.remediation,
    confidence: finding.confidence,
    confidenceLabel: finding.confidenceLabel,
    evidence: finding.evidence ?? [],
  });
}

function findCycles(files) {
  const dartFiles = files.filter((file) => file.language === 'Dart' && file.path.startsWith('lib/'));
  const known = new Set(dartFiles.map((file) => file.path));
  const edges = new Map(dartFiles.map((file) => [
    file.path,
    file.imports
      .filter((entry) => entry.target && known.has(entry.target))
      .map((entry) => entry.target),
  ]));
  let sequence = 0;
  const stack = [];
  const onStack = new Set();
  const index = new Map();
  const low = new Map();
  const cycles = [];

  function visit(filePath) {
    index.set(filePath, sequence);
    low.set(filePath, sequence);
    sequence += 1;
    stack.push(filePath);
    onStack.add(filePath);
    for (const target of edges.get(filePath) ?? []) {
      if (!index.has(target)) {
        visit(target);
        low.set(filePath, Math.min(low.get(filePath), low.get(target)));
      } else if (onStack.has(target)) {
        low.set(filePath, Math.min(low.get(filePath), index.get(target)));
      }
    }
    if (low.get(filePath) !== index.get(filePath)) return;
    const component = [];
    let node;
    do {
      node = stack.pop();
      onStack.delete(node);
      component.push(node);
    } while (node !== filePath);
    const selfCycle = (edges.get(filePath) ?? []).includes(filePath);
    if (component.length > 1 || selfCycle) cycles.push(component.sort());
  }

  for (const file of dartFiles) {
    if (!index.has(file.path)) visit(file.path);
  }
  return cycles;
}

export async function runHealthChecks(root, scan, architecture) {
  const findings = [];

  for (const file of scan.files) {
    if (!sourceExtensions.has(path.extname(file.path))) continue;
    const source = await readFile(path.join(root, file.path), 'utf8');
    const extension = path.extname(file.path);
    const code = withoutComments(source, extension);

    for (const credential of detectCredentialIndicators(source)) {
      addFinding(findings, {
        severity: 'high',
        category: 'security',
        file: file.path,
        line: credential.line,
        title: `Possible ${credential.type}`,
        explanation: 'A credential-shaped value appears in source. The checker records only the indicator type and location; it never includes the matched value.',
        whyItMatters: 'A real credential committed in client or source code can be copied and abused.',
        remediation: 'Confirm whether this is a real secret, remove it from source/history, rotate it if exposed, and load it through an appropriate secret-management mechanism.',
        confidence: credential.type === 'credential-like assignment' ? 5 : 8,
        confidenceLabel: credential.type === 'credential-like assignment' ? 'Needs manual review' : 'Likely',
      });
    }

    for (const match of code.matchAll(/\bhttp:\/\/(?!localhost(?::\d+)?(?:\/|["'])?)(?!127\.0\.0\.1(?::\d+)?(?:\/|["'])?)([^/"'\s]+)/giu)) {
      if (['schemas.android.com', 'www.w3.org'].includes(match[1].toLowerCase())) continue;
      addFinding(findings, {
        severity: 'medium',
        category: 'security',
        file: file.path,
        line: lineNumber(code, match.index),
        title: 'Non-local HTTP URL literal',
        explanation: `Source contains an unencrypted HTTP URL for ${match[1]}. This check does not establish whether the URL is actually used for sensitive traffic.`,
        whyItMatters: 'Unencrypted traffic can be read or changed in transit.',
        remediation: 'Use HTTPS for network requests, or document why this literal is non-network metadata.',
        confidence: 6,
        confidenceLabel: 'Needs manual review',
      });
    }

    if (file.lines > 900 && file.language === 'Dart') {
      addFinding(findings, {
        severity: 'low',
        category: 'architecture',
        file: file.path,
        title: 'Large Dart source file',
        explanation: `The file contains ${file.lines} lines, which makes focused review and safe edits harder.`,
        whyItMatters: 'Large UI and orchestration files can accumulate unrelated responsibilities.',
        remediation: 'Consider extracting cohesive widgets or helpers when the file is next changed; do not refactor solely to satisfy this heuristic.',
        confidence: 8,
        confidenceLabel: 'High for size; low for impact',
      });
    }
  }

  for (const cycle of findCycles(scan.files)) {
    addFinding(findings, {
      severity: 'medium',
      category: 'architecture',
      file: cycle[0],
      title: 'Circular Dart imports',
      explanation: `These library files import one another: ${cycle.join(', ')}.`,
      whyItMatters: 'Cycles make layer boundaries and change impact harder to reason about.',
      remediation: 'Move shared contracts to a lower-level module or invert the dependency through an existing interface.',
      confidence: 9,
      confidenceLabel: 'High',
      evidence: cycle,
    });
  }

  const playerPath = 'lib/features/player/presentation/learning_player_screen.dart';
  const player = await readFile(path.join(root, playerPath), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  if (player && !/\bsaveBookmark\s*\(/u.test(withoutComments(player, '.dart'))) {
    addFinding(findings, {
      severity: 'medium',
      category: 'architecture',
      file: playerPath,
      title: 'Bookmark creation is not connected',
      explanation: 'The current player has no saveBookmark call; the Home bookmarks flow can read and delete records, but this scan found no active UI path that creates them.',
      whyItMatters: 'A stored feature contract can look complete while the user-facing workflow is only partially wired.',
      remediation: 'If bookmark creation is intended, connect an explicit player action to ProgressRepository and test creation/open/delete; otherwise label the action unavailable.',
      confidence: 9,
      confidenceLabel: 'High',
      evidence: ['lib/features/progress/domain/progress_repository.dart', 'lib/features/home/presentation/app_shell.dart'],
    });
  }

  const roadmapPath = 'docs/development-roadmap.md';
  const roadmapDoc = await readFile(path.join(root, roadmapPath), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  if (
    roadmapDoc &&
    /Settings screen does\s+not save settings/i.test(roadmapDoc) &&
    scan.files.some((file) => file.path === 'lib/features/home/presentation/app_shell.dart') &&
    architecture.components.some((component) => component.id === 'feature-settings' && component.status === 'Implemented')
  ) {
    const offset = roadmapDoc.search(/Settings screen does not save settings/i);
    addFinding(findings, {
      severity: 'low',
      category: 'documentation',
      file: roadmapPath,
      line: lineNumber(roadmapDoc, offset),
      title: 'Roadmap status conflicts with active settings wiring',
      explanation: 'The roadmap says Settings does not persist settings, but current app code connects SettingsRepository and the settings screen.',
      whyItMatters: 'Outdated status notes can cause later work to duplicate or remove an active workflow.',
      remediation: 'Update the roadmap status when documentation changes are in scope; this checker does not edit application or documentation files.',
      confidence: 8,
      confidenceLabel: 'High',
      evidence: ['lib/main.dart', 'lib/core/di/service_locator.dart', 'lib/features/home/presentation/app_shell.dart'],
    });
  }

  const implementationStatusPath = 'docs/implementation-status.md';
  const implementationStatus = await readFile(path.join(root, implementationStatusPath), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const noteEditor = await readFile(path.join(root, 'lib/features/notes/presentation/note_editor_page.dart'), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  const noteImageStore = await readFile(path.join(root, 'lib/features/notes/data/note_image_store.dart'), 'utf8').catch((error) => {
    if (error.code === 'ENOENT') return '';
    throw error;
  });
  if (
    implementationStatus &&
    /Notes do not have file attachments/i.test(implementationStatus) &&
    /\b_insertImage\s*\(/u.test(withoutComments(noteEditor, '.dart')) &&
    /\bpickAndStoreImage\s*\(/u.test(withoutComments(noteImageStore, '.dart'))
  ) {
    const offset = implementationStatus.search(/Notes do not have file attachments/i);
    addFinding(findings, {
      severity: 'low',
      category: 'documentation',
      file: implementationStatusPath,
      line: lineNumber(implementationStatus, offset),
      title: 'Implementation status omits the note image workflow',
      explanation: 'The documented limit on arbitrary file attachments remains accurate, but the status does not mention that the note editor supports embedded images stored locally on IO platforms and inline with browser-backed notes on Web.',
      whyItMatters: 'A status summary that omits an active workflow can obscure platform-specific local storage behavior.',
      remediation: 'Document image embeds separately from general file attachments and retain the arbitrary-attachment limitation.',
      confidence: 9,
      confidenceLabel: 'High',
      evidence: ['lib/features/notes/presentation/note_editor_page.dart', 'lib/features/notes/data/note_image_store.dart', 'lib/features/notes/data/note_image_store_io.dart', 'lib/features/notes/data/browser_note_storage_web.dart'],
    });
  }

  if (findings.length === 0) {
    addFinding(findings, {
      severity: 'informational',
      category: 'security',
      file: 'floorplan/',
      title: 'No high-confidence credential indicators found',
      explanation: 'The local heuristic scan did not match its credential patterns in analyzed source files.',
      whyItMatters: 'Static text patterns cannot establish that the application is free of secrets or security flaws.',
      remediation: 'Review sensitive integrations and deployment configuration separately; treat this as a preliminary check, not an audit.',
      confidence: 4,
      confidenceLabel: 'Limited coverage',
    });
  }

  findings.sort((left, right) =>
    severityWeight(left.severity) - severityWeight(right.severity) ||
    right.confidence - left.confidence ||
    left.file.localeCompare(right.file));

  return {
    generatedAt: new Date().toISOString(),
    disclaimer: 'Automated preliminary checks only; this is not a professional security audit and can miss vulnerabilities or report false positives.',
    findings,
    summary: {
      critical: findings.filter((finding) => finding.severity === 'critical').length,
      high: findings.filter((finding) => finding.severity === 'high').length,
      medium: findings.filter((finding) => finding.severity === 'medium').length,
      low: findings.filter((finding) => finding.severity === 'low').length,
      informational: findings.filter((finding) => finding.severity === 'informational').length,
    },
  };
}

export { findCycles };
