# Design: Brainstorm Companion Hardening

## Context

The Superpowers `dev` branch has continued hardening its brainstorming visual companion after the earlier `s-kit` port. The relevant changes are concentrated around the companion server, lifecycle scripts, authentication, WebSocket handling, browser launch behavior, and tests.

The current `s-kit` brainstorming companion already uses project-local session state under `.s-kit/brainstorm/`, but it lacks several protections now present upstream:

- no per-session access token for HTTP or WebSocket clients
- no security headers on companion pages
- no WebSocket origin/authentication gate
- no maximum frame payload size
- weak PID ownership checks in `stop-server.sh`
- no persistent preferred port/token handling for project sessions
- no opt-in safe browser opener
- less complete Windows/MSYS2 lifecycle behavior
- limited brainstorm-server test coverage

This work is for `s-kit` users who use the brainstorming visual companion locally, including Windows users running through Codex. The goal is to selectively port the hardening that improves security, lifecycle correctness, and confidence without broadening scope into unrelated Superpowers features.

## Approved Approach

Selectively adapt the Superpowers brainstorm companion hardening into the existing `s-kit` implementation.

The adaptation should preserve `s-kit` naming, paths, and workflow contracts. In particular, project-local state stays under `.s-kit/brainstorm/`; this is not a wholesale import of Superpowers `.superpowers` paths or plugin behavior.

The implementation should be test-first where practical:

1. Port or create focused tests for auth, WebSocket protocol, browser launching, helper behavior, lifecycle ownership, and start/stop scripts.
2. Update `server.cjs`, `start-server.sh`, and `stop-server.sh` to satisfy those tests while preserving existing `s-kit` behavior.
3. Update only the visual companion docs needed to describe the new flags and access model.

This approach gives us the main value from recent upstream commits while keeping the change small enough to review and verify.

## Alternatives Considered

- Do nothing - leaves known local companion exposure and lifecycle gaps unresolved.
- Wholesale merge from Superpowers - faster to copy but too risky because it can overwrite `s-kit` paths, names, docs, and workflow assumptions.
- Only add tests - improves visibility but leaves the current companion behavior unchanged.
- Only add token auth - addresses the most obvious exposure but leaves PID ownership, browser launch, frame size, and Windows lifecycle gaps.
- Add shell linting in the same slice - useful later, but it is separate quality-gate work and would expand this feature beyond companion hardening.

## Architecture

The feature has four local surfaces.

`skills/brainstorming/scripts/server.cjs` remains the companion server entrypoint. It should add per-session token authorization for HTTP and WebSocket access, emit security headers, cap incoming frame payload size, persist or regenerate session tokens appropriately, expose a key-bearing companion URL, and close upgraded sockets during shutdown. It should also support a configurable idle timeout and an opt-in safe browser opener.

`skills/brainstorming/scripts/start-server.sh` remains the session launcher. It should keep using `.s-kit/brainstorm/<session-id>/` for persistent project state, create owner-only state files, persist preferred port and token files for stable project sessions, add `--idle-timeout-minutes` and `--open`, generate a per-server instance id, and pass that id to Node as an argument.

`skills/brainstorming/scripts/stop-server.sh` remains the shutdown tool. It should verify that the PID it is about to signal belongs to the recorded brainstorm server instance before sending a signal. Stale PID files should be cleaned up and reported as stale instead of killing an unrelated process.

`tests/brainstorm-server/` should become the companion behavior contract. The local package should cover authentication, WebSocket auth and frame behavior, browser launcher selection, helper behavior, lifecycle ownership, and start/stop script behavior. A root-level script such as `test:brainstorm-server` can provide a convenient targeted verification entrypoint without changing the broader `npm test` contract in this slice.

The data flow stays local:

1. `start-server.sh` prepares `.s-kit/brainstorm/<session-id>/state/`.
2. It writes or reuses preferred port/token files with owner-only permissions.
3. It launches `server.cjs` with environment variables and `--brainstorm-server-id=<id>`.
4. `server.cjs` serves only authorized HTTP and WebSocket clients.
5. `stop-server.sh` confirms the running process matches the recorded server id before stopping it.

## Configuration and Inputs

Stored per-session state:

- `.s-kit/brainstorm/<session-id>/state/server.pid`
- `.s-kit/brainstorm/<session-id>/state/server-instance-id`
- `.s-kit/brainstorm/<session-id>/state/server-info.json`
- `.s-kit/brainstorm/<session-id>/state/server-stopped`
- `.s-kit/brainstorm/<session-id>/state/.last-port`
- `.s-kit/brainstorm/<session-id>/state/.last-token`

Command arguments:

- existing `start-server.sh` arguments, including session/project/host/url-host/foreground/background behavior
- new `--idle-timeout-minutes <minutes>` argument
- new `--open` argument for opt-in browser opening

Server environment:

- `BRAINSTORM_PORT_FILE` for preferred port persistence
- `BRAINSTORM_TOKEN_FILE` for token persistence
- `BRAINSTORM_TOKEN` for explicit one-shot token override
- `BRAINSTORM_OPEN` for opt-in browser launch
- `BRAINSTORM_OPEN_CMD` for an operator-provided browser command path
- `BRAINSTORM_IDLE_TIMEOUT_MS` for server idle timeout
- `BRAINSTORM_LIFECYCLE_CHECK_MS` for lifecycle testability
- `BRAINSTORM_OWNER_PID` where the platform can safely observe the owner process

Validation and defaults:

- generated tokens should use strong random bytes
- token comparison should avoid timing leaks for equal-length candidates
- unauthorized HTTP requests should return 403
- unauthorized WebSocket upgrades should be rejected
- WebSocket origins should be restricted to local/allowed origins
- frame payloads larger than the configured cap should be rejected
- explicit `BRAINSTORM_TOKEN` should not silently authorize a different fallback port if the preferred port is occupied
- browser launch should be best-effort, opt-in, loopback-only by default, and should not shell-interpolate URLs

## Decisions

- Preserve `.s-kit/brainstorm/` as the session state root.
- Port the companion hardening selectively instead of merging all recent Superpowers changes.
- Keep Kimi, Antigravity, evals, and unrelated skill updates out of this feature.
- Add focused brainstorm-server tests and a targeted root script, but do not make this slice responsible for fixing the existing full `npm test` branding blocker.
- Treat browser opening as opt-in through `--open`, not automatic default behavior.
- Use a server instance id to prove process ownership before stopping a PID.
- Keep token-bearing URLs and state files local and owner-readable only.

## Risks and Constraints

- Windows, MSYS2, Git Bash, and WSL process identity behavior differs; lifecycle tests must cover the local shell behavior without assuming POSIX PID visibility always works.
- Token-bearing URLs may appear in `server-info.json` or logs; state file permissions and logging discipline matter.
- Binding to `0.0.0.0` or using tunnels changes the threat model; docs should make the key URL requirement explicit.
- Browser auto-open behavior varies by platform and installed handlers, so it must remain best-effort and covered by launcher-selection tests rather than brittle end-to-end UI tests.
- Port fallback behavior is security-sensitive when a token is supplied externally.
- Existing generated `graphify-out` and branding verification noise may affect full-suite verification; this feature should use targeted checks and document any unrelated blocker.

## Verification Strategy

Implementation should be proven with targeted tests first:

- `node ws-protocol.test.js`
- `node helper.test.js`
- `node browser-launcher.test.js`
- `node auth.test.js`
- `node server.test.js`
- `node lifecycle.test.js`
- `bash start-server.test.sh`
- `bash stop-server.test.sh`
- `npm test` from `tests/brainstorm-server/`

Root-level verification should include the workflow checks affected by skill and script changes:

- `npm run verify:naming`
- `npm run verify:assets`
- `npm run verify:agents`
- `npm run verify:workflow`
- `npm run verify:hooks`
- targeted root `npm run test:brainstorm-server` if added

If full `npm test` still fails because of the known `verify:branding` generated `graphify-out` mismatch, record that as an unrelated blocker instead of expanding this feature to fix branding.

After code changes are implemented, run `graphify update .` so the local knowledge graph reflects the modified companion scripts and tests.
