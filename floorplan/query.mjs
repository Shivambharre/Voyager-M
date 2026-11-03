import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));

function words(value) {
  return value.toLowerCase().split(/[^a-z0-9_]+/u).filter((word) => word.length > 2);
}

function workflowScore(workflow, queryWords) {
  const text = `${workflow.name} ${workflow.summary} ${workflow.steps
    .map((step) => `${step.title} ${step.simple} ${step.developer} ${step.filePaths.join(' ')}`)
    .join(' ')}`.toLowerCase();
  return queryWords.reduce((score, word) => score + Math.max(0, text.split(word).length - 1), 0);
}

export async function answerQuestion(question, floorplanDir = scriptDir) {
  const architecturePath = path.join(floorplanDir, 'architecture.json');
  const graphPath = path.join(floorplanDir, 'graph.json');
  let architecture;
  let graph;
  try {
    [architecture, graph] = await Promise.all([
      readFile(architecturePath, 'utf8').then(JSON.parse),
      readFile(graphPath, 'utf8').then(JSON.parse),
    ]);
  } catch (error) {
    throw new Error(`Could not load generated architecture data. Run "node floorplan/scripts/build.mjs" first. ${error.message}`, { cause: error });
  }
  const queryWords = words(question);
  if (!queryWords.length) throw new Error('Provide a question with at least one searchable word.');
  const workflow = graph.workflows
    .map((item) => ({ item, score: workflowScore(item, queryWords) }))
    .sort((left, right) => right.score - left.score)[0];
  const matches = graph.searchIndex
    .map((item) => ({
      item,
      score: queryWords.reduce((score, word) =>
        score + Math.max(0, (item.searchText ?? '').split(word).length - 1), 0),
    }))
    .filter((entry) => entry.score > 0)
    .sort((left, right) => right.score - left.score)
    .slice(0, 8);

  const selectedWorkflow = workflow?.score ? workflow.item : null;
  const output = [
    `Question: ${question}`,
    selectedWorkflow
      ? `Closest verified workflow: ${selectedWorkflow.name} (${selectedWorkflow.status})`
      : 'No curated workflow directly matched. The files below are search references, not a complete explanation.',
  ];
  if (selectedWorkflow) {
    output.push(selectedWorkflow.summary);
    for (const [index, step] of selectedWorkflow.steps.entries()) {
      output.push(`${index + 1}. ${step.title} — ${step.developer}`);
      output.push(`   Evidence: ${step.filePaths.join(', ')}`);
    }
  }
  if (matches.length) {
    output.push('Additional matching components/files:');
    for (const { item } of matches) {
      output.push(`- ${item.name}${item.path ? ` — ${item.path}` : ''}`);
    }
  } else {
    output.push('No indexed source matched; search the repository and explain when evidence is insufficient.');
  }
  output.push('', 'Copilot prompt (copy/paste; no Copilot API or CLI is invoked):');
  output.push([
    'Answer the architecture question using only the supplied VoyagerM repository references and this architecture-map context.',
    'Do not assume undocumented behavior. Distinguish implemented, partial, planned, and unverified behavior.',
    `Question: ${question}`,
    `Relevant files/components: ${matches.map(({ item }) => item.path ?? item.name).join(', ') || 'No direct source match; search the repository and explain the evidence.'}`,
    selectedWorkflow ? `Verified workflow: ${selectedWorkflow.name} (${selectedWorkflow.status}). ${selectedWorkflow.steps.map((step) => `${step.title}: ${step.developer}`).join(' ')}` : '',
    'Mention exact file paths and say when evidence is insufficient.',
  ].filter(Boolean).join('\n\n'));
  return output.join('\n');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const question = process.argv.slice(2).join(' ').trim();
    if (!question) throw new Error('Usage: node floorplan/query.mjs "How does playback work?"');
    process.stdout.write(`${await answerQuestion(question)}\n`);
  } catch (error) {
    process.stderr.write(`Floorplan query failed: ${error.message}\n`);
    process.exitCode = 1;
  }
}
