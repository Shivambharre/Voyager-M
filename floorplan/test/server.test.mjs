import assert from 'node:assert/strict';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { request as httpRequest } from 'node:http';
import test from 'node:test';
import { createFloorplanServer } from '../serve.mjs';

function statusWithHeaders(url, headers) {
  return new Promise((resolve, reject) => {
    const request = httpRequest(url, { headers }, (response) => {
      response.resume();
      response.on('end', () => resolve(response.statusCode));
    });
    request.on('error', reject);
    request.end();
  });
}

test('serves generated artifacts over loopback and rejects writes, traversal, and untrusted origins', async (t) => {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'voyager-floorplan-server-'));
  await writeFile(path.join(directory, 'index.html'), '<!doctype html><h1>Map</h1>');
  await writeFile(path.join(directory, 'graph.json'), '{"nodes":[]}');
  await writeFile(path.join(directory, 'secret.mjs'), 'process.exit(1);');
  const server = await createFloorplanServer({ directory, port: 0 });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  t.after(async () => {
    await new Promise((resolve) => server.close(resolve));
    await rm(directory, { recursive: true, force: true });
  });
  const port = server.address().port;
  const base = `http://127.0.0.1:${port}`;

  const index = await fetch(`${base}/`);
  assert.equal(index.status, 200);
  assert.match(index.headers.get('content-security-policy'), /default-src 'none'/u);
  assert.match(await index.text(), /Map/u);
  const head = await fetch(`${base}/graph.json`, { method: 'HEAD' });
  assert.equal(head.status, 200);
  assert.equal((await head.text()).length, 0);

  assert.equal((await fetch(`${base}/secret.mjs`)).status, 404);
  assert.equal((await fetch(`${base}/%2e%2e%2fsecret.mjs`)).status, 404);
  assert.equal((await fetch(`${base}/`, { method: 'POST' })).status, 405);
  assert.equal(await statusWithHeaders(`${base}/`, { Host: 'attacker.example' }), 403);
  assert.equal(await statusWithHeaders(`${base}/`, {
    Host: `127.0.0.1:${port}`,
    Origin: 'https://attacker.example',
  }), 403);
});

test('does not allow binding on a non-loopback interface', async () => {
  await assert.rejects(createFloorplanServer({ host: '0.0.0.0' }), /only bind to 127\.0\.0\.1/u);
});
