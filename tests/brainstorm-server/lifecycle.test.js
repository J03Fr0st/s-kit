const { spawn } = require('child_process');
const http = require('http');
const net = require('net');
const WebSocket = require('ws');
const fs = require('fs');
const os = require('os');
const path = require('path');
const assert = require('assert');

const SERVER_PATH = path.join(__dirname, '../../skills/brainstorming/scripts/server.cjs');
const VALID_TOKEN = 'a'.repeat(64);
const OTHER_TOKEN = 'b'.repeat(64);

function mkTestDir(name) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), `brainstorm-${name}-`));
  fs.mkdirSync(path.join(dir, 'content'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'state'), { recursive: true });
  return dir;
}

function cleanup(dir) {
  if (dir && fs.existsSync(dir)) fs.rmSync(dir, { recursive: true, force: true });
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function request(url) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, (res) => {
      res.resume();
      res.on('end', () => resolve(res.statusCode));
    });
    req.on('error', reject);
  });
}

function occupyPort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => resolve({
      port: server.address().port,
      close: () => new Promise(done => server.close(done))
    }));
    server.on('error', reject);
  });
}

function startServer(env = {}) {
  return spawn(process.execPath, [SERVER_PATH], {
    env: {
      ...process.env,
      BRAINSTORM_OWNER_PID: '',
      ...env
    },
    stdio: ['ignore', 'pipe', 'pipe']
  });
}

function waitForStarted(child, timeoutMs = 5000) {
  let stdout = '';
  let stderr = '';

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`Server did not start. stderr: ${stderr}`)), timeoutMs);
    child.stdout.on('data', (data) => {
      stdout += data.toString();
      for (const line of stdout.split(/\r?\n/)) {
        if (!line.includes('"server-started"')) continue;
        clearTimeout(timeout);
        resolve({ info: JSON.parse(line), stdout: () => stdout, stderr: () => stderr });
      }
    });
    child.stderr.on('data', (data) => { stderr += data.toString(); });
    child.on('exit', (code) => {
      clearTimeout(timeout);
      reject(new Error(`Server exited before start with code ${code}. stderr: ${stderr}`));
    });
    child.on('error', reject);
  });
}

function waitForExit(child, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Server did not exit')), timeoutMs);
    child.once('exit', (code) => {
      clearTimeout(timeout);
      resolve(code);
    });
  });
}

async function stopServer(child) {
  if (child.exitCode !== null) return child.exitCode;
  child.kill('SIGTERM');
  return waitForExit(child);
}

function openSocket(url, options = {}) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url, options);
    ws.once('open', () => resolve(ws));
    ws.once('error', reject);
    ws.once('unexpected-response', (req, res) => reject(new Error(`Unexpected response ${res.statusCode}`)));
  });
}

function tokenFromUrl(url) {
  return new URL(url).searchParams.get('key');
}

function writeOpenLogger(dir) {
  const logFile = path.join(dir, 'open.log');
  const opener = path.join(dir, 'opener.js');
  fs.writeFileSync(opener, "const fs=require('fs');fs.appendFileSync(process.env.OPEN_LOG,process.argv[2]+'\\n');\n");
  return { logFile, opener };
}

function writeScreen(dir, fileName, html) {
  fs.writeFileSync(path.join(dir, 'content', fileName), html);
}

async function runTests() {
  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  PASS: ${name}`);
      passed++;
    } catch (e) {
      console.log(`  FAIL: ${name}`);
      console.log(`    ${e.message}`);
      failed++;
    }
  }

  await test('server-info reports configured idle_timeout_ms', async () => {
    const dir = mkTestDir('idle-info');
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_IDLE_TIMEOUT_MS: '12345'
    });
    try {
      const { info } = await waitForStarted(child);
      assert.strictEqual(info.idle_timeout_ms, 12345);
      const serverInfo = JSON.parse(fs.readFileSync(path.join(dir, 'state', 'server-info'), 'utf-8'));
      assert.strictEqual(serverInfo.idle_timeout_ms, 12345);
    } finally {
      await stopServer(child);
      cleanup(dir);
    }
  });

  await test('idle shutdown closes an open authenticated WebSocket and writes stopped state', async () => {
    const dir = mkTestDir('idle-ws');
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_IDLE_TIMEOUT_MS: '450',
      BRAINSTORM_LIFECYCLE_CHECK_MS: '50'
    });
    try {
      const { info } = await waitForStarted(child);
      const ws = await openSocket(`ws://localhost:${info.port}/?key=${VALID_TOKEN}`);
      const closed = new Promise(resolve => ws.once('close', resolve));
      const code = await waitForExit(child, 4000);
      await closed;
      assert.strictEqual(code, 0);
      assert(!fs.existsSync(path.join(dir, 'state', 'server-info')), 'server-info should be removed');
      const stopped = JSON.parse(fs.readFileSync(path.join(dir, 'state', 'server-stopped'), 'utf-8'));
      assert.strictEqual(stopped.reason, 'idle timeout');
      assert(stopped.timestamp, 'server-stopped should include timestamp');
    } finally {
      cleanup(dir);
    }
  });

  await test('IPv6 BRAINSTORM_URL_HOST is bracketed in startup URL', async () => {
    const dir = mkTestDir('ipv6-url');
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_URL_HOST: '::1'
    });
    try {
      const { info } = await waitForStarted(child);
      assert(info.url.startsWith(`http://[::1]:${info.port}/?key=`), info.url);
    } finally {
      await stopServer(child);
      cleanup(dir);
    }
  });

  await test('IPv6 advertised origin authenticates WebSocket', async () => {
    const dir = mkTestDir('ipv6-origin');
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_URL_HOST: '::1'
    });
    try {
      const { info } = await waitForStarted(child);
      const ws = await openSocket(`ws://localhost:${info.port}/?key=${VALID_TOKEN}`, {
        headers: { Origin: `http://[::1]:${info.port}` }
      });
      ws.close();
    } finally {
      await stopServer(child);
      cleanup(dir);
    }
  });

  await test('port and token are persisted, hardened, reused, and authenticate WebSocket after restart', async () => {
    const dir = mkTestDir('persist');
    const portFile = path.join(dir, '.last-port');
    const tokenFile = path.join(dir, '.last-token');
    fs.writeFileSync(tokenFile, `${VALID_TOKEN}\n`, { mode: 0o644 });
    try {
      const first = startServer({
        BRAINSTORM_DIR: dir,
        BRAINSTORM_PORT_FILE: portFile,
        BRAINSTORM_TOKEN_FILE: tokenFile
      });
      const firstStart = await waitForStarted(first);
      await stopServer(first);

      assert.strictEqual(fs.readFileSync(portFile, 'utf-8').trim(), String(firstStart.info.port));
      assert.strictEqual(fs.readFileSync(tokenFile, 'utf-8').trim(), VALID_TOKEN);
      if (process.platform !== 'win32') {
        assert.strictEqual(fs.statSync(tokenFile).mode & 0o777, 0o600);
      }

      const second = startServer({
        BRAINSTORM_DIR: dir,
        BRAINSTORM_PORT_FILE: portFile,
        BRAINSTORM_TOKEN_FILE: tokenFile
      });
      const secondStart = await waitForStarted(second);
      const ws = await openSocket(`ws://localhost:${secondStart.info.port}/?key=${VALID_TOKEN}`);
      ws.close();
      await stopServer(second);

      assert.strictEqual(secondStart.info.port, firstStart.info.port);
      assert.strictEqual(tokenFromUrl(secondStart.info.url), VALID_TOKEN);
    } finally {
      cleanup(dir);
    }
  });

  await test('preferred port fallback chooses a different high port and preserves persisted files', async () => {
    const dir = mkTestDir('fallback-file');
    const occupied = await occupyPort();
    const portFile = path.join(dir, '.last-port');
    const tokenFile = path.join(dir, '.last-token');
    fs.writeFileSync(portFile, `${occupied.port}\n`);
    fs.writeFileSync(tokenFile, `${VALID_TOKEN}\n`, { mode: 0o600 });
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_PORT_FILE: portFile,
      BRAINSTORM_TOKEN_FILE: tokenFile
    });
    try {
      const { info } = await waitForStarted(child);
      const fallbackToken = tokenFromUrl(info.url);
      assert.notStrictEqual(info.port, occupied.port);
      assert(info.port >= 49152, `fallback port should be high: ${info.port}`);
      assert.strictEqual(fs.readFileSync(portFile, 'utf-8').trim(), String(occupied.port));
      assert.strictEqual(fs.readFileSync(tokenFile, 'utf-8').trim(), VALID_TOKEN);
      assert.notStrictEqual(fallbackToken, VALID_TOKEN);
      const ws = await openSocket(`ws://localhost:${info.port}/?key=${fallbackToken}`);
      ws.close();
    } finally {
      await stopServer(child);
      await occupied.close();
      cleanup(dir);
    }
  });

  await test('fallback with explicit BRAINSTORM_TOKEN fails closed', async () => {
    const dir = mkTestDir('fallback-env-token');
    const occupied = await occupyPort();
    const portFile = path.join(dir, '.last-port');
    fs.writeFileSync(portFile, `${occupied.port}\n`);
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_PORT_FILE: portFile,
      BRAINSTORM_TOKEN: OTHER_TOKEN
    });
    let stderr = '';
    child.stderr.on('data', data => { stderr += data.toString(); });
    try {
      const code = await waitForExit(child, 4000);
      assert.notStrictEqual(code, 0);
      assert(stderr.includes('BRAINSTORM_TOKEN'), stderr);
    } finally {
      await occupied.close();
      cleanup(dir);
    }
  });

  await test('BRAINSTORM_OPEN command opens once on first screen with key-bearing URL', async () => {
    const dir = mkTestDir('open-once');
    const { logFile, opener } = writeOpenLogger(dir);
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_OPEN: '1',
      BRAINSTORM_OPEN_CMD: `"${process.execPath}" "${opener}"`,
      OPEN_LOG: logFile
    });
    try {
      const { info } = await waitForStarted(child);
      await sleep(150);
      assert(!fs.existsSync(logFile), 'browser should not open before first screen');
      writeScreen(dir, 'screen.html', '<h1>Ready</h1>');
      await sleep(500);
      writeScreen(dir, 'screen2.html', '<h1>Ready again</h1>');
      await sleep(500);
      const lines = fs.readFileSync(logFile, 'utf-8').trim().split(/\r?\n/);
      assert.strictEqual(lines.length, 1);
      assert.strictEqual(lines[0], info.url);
      assert(lines[0].includes('?key='));
    } finally {
      await stopServer(child);
      cleanup(dir);
    }
  });

  await test('without BRAINSTORM_OPEN no browser launch happens', async () => {
    const dir = mkTestDir('no-open');
    const { logFile, opener } = writeOpenLogger(dir);
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_OPEN_CMD: `"${process.execPath}" "${opener}"`,
      OPEN_LOG: logFile
    });
    try {
      await waitForStarted(child);
      writeScreen(dir, 'screen.html', '<h1>Ready</h1>');
      await sleep(500);
      assert(!fs.existsSync(logFile), 'browser command should not run');
    } finally {
      await stopServer(child);
      cleanup(dir);
    }
  });

  await test('unauthenticated 403 flood does not prevent idle timeout', async () => {
    const dir = mkTestDir('unauth-idle');
    const child = startServer({
      BRAINSTORM_DIR: dir,
      BRAINSTORM_TOKEN: VALID_TOKEN,
      BRAINSTORM_IDLE_TIMEOUT_MS: '450',
      BRAINSTORM_LIFECYCLE_CHECK_MS: '50'
    });
    let timer;
    try {
      const { info } = await waitForStarted(child);
      timer = setInterval(() => {
        request(`http://localhost:${info.port}/`).catch(() => {});
      }, 50);
      const code = await waitForExit(child, 4000);
      assert.strictEqual(code, 0);
      const stopped = JSON.parse(fs.readFileSync(path.join(dir, 'state', 'server-stopped'), 'utf-8'));
      assert.strictEqual(stopped.reason, 'idle timeout');
    } finally {
      if (timer) clearInterval(timer);
      cleanup(dir);
    }
  });

  console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
  if (failed > 0) process.exit(1);
}

runTests().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
