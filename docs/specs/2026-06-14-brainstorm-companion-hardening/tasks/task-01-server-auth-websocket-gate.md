# Task 01: Server Auth and WebSocket Protocol Gate

## Status

complete

## Phase

1

## Description

Add the core security gate to the brainstorm companion server. Today `server.cjs` serves screens and accepts WebSocket events from any client that can reach the bound host. This task introduces a per-session key, protected HTTP and WebSocket access, security headers, and a maximum WebSocket frame payload size. Later tasks depend on this behavior for stable reconnect, lifecycle, and script integration.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-02-server-lifecycle-persistence-browser.md, task-03-helper-key-reconnect.md

**Context from dependencies:** None. This task establishes the server-side auth and protocol contract consumed by later tasks.

## Files to Create

- `tests/brainstorm-server/auth.test.js` - security tests for HTTP auth, cookies, WebSocket auth, security headers, and unauthorized activity behavior.

## Files to Modify

- `skills/brainstorming/scripts/server.cjs` - add token auth, security headers, WebSocket auth/origin checks, safer file serving, and frame payload caps.
- `tests/brainstorm-server/server.test.js` - update existing integration tests to use the key-bearing URL or cookie when talking to the server.
- `tests/brainstorm-server/ws-protocol.test.js` - add protocol tests for maximum advertised payload rejection and exported frame cap.

## Technical Details

### Implementation Steps

1. Keep the existing zero-dependency CommonJS server. Do not add runtime dependencies.

2. Add a frame cap:
   - Constant: `MAX_FRAME_PAYLOAD_BYTES = 10 * 1024 * 1024`.
   - Export it from `module.exports`.
   - In `decodeFrame`, reject advertised payload lengths larger than this cap before allocating payload buffers.
   - Apply the cap for 16-bit and 64-bit extended lengths.
   - Error message should include enough text for tests to match `/exceeds maximum allowed size/i`.

3. Add token creation and comparison:
   - If `process.env.BRAINSTORM_TOKEN` exists, use it as the session key.
   - Otherwise generate a random token with `crypto.randomBytes(32).toString('hex')`.
   - Add `timingSafeEqualStr(a, b)` using `crypto.timingSafeEqual` after converting both strings to buffers. If lengths differ, return false without throwing.
   - Do not log the token except as part of the required key-bearing startup URL.

4. Add URL and cookie helpers:
   - `companionUrl()` should return `http://<urlHost>:<port>/?key=<token>`.
   - Bracket IPv6 URL hosts, for example `http://[::1]:3421/?key=...`.
   - Cookie name should be port-scoped: `brainstorm-key-<actualPort>`.
   - Parse query params with the standard `URL` API or equivalent robust parsing. Do not rely on raw string splitting for authorization.
   - Parse cookies from the `Cookie` header.

5. Add security headers to all HTTP responses:

   ```js
   {
     'Referrer-Policy': 'no-referrer',
     'Cache-Control': 'no-store',
     'X-Frame-Options': 'DENY',
     'Content-Security-Policy': "frame-ancestors 'none'",
     'Cross-Origin-Resource-Policy': 'same-origin'
   }
   ```

6. Add forbidden handling:
   - Unauthorized requests return `403` and a small HTML page explaining that the coding agent session key is required.
   - Unauthorized requests must return the security headers.
   - Unauthorized requests must not call `touchActivity()`.

7. Add HTTP auth:
   - Request is authorized when it has a valid `?key=<token>` or a valid cookie named `brainstorm-key-<port>`.
   - If an explicit query key is present and wrong, reject the request even if a valid cookie is also present.
   - `GET /?key=<token>` returns a bootstrap HTML page, not screen content. The bootstrap should store the key in `sessionStorage` under `brainstorm-session-key` and call `location.replace('/')`. If storage fails, it should still redirect to `/`.
   - `GET /` with a valid cookie serves the waiting page or newest screen.
   - `GET /files/<name>` requires auth and serves only regular files inside `CONTENT_DIR`. Use `path.basename` plus a regular-file check to avoid directories, dotfiles, and traversal.
   - 404 responses should also include security headers.

8. Add cookie behavior:
   - Authorized responses should set `Set-Cookie: brainstorm-key-<port>=<token>; HttpOnly; SameSite=Strict; Path=/`.
   - The keyed bootstrap page should include this cookie header.

9. Add WebSocket auth and origin checks:
   - Reject upgrades without a valid key or cookie.
   - Allow direct non-browser WebSocket clients without an `Origin` header when authenticated.
   - For browser clients with `Origin`, allow only same-origin values for the current companion URL host and port.
   - Reject cross-origin browser upgrades even with a valid cookie, because a hostile local browser page could otherwise inject events into `state/events`.
   - Only authenticated WebSocket messages should call `touchActivity()` and append choice events.

10. Update `server.test.js`:
    - Start the server with a fixed `BRAINSTORM_TOKEN`, for example `servertesttoken`.
    - Read the startup JSON and use either the `url` field or an auth cookie for HTTP requests.
    - WebSocket URLs should include `?key=<token>` or use the valid cookie.
    - Preserve existing behavior assertions: waiting page, helper injection, full document serving, fragments, newest file, 404s, event writing, malformed JSON handling, file watching, frame template checks.

11. Add `auth.test.js` with the following coverage:
    - startup URL includes `?key=<token>`
    - keyless `GET /` returns 403
    - wrong-key `GET /` returns 403
    - wrong query key plus valid cookie returns 403
    - 403 responses include all security headers
    - valid keyed `GET /` returns bootstrap and does not include screen content
    - bootstrap still redirects when `sessionStorage.setItem` throws
    - valid keyed response sets HttpOnly SameSite=Strict cookie
    - valid cookie on bare `GET /` serves the protected screen
    - `/files` is 403 without auth and serves content with valid key
    - WebSocket without auth is rejected
    - WebSocket with valid key opens
    - WebSocket with valid cookie opens
    - same-origin browser WebSocket opens
    - cross-origin browser WebSocket is rejected and does not write `state/events`
    - JSON payload `null` over an authorized socket does not crash the server

12. Add to `ws-protocol.test.js`:
    - Assert `ws.MAX_FRAME_PAYLOAD_BYTES` is exported.
    - Construct a masked 64-bit header advertising `MAX_FRAME_PAYLOAD_BYTES + 1` with no payload and assert `decodeFrame` throws before allocation.

### Code Snippets

Security header helper shape:

```js
function securityHeaders(headers = {}) {
  return {
    'Referrer-Policy': 'no-referrer',
    'Cache-Control': 'no-store',
    'X-Frame-Options': 'DENY',
    'Content-Security-Policy': "frame-ancestors 'none'",
    'Cross-Origin-Resource-Policy': 'same-origin',
    ...headers
  };
}
```

Bootstrap behavior:

```html
<script>
try { sessionStorage.setItem('brainstorm-session-key', KEY_FROM_SERVER); }
catch (e) {}
location.replace('/');
</script>
```

Cookie name:

```js
let COOKIE_NAME = 'brainstorm-key-' + PORT;
```

### Environment Variables

- `BRAINSTORM_TOKEN` - explicit session key used by tests and operator overrides.
- `BRAINSTORM_PORT` - fixed port for tests.
- `BRAINSTORM_DIR` - test session directory.

### API Endpoints

- `GET /?key=<token>` - authorized bootstrap response that stores the key and redirects to `/`.
- `GET /` - serves current screen only when authenticated by cookie.
- `GET /files/<basename>` - serves a regular file from `CONTENT_DIR` only when authenticated.
- `WS /?key=<token>` - accepts authorized WebSocket client.

## Verification Plan

### RED

- Command: `cd tests/brainstorm-server && node auth.test.js`
- Expected: fails before implementation because `auth.test.js` does not exist or because keyless requests are still accepted.

- Command: `cd tests/brainstorm-server && node ws-protocol.test.js`
- Expected: fails after adding the oversized-frame test because `MAX_FRAME_PAYLOAD_BYTES` is not exported and oversized frames are not rejected.

### GREEN

- Command: `cd tests/brainstorm-server && node auth.test.js && node ws-protocol.test.js && node server.test.js`
- Expected: all three commands pass. Existing server integration behavior still works through authenticated requests.

### Final Verification

- Command: `npm run verify:assets`
- Expected: generated skill assets still satisfy the packaging asset check.

## Acceptance Criteria

- [ ] Startup JSON includes a key-bearing `url`.
- [ ] Unauthorized HTTP requests receive 403 and security headers.
- [ ] Unauthorized HTTP requests do not refresh server activity.
- [ ] Valid keyed requests bootstrap and set the session cookie.
- [ ] Valid cookie requests serve screens and files without exposing content at the keyed bootstrap response.
- [ ] WebSocket upgrades require auth and reject cross-origin browser origins.
- [ ] Cross-origin WebSocket attempts cannot append to `state/events`.
- [ ] `decodeFrame` rejects oversized advertised frames before allocation.
- [ ] Existing server behavior still passes through authenticated integration tests.

## Notes

Use upstream Superpowers tests as reference only. Preserve `s-kit` paths and avoid introducing `.superpowers` anywhere in this repo.
