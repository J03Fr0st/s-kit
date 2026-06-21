# Task 02: Server Lifecycle, Persistence, and Browser Launch

## Status

complete

## Phase

2

## Description

Finish the hardened server behavior that sits below the shell launcher: configurable idle timeout, clean shutdown with open WebSockets, preferred port/token persistence, safe fallback semantics, and opt-in browser launching. This task only touches `server.cjs` and server-focused tests so it can run in parallel with the helper update.

## Dependencies

**Depends on:** task-01-server-auth-websocket-gate.md
**Blocks:** task-04-start-stop-ownership-flags.md, task-05-docs-test-wiring.md

**Context from dependencies:** Task 01 adds the session key, cookie name, security headers, WebSocket auth/origin checks, `companionUrl()`, and `MAX_FRAME_PAYLOAD_BYTES`. This task builds on that auth contract so persisted tokens, browser-open URLs, and reconnect tests use the same key-bearing URL.

## Files to Create

- `tests/brainstorm-server/browser-launcher.test.js` - pure tests for platform browser launcher selection and shell-injection avoidance.
- `tests/brainstorm-server/lifecycle.test.js` - server lifecycle tests for idle shutdown, port/token persistence, fallback behavior, browser auto-open, and unauthorized activity.

## Files to Modify

- `skills/brainstorming/scripts/server.cjs` - add lifecycle settings, persistent port/token support, safe fallback behavior, browser launch helper, and socket-closing shutdown.

## Technical Details

### Implementation Steps

1. Add configurable idle timeout:
   - Default `IDLE_TIMEOUT_MS` should be 4 hours.
   - Read `BRAINSTORM_IDLE_TIMEOUT_MS`; use it only when it is a positive finite number.
   - Read `BRAINSTORM_LIFECYCLE_CHECK_MS`; use it only when it is a positive finite number. Keep 60 seconds as the production default.
   - Include `idle_timeout_ms` in the `server-started` JSON and `state/server-info`.

2. Make shutdown complete with open sockets:
   - Track all accepted WebSocket sockets in `clients`.
   - On shutdown, send/close or destroy sockets so `server.close()` can complete.
   - Clear the lifecycle interval and file watcher.
   - Remove `state/server-info`.
   - Write `state/server-stopped` as JSON containing at least `reason` and `timestamp`.
   - Exit cleanly with code 0 for normal idle/owner shutdown.

3. Add preferred port support:
   - `BRAINSTORM_PORT` remains the highest-priority explicit port.
   - `BRAINSTORM_PORT_FILE` points to a persisted preferred port file.
   - If no explicit `BRAINSTORM_PORT` is supplied and the port file contains a valid port, try that port.
   - Otherwise choose a random high port in the existing range.
   - When binding succeeds on the preferred port, write the actual port back to the port file.
   - Do not overwrite the port file after an `EADDRINUSE` fallback.

4. Add persisted token support:
   - `BRAINSTORM_TOKEN` remains the highest-priority explicit token.
   - `BRAINSTORM_TOKEN_FILE` points to a persisted token file.
   - If no explicit token is supplied and the token file contains a valid hex token, reuse it.
   - Otherwise generate a new random token.
   - When binding succeeds on the preferred port, write the token file with owner-only permissions.
   - Harden existing token file permissions to owner-only where the platform supports chmod.

5. Add safe fallback behavior:
   - If the preferred port is in use and token source is `env` from `BRAINSTORM_TOKEN`, fail closed with a non-zero exit and an error mentioning `BRAINSTORM_TOKEN`.
   - If the preferred port is in use and token source is `file`, fall back to a random high port with a fresh generated token and do not overwrite `.last-port` or `.last-token`.
   - The fallback key must not authenticate to the original server on the preferred port.

6. Add browser launcher selection:
   - Export `browserLauncherForPlatform(url, opts = {})`.
   - For `platform: 'darwin'`, return `{ bin: 'open', args: [url] }`.
   - For `platform: 'win32'`, return `{ bin: 'rundll32.exe', args: ['url.dll,FileProtocolHandler', url] }`.
   - For WSL detected by Linux platform and an OS release containing `microsoft`, use the same `rundll32.exe` launcher.
   - For Linux with `DISPLAY` or `WAYLAND_DISPLAY`, return `{ bin: 'xdg-open', args: [url] }`.
   - For headless Linux, return `null`.
   - Do not route platform launcher URLs through `cmd.exe`, `sh -c`, or other command interpreters.

7. Add opt-in browser auto-open:
   - Enable only when `BRAINSTORM_OPEN` is set.
   - Open only once, on the first screen that is actually available.
   - Skip auto-open when `HOST` is not loopback (`127.0.0.1` or `localhost`).
   - Skip if a browser/WebSocket client is already connected.
   - Open the key-bearing `companionUrl()`, not the bare URL.
   - Use `child_process.execFile` for platform launchers.
   - `BRAINSTORM_OPEN_CMD` is trusted operator input for tests and custom environments; keep it opt-in and append/pass the URL in a way that preserves it as one argument.

8. Add `browser-launcher.test.js`:
   - Windows launcher returns `rundll32.exe` with argv `['url.dll,FileProtocolHandler', url]`.
   - WSL returns the same `rundll32.exe` launcher.
   - Headless Linux returns `null`.
   - Linux with a display returns `xdg-open`.
   - macOS returns `open`.
   - Assert no Windows launcher args include `/c`.

9. Add `lifecycle.test.js` with server-only tests:
   - `server-info` reports configured `idle_timeout_ms`.
   - Idle shutdown closes an open authenticated WebSocket and process exits.
   - IPv6 `BRAINSTORM_URL_HOST` is bracketed in the startup URL.
   - Port and token are persisted and reused across restart.
   - Existing persisted token file permissions are hardened.
   - Stored key authenticates WebSocket after same-port restart.
   - Preferred port fallback chooses a different high port and does not overwrite `.last-port`.
   - Fallback with persisted token generates a fresh unpersisted key and does not overwrite `.last-token`.
   - Fallback with explicit `BRAINSTORM_TOKEN` fails closed.
   - `BRAINSTORM_OPEN` plus test `BRAINSTORM_OPEN_CMD` opens exactly once on first screen and the opened URL contains `?key=`.
   - Without `BRAINSTORM_OPEN`, no browser launch happens.
   - A flood of unauthenticated 403 requests does not prevent idle timeout.

### Code Snippets

Idle timeout parsing:

```js
function positiveMsFromEnv(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

const IDLE_TIMEOUT_MS = positiveMsFromEnv('BRAINSTORM_IDLE_TIMEOUT_MS', 4 * 60 * 60 * 1000);
const LIFECYCLE_CHECK_MS = positiveMsFromEnv('BRAINSTORM_LIFECYCLE_CHECK_MS', 60 * 1000);
```

Browser launcher shape:

```js
function browserLauncherForPlatform(url, {
  platform = process.platform,
  osRelease = require('os').release(),
  env = process.env
} = {}) {
  // return { bin, args } or null
}
```

### Environment Variables

- `BRAINSTORM_IDLE_TIMEOUT_MS` - idle timeout in milliseconds.
- `BRAINSTORM_LIFECYCLE_CHECK_MS` - lifecycle check interval in milliseconds, mainly for tests.
- `BRAINSTORM_PORT_FILE` - persisted preferred port file.
- `BRAINSTORM_TOKEN_FILE` - persisted session token file.
- `BRAINSTORM_OPEN` - enables opt-in browser auto-open.
- `BRAINSTORM_OPEN_CMD` - trusted operator/test command used instead of platform launcher.

## Verification Plan

### RED

- Command: `cd tests/brainstorm-server && node browser-launcher.test.js`
- Expected: fails before implementation because the test file does not exist or `browserLauncherForPlatform` is not exported.

- Command: `cd tests/brainstorm-server && node lifecycle.test.js`
- Expected: fails before implementation because lifecycle persistence, idle timeout reporting, and auto-open behavior are missing.

### GREEN

- Command: `cd tests/brainstorm-server && node browser-launcher.test.js && node lifecycle.test.js`
- Expected: both tests pass without opening a real browser.

### Final Verification

- Command: `cd tests/brainstorm-server && node auth.test.js && node server.test.js`
- Expected: auth and existing server behavior still pass after the lifecycle changes.

## Acceptance Criteria

- [ ] `server-started` JSON includes `idle_timeout_ms`.
- [ ] Idle shutdown exits cleanly even with an open authenticated WebSocket.
- [ ] Unauthorized requests do not keep the server alive.
- [ ] Preferred port and token are persisted and reused when safe.
- [ ] Fallback port behavior does not hijack another session's token or overwrite shared state.
- [ ] Explicit-token fallback fails closed.
- [ ] Browser launcher selection is platform-aware and does not shell-interpolate platform URLs.
- [ ] Browser auto-open is opt-in, loopback-only, opens once, and uses a key-bearing URL.

## Notes

Keep start-script parsing of `--idle-timeout-minutes` and `--open` out of this task. Task 04 wires those shell flags into the server environment.
