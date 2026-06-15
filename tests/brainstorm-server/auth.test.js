const { spawn } = require('child_process');
const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const SERVER_PATH = path.join(__dirname, '../../skills/brainstorming/scripts/server.cjs');
const TEST_PORT = 3335;
const TEST_TOKEN = 'authtesttoken';
const TEST_DIR = '/tmp/brainstorm-auth-test';
const CONTENT_DIR = path.join(TEST_DIR, 'content');
const STATE_DIR = path.join(TEST_DIR, 'state');
const BASE_URL = `http://localhost:${TEST_PORT}`;
const WS_URL = `ws://localhost:${TEST_PORT}`;
const COOKIE_NAME = `brainstorm-key-${TEST_PORT}`;

const SECURITY_HEADERS = {
  'referrer-policy': 'no-referrer',
  'cache-control': 'no-store',
  'x-frame-options': 'DENY',
  'content-security-policy': "frame-ancestors 'none'",
  'cross-origin-resource-policy': 'same-origin'
};

function cleanup() {
  if (fs.existsSync(TEST_DIR)) {
    fs.rmSync(TEST_DIR, { recursive: true });
  }
}

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function request(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request(url, {
      method: options.method || 'GET',
      headers: options.headers || {}
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve({
        status: res.statusCode,
        headers: res.headers,
        body
      }));
    });
    req.on('error', reject);
    req.end();
  });
}

function startServer() {
  return spawn('node', [SERVER_PATH], {
    env: {
      ...process.env,
      BRAINSTORM_PORT: String(TEST_PORT),
      BRAINSTORM_DIR: TEST_DIR,
      BRAINSTORM_TOKEN: TEST_TOKEN
    }
  });
}

function waitForServer(server) {
  let stdout = '';
  let stderr = '';

  return new Promise((resolve, reject) => {
    server.stdout.on('data', (data) => {
      stdout += data.toString();
      const line = stdout.split('\n').find(entry => entry.includes('"server-started"'));
      if (line) resolve(JSON.parse(line));
    });
    server.stderr.on('data', (data) => { stderr += data.toString(); });
    server.on('error', reject);
    setTimeout(() => reject(new Error(`Server didn't start. stderr: ${stderr}`)), 5000);
  });
}

function openSocket(url, options = {}) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url, options);
    ws.once('open', () => resolve(ws));
    ws.once('error', reject);
    ws.once('unexpected-response', (req, res) => {
      reject(new Error(`Unexpected response ${res.statusCode}`));
    });
  });
}

function expectSocketRejected(url, options = {}) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url, options);
    ws.once('open', () => {
      ws.close();
      reject(new Error('WebSocket opened unexpectedly'));
    });
    ws.once('error', () => resolve());
    ws.once('unexpected-response', () => resolve());
    setTimeout(() => resolve(), 500);
  });
}

async function runTests() {
  cleanup();
  const server = startServer();
  let passed = 0;
  let failed = 0;

  const startup = await waitForServer(server);

  function test(name, fn) {
    return fn().then(() => {
      console.log(`  PASS: ${name}`);
      passed++;
    }).catch(e => {
      console.log(`  FAIL: ${name}`);
      console.log(`    ${e.message}`);
      failed++;
    });
  }

  try {
    fs.writeFileSync(path.join(CONTENT_DIR, 'screen.html'), '<h1>Protected Screen</h1>');
    fs.writeFileSync(path.join(CONTENT_DIR, 'asset.txt'), 'protected asset');
    await sleep(200);

    await test('startup URL includes key', async () => {
      assert.strictEqual(startup.url, `${BASE_URL}/?key=${TEST_TOKEN}`);
    });

    await test('keyless GET / returns 403', async () => {
      const res = await request(`${BASE_URL}/`);
      assert.strictEqual(res.status, 403);
    });

    await test('wrong-key GET / returns 403', async () => {
      const res = await request(`${BASE_URL}/?key=wrong`);
      assert.strictEqual(res.status, 403);
    });

    await test('wrong query key plus valid cookie returns 403', async () => {
      const res = await request(`${BASE_URL}/?key=wrong`, {
        headers: { Cookie: `${COOKIE_NAME}=${TEST_TOKEN}` }
      });
      assert.strictEqual(res.status, 403);
    });

    await test('403 responses include security headers', async () => {
      const res = await request(`${BASE_URL}/`);
      for (const [name, expected] of Object.entries(SECURITY_HEADERS)) {
        assert.strictEqual(res.headers[name], expected, `${name} should be set`);
      }
    });

    await test('valid keyed GET / returns bootstrap without screen content', async () => {
      const res = await request(`${BASE_URL}/?key=${TEST_TOKEN}`);
      assert.strictEqual(res.status, 200);
      assert(res.body.includes("sessionStorage.setItem('brainstorm-session-key'"), 'Should store session key');
      assert(res.body.includes("location.replace('/')"), 'Should redirect to bare URL');
      assert(!res.body.includes('Protected Screen'), 'Should not serve screen content at keyed URL');
    });

    await test('bootstrap still redirects when sessionStorage.setItem throws', async () => {
      const res = await request(`${BASE_URL}/?key=${TEST_TOKEN}`);
      assert(res.body.includes('catch (e) {}'), 'Should ignore sessionStorage failures');
      assert(res.body.includes("location.replace('/')"), 'Should redirect after storage failure');
    });

    await test('valid keyed response sets HttpOnly SameSite Strict cookie', async () => {
      const res = await request(`${BASE_URL}/?key=${TEST_TOKEN}`);
      const cookie = res.headers['set-cookie'] && res.headers['set-cookie'][0];
      assert(cookie, 'Should set cookie');
      assert(cookie.includes(`${COOKIE_NAME}=${TEST_TOKEN}`), 'Should include session cookie');
      assert(cookie.includes('HttpOnly'), 'Should be HttpOnly');
      assert(cookie.includes('SameSite=Strict'), 'Should be SameSite Strict');
      assert(cookie.includes('Path=/'), 'Should be path scoped to root');
    });

    await test('valid cookie on bare GET / serves protected screen', async () => {
      const res = await request(`${BASE_URL}/`, {
        headers: { Cookie: `${COOKIE_NAME}=${TEST_TOKEN}` }
      });
      assert.strictEqual(res.status, 200);
      assert(res.body.includes('Protected Screen'), 'Should serve screen with valid cookie');
    });

    await test('/files is 403 without auth and serves content with valid key', async () => {
      const denied = await request(`${BASE_URL}/files/asset.txt`);
      assert.strictEqual(denied.status, 403);

      const allowed = await request(`${BASE_URL}/files/asset.txt?key=${TEST_TOKEN}`);
      assert.strictEqual(allowed.status, 200);
      assert.strictEqual(allowed.body, 'protected asset');
    });

    await test('WebSocket without auth is rejected', async () => {
      await expectSocketRejected(WS_URL);
    });

    await test('WebSocket with valid key opens', async () => {
      const ws = await openSocket(`${WS_URL}/?key=${TEST_TOKEN}`);
      ws.close();
    });

    await test('WebSocket with valid cookie opens', async () => {
      const ws = await openSocket(WS_URL, {
        headers: { Cookie: `${COOKIE_NAME}=${TEST_TOKEN}` }
      });
      ws.close();
    });

    await test('same-origin browser WebSocket opens', async () => {
      const ws = await openSocket(`${WS_URL}/?key=${TEST_TOKEN}`, {
        headers: { Origin: BASE_URL }
      });
      ws.close();
    });

    await test('cross-origin browser WebSocket is rejected and writes no events', async () => {
      const eventsFile = path.join(STATE_DIR, 'events');
      if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);

      await expectSocketRejected(WS_URL, {
        headers: {
          Cookie: `${COOKIE_NAME}=${TEST_TOKEN}`,
          Origin: 'http://evil.example'
        }
      });
      await sleep(200);
      assert(!fs.existsSync(eventsFile), 'Rejected socket should not write events');
    });

    await test('JSON payload null over authorized socket does not crash the server', async () => {
      const ws = await openSocket(`${WS_URL}/?key=${TEST_TOKEN}`);
      ws.send('null');
      await sleep(200);
      ws.close();

      const res = await request(`${BASE_URL}/`, {
        headers: { Cookie: `${COOKIE_NAME}=${TEST_TOKEN}` }
      });
      assert.strictEqual(res.status, 200);
    });

    console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
    if (failed > 0) process.exit(1);
  } finally {
    server.kill();
    await sleep(100);
    cleanup();
  }
}

runTests().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
