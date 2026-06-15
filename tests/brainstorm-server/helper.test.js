const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const HELPER_PATH = path.join(__dirname, '../../skills/brainstorming/scripts/helper.js');
const source = fs.readFileSync(HELPER_PATH, 'utf8');

function loadHelperExports() {
  const module = { exports: {} };
  vm.runInNewContext(source, {
    module,
    exports: module.exports,
    setTimeout,
    clearTimeout
  }, { filename: HELPER_PATH });
  return module.exports;
}

function createElement(tagName) {
  return {
    tagName,
    id: '',
    className: '',
    textContent: '',
    innerHTML: '',
    dataset: {},
    children: [],
    style: {
      values: {},
      setProperty(name, value) {
        this.values[name] = value;
      }
    },
    classList: {
      add() {},
      remove() {},
      toggle() {}
    },
    appendChild(child) {
      this.children.push(child);
      child.parentNode = this;
      return child;
    },
    closest() {
      return null;
    },
    querySelectorAll() {
      return [];
    }
  };
}

function loadBrowser(options = {}) {
  const timers = [];
  const sockets = [];
  const status = createElement('div');
  status.className = 'status';
  const body = createElement('body');
  const elementsById = {};
  const calls = { replace: [], reload: 0 };

  const document = {
    body,
    listeners: {},
    addEventListener(type, handler) {
      this.listeners[type] = handler;
    },
    querySelector(selector) {
      return selector === '.status' && options.withStatus !== false ? status : null;
    },
    createElement,
    getElementById(id) {
      return elementsById[id] || null;
    }
  };

  function WebSocket(url) {
    this.url = url;
    this.readyState = 0;
    this.sent = [];
    sockets.push(this);
  }
  WebSocket.OPEN = 1;
  WebSocket.prototype.send = function send(payload) {
    this.sent.push(payload);
  };

  const sessionStorage = {
    getItem(name) {
      if (options.storageThrows) throw new Error('storage unavailable');
      assert.strictEqual(name, 'brainstorm-session-key');
      return Object.prototype.hasOwnProperty.call(options, 'key') ? options.key : null;
    }
  };

  const module = { exports: {} };
  const sandbox = {
    module,
    exports: module.exports,
    window: {
      location: {
        host: 'localhost:3333',
        replace(url) {
          calls.replace.push(url);
        },
        reload() {
          calls.reload++;
        }
      },
      sessionStorage
    },
    document,
    WebSocket,
    Date: { now: () => 12345 },
    JSON,
    encodeURIComponent,
    setTimeout(fn, delay) {
      const timer = { fn, delay, cleared: false };
      timers.push(timer);
      return timer;
    },
    clearTimeout(timer) {
      if (timer) timer.cleared = true;
    }
  };
  sandbox.window.WebSocket = WebSocket;
  sandbox.window.setTimeout = sandbox.setTimeout;
  sandbox.window.clearTimeout = sandbox.clearTimeout;
  vm.runInNewContext(source, sandbox, { filename: HELPER_PATH });

  return { ...sandbox, timers, sockets, status, body, calls };
}

function runDueTimers(browser, delay) {
  const due = browser.timers.filter(timer => timer.delay === delay && !timer.cleared);
  due.forEach(timer => {
    timer.cleared = true;
    timer.fn();
  });
}

function test(name, fn) {
  try {
    fn();
    console.log(`  PASS: ${name}`);
    return 0;
  } catch (error) {
    console.log(`  FAIL: ${name}`);
    console.log(`    ${error.message}`);
    return 1;
  }
}

let failed = 0;

failed += test('exports reconnect constants and pure delay helper', () => {
  const helper = loadHelperExports();
  assert.strictEqual(helper.MIN_RECONNECT_MS, 500);
  assert.strictEqual(helper.MAX_RECONNECT_MS, 30000);
  assert(helper.TOMBSTONE_AFTER_MS >= 5000);
  assert.strictEqual(helper.nextReconnectDelay(500, 30000), 1000);
  assert.strictEqual(helper.nextReconnectDelay(20000, 30000), 30000);
});

failed += test('source contains connection statuses and tombstone copy', () => {
  assert(source.includes('Connected'));
  assert(source.includes('Reconnecting'));
  assert(source.includes('Disconnected'));
  assert(source.includes('bs-tombstone'));
  assert(source.includes('Companion paused'));
});

failed += test('stored key is included in the WebSocket URL', () => {
  const browser = loadBrowser({ key: 'abc 123' });
  assert.strictEqual(browser.sockets[0].url, 'ws://localhost:3333/?key=abc%20123');
});

failed += test('missing or unreadable key uses cookie-only WebSocket URL', () => {
  assert.strictEqual(loadBrowser({ key: null }).sockets[0].url, 'ws://localhost:3333');
  assert.strictEqual(loadBrowser({ storageThrows: true }).sockets[0].url, 'ws://localhost:3333');
});

failed += test('close updates status, nulls socket, and schedules a 500 ms reconnect', () => {
  const browser = loadBrowser({ key: 'abc' });
  browser.sockets[0].onclose();
  assert.strictEqual(browser.status.textContent, 'Reconnecting...');
  assert.strictEqual(browser.status.style.values['--status-color'], '#c77d00');
  assert(browser.timers.some(timer => timer.delay === 500 && !timer.cleared));
  browser.window.brainstorm.send({ type: 'choice', value: 'queued' });
  assert.strictEqual(browser.sockets[0].sent.length, 0);
});

failed += test('reconnect delay backs off and caps at 30000 ms', () => {
  const browser = loadBrowser({ key: 'abc' });
  browser.sockets[0].onclose();
  runDueTimers(browser, 500);
  browser.sockets[1].onclose();
  runDueTimers(browser, 1000);
  browser.sockets[2].onclose();
  assert(browser.timers.some(timer => timer.delay === 2000 && !timer.cleared));

  const helper = loadHelperExports();
  let delay = helper.MIN_RECONNECT_MS;
  for (let i = 0; i < 10; i++) delay = helper.nextReconnectDelay(delay, helper.MAX_RECONNECT_MS);
  assert.strictEqual(delay, 30000);
});

failed += test('tombstone appears once after grace period', () => {
  const browser = loadBrowser({ key: 'abc' });
  browser.sockets[0].onclose();
  runDueTimers(browser, browser.module.exports.TOMBSTONE_AFTER_MS);
  runDueTimers(browser, browser.module.exports.TOMBSTONE_AFTER_MS);
  const tombstones = browser.body.children.filter(child => child.id === 'bs-tombstone');
  assert.strictEqual(tombstones.length, 1);
  assert(tombstones[0].className.includes('bs-tombstone'));
  assert(tombstones[0].textContent.includes('Companion paused'));
  assert.strictEqual(browser.status.textContent, 'Disconnected');
});

failed += test('recovery after tombstone reboots with stored key', () => {
  const browser = loadBrowser({ key: 'abc 123' });
  browser.sockets[0].onclose();
  runDueTimers(browser, browser.module.exports.TOMBSTONE_AFTER_MS);
  runDueTimers(browser, 500);
  browser.sockets[1].readyState = browser.WebSocket.OPEN;
  browser.sockets[1].onopen();
  assert.deepStrictEqual(browser.calls.replace, ['/?key=abc%20123']);
  assert.strictEqual(browser.calls.reload, 0);
});

failed += test('recovery after tombstone reloads without stored key', () => {
  const browser = loadBrowser({ key: null });
  browser.sockets[0].onclose();
  runDueTimers(browser, browser.module.exports.TOMBSTONE_AFTER_MS);
  runDueTimers(browser, 500);
  browser.sockets[1].readyState = browser.WebSocket.OPEN;
  browser.sockets[1].onopen();
  assert.strictEqual(browser.calls.reload, 1);
  assert.deepStrictEqual(browser.calls.replace, []);
});

console.log(`\n--- Results: ${9 - failed} passed, ${failed} failed ---`);
if (failed > 0) process.exit(1);
