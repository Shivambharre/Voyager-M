import { createReadStream, promises as fs } from 'node:fs';
import { createServer } from 'node:http';
import { isIP } from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const floorplanDir = path.dirname(fileURLToPath(import.meta.url));
const allowedRootFiles = new Set([
  'index.html',
  'architecture.json',
  'graph.json',
  'recent-work.json',
  'health.json',
]);
const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
};

function isLoopback(address) {
  if (!address) return false;
  const normalized = address.toLowerCase().replace(/^::ffff:/u, '');
  return normalized === '::1' || normalized === '127.0.0.1' || normalized.startsWith('127.');
}

function requestPath(rawUrl) {
  const rawPath = (rawUrl ?? '').split('?', 1)[0];
  let decoded;
  try {
    decoded = decodeURIComponent(rawPath);
  } catch {
    return null;
  }
  if (!decoded.startsWith('/') || decoded.includes('\\') || decoded.includes('\0')) return null;
  const segments = decoded.split('/');
  if (segments.some((segment) => segment === '..' || segment === '.')) return null;
  const normalized = path.posix.normalize(decoded);
  if (normalized !== decoded && normalized !== '/') return null;
  if (normalized === '/' || normalized === '/index.html') return 'index.html';
  const relative = normalized.slice(1);
  if (allowedRootFiles.has(relative)) return relative;
  if (/^descriptions\/f-[A-Za-z0-9_-]+\.json$/u.test(relative)) return relative;
  return null;
}

function trustedOrigin(request, port) {
  const origin = request.headers.origin;
  if (!origin || origin === 'null') return true;
  let parsed;
  try {
    parsed = new URL(origin);
  } catch {
    return false;
  }
  const requestHost = request.headers.host;
  return ['http:', 'https:'].includes(parsed.protocol) &&
    ['127.0.0.1', 'localhost'].includes(parsed.hostname) &&
    (requestHost === `${parsed.hostname}:${port}` || requestHost === `${parsed.hostname}`);
}

function setHeaders(response, contentType) {
  response.setHeader('Content-Type', contentType);
  response.setHeader('X-Content-Type-Options', 'nosniff');
  response.setHeader('Referrer-Policy', 'no-referrer');
  response.setHeader('X-Frame-Options', 'DENY');
  response.setHeader('Cache-Control', 'no-store');
  response.setHeader(
    'Content-Security-Policy',
    "default-src 'none'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; font-src 'self'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  );
}

export async function createFloorplanServer({
  directory = floorplanDir,
  host = '127.0.0.1',
  port = 4173,
} = {}) {
  if (host !== '127.0.0.1') throw new Error('Floorplan may only bind to 127.0.0.1.');
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('Port must be an integer from 0 to 65535.');
  const root = await fs.realpath(directory);

  const server = createServer(async (request, response) => {
    const remoteAddress = request.socket.remoteAddress;
    if (!isLoopback(remoteAddress) || isIP(remoteAddress.replace(/^::ffff:/u, '')) === 0) {
      response.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Loopback clients only.\n');
      return;
    }

    const requestHost = request.headers.host ?? '';
    const hostName = requestHost.replace(/:\d+$/u, '').replace(/^\[|\]$/gu, '').toLowerCase();
    if (!['127.0.0.1', 'localhost'].includes(hostName) || !trustedOrigin(request, server.address()?.port ?? port)) {
      response.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Request host or origin is not allowed.\n');
      return;
    }

    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405, { Allow: 'GET, HEAD', 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Read-only server; only GET and HEAD are supported.\n');
      return;
    }

    const relative = requestPath(request.url);
    if (!relative) {
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Not found.\n');
      return;
    }
    const target = path.resolve(root, relative);
    if (!target.startsWith(`${root}${path.sep}`)) {
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Not found.\n');
      return;
    }

    let fileInfo;
    try {
      fileInfo = await fs.stat(target);
      if (!fileInfo.isFile()) throw new Error('Not a file.');
      const actual = await fs.realpath(target);
      if (!actual.startsWith(`${root}${path.sep}`)) throw new Error('Outside generated directory.');
    } catch (error) {
      if (error.code !== 'ENOENT' && error.code !== 'ENOTDIR') {
        response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        response.end('Not found.\n');
        return;
      }
      response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('Not found.\n');
      return;
    }
    setHeaders(response, mimeTypes[path.extname(target)] ?? 'application/octet-stream');
    response.setHeader('Content-Length', fileInfo.size);
    response.writeHead(200);
    if (request.method === 'HEAD') {
      response.end();
      return;
    }
    createReadStream(target).pipe(response);
  });

  return server;
}

function parsePort(argv) {
  const index = argv.indexOf('--port');
  if (index < 0) return 4173;
  const value = Number(argv[index + 1]);
  if (!Number.isInteger(value) || value < 0 || value > 65535) {
    throw new Error('Usage: node floorplan/serve.mjs [--port 4173]');
  }
  return value;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const port = parsePort(process.argv.slice(2));
    const server = await createFloorplanServer({ port });
    server.on('error', (error) => {
      process.stderr.write(`Floorplan server failed: ${error.message}\n`);
      process.exitCode = 1;
    });
    server.listen(port, '127.0.0.1', () => {
      const address = server.address();
      process.stdout.write(`Floorplan is available at http://127.0.0.1:${address.port}/\n`);
      process.stdout.write('Read-only local server. Press Ctrl+C to stop it cleanly.\n');
    });
    const stop = () => server.close(() => process.exit(0));
    process.once('SIGINT', stop);
    process.once('SIGTERM', stop);
  } catch (error) {
    process.stderr.write(`Floorplan server failed: ${error.message}\n`);
    process.exitCode = 1;
  }
}
