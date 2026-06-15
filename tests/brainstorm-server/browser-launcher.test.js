const assert = require('assert');
const path = require('path');

const SERVER_PATH = path.join(__dirname, '../../skills/brainstorming/scripts/server.cjs');
const { browserLauncherForPlatform } = require(SERVER_PATH);

const URL = 'http://localhost:3333/?key=a&x=/c';

function runTests() {
  let passed = 0;
  let failed = 0;

  function test(name, fn) {
    try {
      fn();
      console.log(`  PASS: ${name}`);
      passed++;
    } catch (e) {
      console.log(`  FAIL: ${name}`);
      console.log(`    ${e.message}`);
      failed++;
    }
  }

  test('Windows launcher uses rundll32 without command interpreter args', () => {
    const launcher = browserLauncherForPlatform(URL, { platform: 'win32' });
    assert.deepStrictEqual(launcher, {
      bin: 'rundll32.exe',
      args: ['url.dll,FileProtocolHandler', URL]
    });
    assert(!launcher.args.includes('/c'), 'Windows launcher must not include /c');
  });

  test('WSL launcher uses Windows URL handler', () => {
    const launcher = browserLauncherForPlatform(URL, {
      platform: 'linux',
      osRelease: '5.15.146.1-microsoft-standard-WSL2',
      env: {}
    });
    assert.deepStrictEqual(launcher, {
      bin: 'rundll32.exe',
      args: ['url.dll,FileProtocolHandler', URL]
    });
  });

  test('headless Linux returns null', () => {
    assert.strictEqual(browserLauncherForPlatform(URL, {
      platform: 'linux',
      osRelease: '6.8.0',
      env: {}
    }), null);
  });

  test('Linux display uses xdg-open', () => {
    assert.deepStrictEqual(browserLauncherForPlatform(URL, {
      platform: 'linux',
      osRelease: '6.8.0',
      env: { DISPLAY: ':0' }
    }), { bin: 'xdg-open', args: [URL] });
  });

  test('Linux Wayland display uses xdg-open', () => {
    assert.deepStrictEqual(browserLauncherForPlatform(URL, {
      platform: 'linux',
      osRelease: '6.8.0',
      env: { WAYLAND_DISPLAY: 'wayland-0' }
    }), { bin: 'xdg-open', args: [URL] });
  });

  test('macOS uses open', () => {
    assert.deepStrictEqual(browserLauncherForPlatform(URL, {
      platform: 'darwin',
      env: {}
    }), { bin: 'open', args: [URL] });
  });

  console.log(`\n--- Results: ${passed} passed, ${failed} failed ---`);
  if (failed > 0) process.exit(1);
}

runTests();
