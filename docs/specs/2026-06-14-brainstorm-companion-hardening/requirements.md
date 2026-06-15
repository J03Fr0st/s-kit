# Requirements: Brainstorm Companion Hardening

## Summary

The brainstorming visual companion currently serves local HTML screens and accepts browser events without a per-session access key. Recent Superpowers work hardened this surface with token-gated HTTP and WebSocket access, security headers, safer browser launch behavior, better lifecycle handling, and broader tests.

This feature selectively adapts those improvements into `s-kit` while preserving existing `s-kit` paths, naming, and workflow contracts. Project-local companion state must remain under `.s-kit/brainstorm/`, and the implementation should stay scoped to the companion server, helper, lifecycle scripts, tests, and companion docs.

The expected outcome is a companion that is safer to expose on loopback or remote binds, harder to accidentally stop incorrectly, more reliable on Windows-like shells, and covered by targeted tests that can be run without relying on the broader package test chain.

## Goals

- Gate all companion HTTP and WebSocket access with a per-session key.
- Add leak-reduction and anti-framing headers to companion responses.
- Reject unauthorized or cross-origin WebSocket event injection.
- Enforce a maximum inbound WebSocket frame payload size.
- Preserve and harden project-local `.s-kit/brainstorm/` session state.
- Persist preferred port and token for stable project sessions when safe.
- Add configurable idle timeout and lifecycle shutdown that closes open sockets.
- Add opt-in safe browser launch behavior for local sessions.
- Prove behavior with focused brainstorm-server tests and a root targeted test script.
- Update visual companion docs for the new access URL, flags, and timeout behavior.

## Non-Goals

- Do not wholesale merge Superpowers.
- Do not introduce `.superpowers` paths into `s-kit`.
- Do not add Kimi, Antigravity, evals, or unrelated upstream skill updates.
- Do not add shell linting as part of this feature.
- Do not replace the visual companion UI or redesign the frame template.
- Do not make this feature responsible for fixing the known full `npm test` `verify:branding` generated `graphify-out` blocker.
- Do not add the brainstorm-server tests to the root `npm test` chain unless explicitly requested later.

## Acceptance Criteria

- [ ] `server.cjs` emits a key-bearing URL and rejects keyless or wrong-key HTTP requests with 403.
- [ ] Authorized keyed loads bootstrap to a bare URL, set an HttpOnly `SameSite=Strict` cookie, and do not serve screen content directly at the keyed URL.
- [ ] Bare authorized loads with the cookie serve the newest screen and protected `/files/*` assets.
- [ ] WebSocket upgrades require a valid key or cookie, and browser-origin upgrades are limited to same-origin requests.
- [ ] Unauthorized HTTP requests do not refresh activity or keep the server alive.
- [ ] Incoming WebSocket frames larger than the maximum payload cap are rejected before large allocation.
- [ ] Server shutdown closes open WebSocket sockets, writes `state/server-stopped`, and removes alive metadata.
- [ ] Project sessions persist safe `.last-port` and `.last-token` files under `.s-kit/brainstorm/<session-id>/state/`.
- [ ] Port fallback does not overwrite another session's persisted port/token and fails closed when an explicit `BRAINSTORM_TOKEN` would be unsafe.
- [ ] `start-server.sh` supports `--idle-timeout-minutes` and `--open`, writes a server instance id, and passes it to Node.
- [ ] `stop-server.sh` verifies PID ownership using the recorded server instance id before signaling.
- [ ] Windows-like shells clear unsafe `BRAINSTORM_OWNER_PID` monitoring assumptions while keeping foreground behavior.
- [ ] The helper connects WebSockets with the stored session key when available and uses backoff/tombstone behavior when disconnected.
- [ ] `npm run test:brainstorm-server` runs the targeted brainstorm-server test suite.
- [ ] Visual companion docs describe the key-bearing URL, sensitive state files, `--open`, `--idle-timeout-minutes`, and the longer default idle timeout.

## Assumptions

- Node.js and Bash are available for the companion tests, matching the current `tests/brainstorm-server` setup.
- The `ws` package remains a test-only dependency under `tests/brainstorm-server`.
- The upstream Superpowers implementation is reference material only; paths and names must be adapted to `s-kit`.
- Existing generated `graphify-out` churn and `verify:branding` failures are unrelated unless this feature touches those generated surfaces.
- Browser launch is best-effort and should be verified through launcher-selection tests, not by opening a real browser in automated tests.

## Technical Constraints

- Keep all companion server runtime dependencies zero-dependency; no new shipped Node packages.
- Use `skills/brainstorming/scripts/server.cjs` as the single companion server entrypoint.
- Keep persistent session files under `.s-kit/brainstorm/<session-id>/state/`.
- Keep `/tmp/brainstorm-*` sessions ephemeral and project sessions persistent.
- Do not shell-interpolate URLs for platform browser launchers; pass URLs as argv with `execFile`.
- Treat `BRAINSTORM_OPEN_CMD` as trusted operator input only and keep it opt-in.
- Tests must avoid long fixed sleeps where configurable lifecycle intervals can make them fast.
- After implementation changes, run `graphify update .` because this repo requires graph refresh after code edits.
