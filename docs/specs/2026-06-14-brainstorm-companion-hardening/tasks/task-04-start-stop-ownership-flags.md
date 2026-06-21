# Task 04: Start/Stop Ownership and Runtime Flags

## Status

complete

## Phase

3

## Description

Adapt the shell launch and stop scripts to the hardened server contract. The server now supports persisted port/token files, configurable idle timeout, opt-in browser launch, and a server instance id. The scripts need to preserve `.s-kit/brainstorm/` project state, pass the right environment, and ensure `stop-server.sh` never kills an unrelated process whose PID was recycled.

## Dependencies

**Depends on:** task-02-server-lifecycle-persistence-browser.md
**Blocks:** task-05-docs-test-wiring.md

**Context from dependencies:** Task 02 adds `BRAINSTORM_PORT_FILE`, `BRAINSTORM_TOKEN_FILE`, `BRAINSTORM_IDLE_TIMEOUT_MS`, `BRAINSTORM_OPEN`, browser-open behavior, and `--brainstorm-server-id=<id>` support in `server.cjs`. This task wires those capabilities through `start-server.sh` and uses the server instance id in `stop-server.sh` to prove process ownership before signaling.

## Files to Create

- `tests/brainstorm-server/start-server.test.sh` - shell tests for Windows-like owner PID clearing, foreground detection, `.s-kit` state, server instance id, and new flags.
- `tests/brainstorm-server/stop-server.test.sh` - shell tests for PID ownership safety, stale PID handling, real server stop, persistent stop metadata, and malformed id fail-closed behavior.

## Files to Modify

- `skills/brainstorming/scripts/start-server.sh` - add flags, owner-only state, persistent port/token files, server instance id, and Windows-like owner PID clearing.
- `skills/brainstorming/scripts/stop-server.sh` - verify PID ownership with server instance id before signaling; write stopped metadata.
- `tests/brainstorm-server/windows-lifecycle.test.sh` - update stale references from `server.js` and dotfile state paths to the current `server.cjs` and `state/` layout.

## Technical Details

### Implementation Steps

1. Harden state file permissions in `start-server.sh`:
   - Set `umask 077` before creating session directories or state files.
   - Keep project sessions under `${PROJECT_DIR}/.s-kit/brainstorm/${SESSION_ID}`.
   - Keep non-project sessions under `/tmp/brainstorm-${SESSION_ID}`.
   - Create `content/` and `state/` as peers under `SESSION_DIR`.

2. Add arguments to `start-server.sh`:
   - `--idle-timeout-minutes <minutes>` - positive numeric minutes, converted to milliseconds and passed as `BRAINSTORM_IDLE_TIMEOUT_MS`.
   - `--open` - opt-in flag that sets `BRAINSTORM_OPEN=1`.
   - Preserve existing `--project-dir`, `--host`, `--url-host`, `--foreground`, and `--background`.
   - Unknown arguments still return JSON error and non-zero exit.

3. Generate and persist server instance id:
   - Create a shell-safe random id matching `^[A-Za-z0-9_-]{32,64}$`.
   - Write it to `${STATE_DIR}/server-instance-id`.
   - Pass it to Node exactly as an argv element: `node server.cjs "--brainstorm-server-id=${SERVER_ID}"`.
   - Do this in both foreground and background modes.

4. Pass persisted state files to the server:
   - `BRAINSTORM_PORT_FILE="${STATE_DIR}/.last-port"`
   - `BRAINSTORM_TOKEN_FILE="${STATE_DIR}/.last-token"`
   - Continue passing `BRAINSTORM_DIR`, `BRAINSTORM_HOST`, `BRAINSTORM_URL_HOST`, and `BRAINSTORM_OWNER_PID`.
   - Add `BRAINSTORM_IDLE_TIMEOUT_MS` only when `--idle-timeout-minutes` is supplied.
   - Add `BRAINSTORM_OPEN=1` only when `--open` is supplied.

5. Fix Windows-like owner PID behavior:
   - Existing auto-foreground behavior for Windows-like shells should remain.
   - Clear `OWNER_PID` for Windows-like shells because Node cannot reliably observe MSYS2/Git Bash PID namespaces.
   - Treat these as Windows-like:
     - `OSTYPE` begins with `msys`, `cygwin`, or `mingw`
     - `MSYSTEM` is set
     - `uname -s` reports a Windows-like value such as `MINGW64_NT-*`

6. Update background startup behavior:
   - Write actual background PID to `state/server.pid`.
   - Wait for `server-started` in `state/server.log`.
   - If background process is reaped, keep the existing helpful foreground retry error but include the new flags when relevant.
   - Print the first `server-started` JSON line on success.

7. Harden `stop-server.sh`:
   - Read `${STATE_DIR}/server.pid` and `${STATE_DIR}/server-instance-id`.
   - Validate server instance id against `^[A-Za-z0-9_-]{32,64}$`; malformed or missing id should fail closed as stale.
   - Inspect the target PID command line using `ps`, and signal only if the command line contains both `server.cjs` and `--brainstorm-server-id=<id>`.
   - If the PID is missing, stale, unrelated, malformed, or wrong id:
     - do not signal it
     - remove stale `server.pid` and `server-instance-id`
     - remove alive metadata such as `server-info`
     - write `state/server-stopped` with reason `stale_pid`
     - output `{"status":"stale_pid"}`
   - For a real matching server:
     - send graceful signal, wait briefly, then escalate to `-9` only if still alive
     - remove `server.pid`, `server.log`, `server-info`, and `server-instance-id`
     - write `state/server-stopped` with reason `stop-server.sh`
     - keep persistent `.s-kit` sessions and only delete ephemeral `/tmp/*` sessions
     - output `{"status":"stopped"}`

8. Add `start-server.test.sh`:
   - Use a fake `node` on `PATH` to capture env vars and argv.
   - Fake `uname -s` to return a Windows-like value and assert `BRAINSTORM_OWNER_PID` is empty/unset.
   - Assert the Node argv includes exactly one `--brainstorm-server-id=<safe id>` argument.
   - Assert `server-instance-id` is written under `.s-kit/brainstorm/.../state/`, not `.superpowers`.
   - Assert Windows-like detection auto-foregrounds.
   - Assert `--idle-timeout-minutes 5` passes `BRAINSTORM_IDLE_TIMEOUT_MS=300000`.
   - Assert `--open` passes `BRAINSTORM_OPEN=1`.
   - Assert `BRAINSTORM_PORT_FILE` and `BRAINSTORM_TOKEN_FILE` point under `state/.last-port` and `state/.last-token`.

9. Add `stop-server.test.sh`:
   - Unrelated `sleep` PID in `server.pid` is not killed and returns `stale_pid`.
   - Real brainstorm server with matching instance id is stopped.
   - Persistent session stop clears `server-info` and writes `server-stopped` with reason `stop-server.sh`.
   - Missing pid file reports `not_running`.
   - `node server.cjs` impostor with missing id is not killed.
   - Impostor with wrong id is not killed.
   - Malformed instance id is fail-closed and does not signal.

10. Fix `windows-lifecycle.test.sh`:
    - Replace `server.js` with `server.cjs`.
    - Replace `.server-info` with `state/server-info`.
    - Replace `.server.pid` with `state/server.pid`.
    - Use configurable lifecycle env vars where possible to avoid 75-second sleeps.
    - Keep platform-specific tests skipped on non-Windows-like shells where appropriate.

### Code Snippets

Node launch shape:

```bash
env \
  BRAINSTORM_DIR="$SESSION_DIR" \
  BRAINSTORM_HOST="$BIND_HOST" \
  BRAINSTORM_URL_HOST="$URL_HOST" \
  BRAINSTORM_OWNER_PID="$OWNER_PID" \
  BRAINSTORM_PORT_FILE="$STATE_DIR/.last-port" \
  BRAINSTORM_TOKEN_FILE="$STATE_DIR/.last-token" \
  ${IDLE_TIMEOUT_MS:+BRAINSTORM_IDLE_TIMEOUT_MS="$IDLE_TIMEOUT_MS"} \
  ${OPEN_BROWSER:+BRAINSTORM_OPEN=1} \
  node server.cjs "--brainstorm-server-id=$SERVER_ID"
```

Use arrays or explicit env assignments where needed so empty optional vars do not create broken shell syntax.

Instance id validation:

```bash
case "$server_id" in
  *[!A-Za-z0-9_-]*|"") stale="true" ;;
esac
```

## Verification Plan

### RED

- Command: `cd tests/brainstorm-server && bash start-server.test.sh`
- Expected: fails before implementation because the test file does not exist or `start-server.sh` lacks server instance id/new flag behavior.

- Command: `cd tests/brainstorm-server && bash stop-server.test.sh`
- Expected: fails before implementation because the test file does not exist or stale PID protection is missing.

### GREEN

- Command: `cd tests/brainstorm-server && bash start-server.test.sh && bash stop-server.test.sh`
- Expected: both shell test suites pass.

### Final Verification

- Command: `cd tests/brainstorm-server && bash windows-lifecycle.test.sh`
- Expected: passes or skips platform-specific sections cleanly on the current shell; no references to `server.js`, `.server-info`, or `.server.pid` remain.

## Acceptance Criteria

- [ ] Project sessions still use `.s-kit/brainstorm/`.
- [ ] State files are created with owner-only permissions where supported.
- [ ] `--idle-timeout-minutes` and `--open` are parsed and passed to the server.
- [ ] A safe server instance id is written and passed as a Node argv element.
- [ ] Windows-like shells clear unsafe owner PID monitoring.
- [ ] `stop-server.sh` never signals an unrelated or stale PID.
- [ ] Real matching brainstorm servers are stopped and write stopped metadata.
- [ ] Persistent sessions are not deleted by stop.
- [ ] Existing Windows lifecycle test uses current server/state paths.

## Notes

Do not copy upstream `.superpowers` path assertions. Every persistent path assertion in this repo must use `.s-kit`.
