# Task 03: Helper Key and Reconnect Behavior

## Status

complete

## Wave

2

## Description

Update the injected browser helper so it works with the authenticated companion server and behaves well when the server restarts or pauses. The helper currently connects to `ws://<host>` without a key and retries with a fixed timeout. After Task 01, browser WebSocket connections need the stored session key when available, and users need clearer reconnect/disconnected feedback.

## Dependencies

**Depends on:** task-01-server-auth-websocket-gate.md
**Blocks:** task-05-docs-test-wiring.md

**Context from dependencies:** Task 01 makes `GET /?key=<token>` bootstrap the browser by storing `brainstorm-session-key` in `sessionStorage`, then redirecting to `/`. This helper task consumes that stored key for the WebSocket URL while still allowing cookie-only reconnects when no key is available.

## Files to Create

- `tests/brainstorm-server/helper.test.js` - unit and mocked-browser tests for helper reconnect, session key usage, status text, and tombstone behavior.

## Files to Modify

- `skills/brainstorming/scripts/helper.js` - read stored session key, connect with authenticated WebSocket URLs, add reconnect backoff/status/tombstone behavior, and export pure helper functions for tests.

## Technical Details

### Implementation Steps

1. Preserve the browser IIFE shape and existing public behavior:
   - Clicks on `[data-choice]` still send `{ type: 'click', text, choice, id, timestamp }`.
   - Selection indicator behavior remains intact.
   - `window.toggleSelect` and `window.brainstorm` remain available.

2. Add session-key-aware WebSocket URLs:
   - Read `sessionStorage.getItem('brainstorm-session-key')` in a try/catch.
   - If a key exists, connect to `ws://<window.location.host>/?key=<encoded-key>`.
   - If no key exists or storage read fails, connect to `ws://<window.location.host>` and rely on the HttpOnly cookie.
   - This allows a same-port restart with the same persisted key to recover even if the cookie flow needs rebootstrap.

3. Add reconnect constants and pure helper:
   - `MIN_RECONNECT_MS = 500`
   - `MAX_RECONNECT_MS = 30000`
   - `TOMBSTONE_AFTER_MS` should be at least 5000 ms; use a practical value such as 15000 ms.
   - `nextReconnectDelay(current, max)` should double until capped at max.
   - Export these in CommonJS test environments:

   ```js
   if (typeof module !== 'undefined' && module.exports) {
     module.exports = { nextReconnectDelay, MIN_RECONNECT_MS, MAX_RECONNECT_MS, TOMBSTONE_AFTER_MS };
   }
   ```

4. Add connection status behavior:
   - On open: status text becomes `Connected`, queue drains, reconnect delay resets.
   - On close/error: status text becomes `Reconnecting...` until the tombstone threshold passes.
   - After the grace period: status text becomes `Disconnected` and a single overlay/tombstone element is appended to the page.
   - Use existing `.status` element if present. If absent, behavior should not throw.
   - If changing CSS variables, use `style.setProperty('--status-color', value)`.

5. Add recovery behavior:
   - When a tombstoned connection later opens and a stored key exists, call `window.location.replace('/?key=' + encodeURIComponent(key))` so the server can set a fresh cookie and strip the key again.
   - When tombstoned and no stored key exists, call `window.location.reload()` on recovery.
   - Continue to reload on explicit WebSocket `{ type: 'reload' }` messages.

6. Add robust socket behavior:
   - Set `ws = null` on close so `sendEvent` queues events instead of sending into a closed socket.
   - Clear pending reconnect timers before scheduling a new one.
   - Handle `onerror`.
   - Do not create multiple tombstones.
   - Keep malformed server messages from crashing the helper if feasible.

7. Add `helper.test.js`:
   - Evaluate `helper.js` in a CommonJS sandbox to test `nextReconnectDelay` and constants.
   - Assert source contains status strings `Connected`, `Reconnecting`, and `Disconnected`.
   - Assert source creates a `bs-tombstone` element and text mentioning `Companion paused`.
   - Mock `window`, `document`, `WebSocket`, timers, and `Date.now()` to exercise browser behavior:
     - stored key is included in WebSocket URL
     - no key produces cookie-only WebSocket URL
     - close schedules 500 ms reconnect
     - delay backs off 500 -> 1000 -> 2000 and caps at 30000
     - tombstone appears after grace period
     - recovery with stored key calls `location.replace('/?key=...')`
     - recovery without stored key calls `location.reload()`

### Code Snippets

WebSocket URL helper:

```js
function sessionKey() {
  try { return window.sessionStorage && window.sessionStorage.getItem('brainstorm-session-key'); }
  catch (e) { return null; }
}

function websocketUrl() {
  const key = sessionKey();
  const base = 'ws://' + window.location.host;
  return key ? base + '/?key=' + encodeURIComponent(key) : base;
}
```

Reconnect delay:

```js
function nextReconnectDelay(current, max) {
  return Math.min(current * 2, max);
}
```

### Environment Variables

None.

### API Endpoints

- `WS /?key=<token>` - used when `brainstorm-session-key` is present.
- `WS /` - used when relying on the server's HttpOnly cookie.

## Verification Plan

### RED

- Command: `cd tests/brainstorm-server && node helper.test.js`
- Expected: fails before implementation because `helper.test.js` does not exist or helper exports/session-key behavior are missing.

### GREEN

- Command: `cd tests/brainstorm-server && node helper.test.js`
- Expected: helper tests pass.

### Final Verification

- Command: `cd tests/brainstorm-server && node auth.test.js`
- Expected: server bootstrap and helper key contract remain compatible.

## Acceptance Criteria

- [ ] Helper uses `sessionStorage` key in WebSocket URL when available.
- [ ] Helper falls back to cookie-only WebSocket URL when no stored key exists.
- [ ] Existing click/choice event behavior is preserved.
- [ ] Reconnect delay backs off and caps at 30000 ms.
- [ ] Status text covers connected, reconnecting, and disconnected states.
- [ ] Tombstone overlay appears once after the reconnect grace period.
- [ ] Recovery with a stored key reboots through `/?key=<key>`.
- [ ] Recovery without a stored key reloads the current page.

## Notes

Do not move auth logic into the helper. The server remains the enforcement boundary; the helper only carries the key it was bootstrapped with.
