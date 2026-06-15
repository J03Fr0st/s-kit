# Task 05: Docs and Test Package Wiring

## Status

complete

## Wave

4

## Description

Wire the expanded brainstorm-server tests into convenient package scripts and update the visual companion guide for the new security and lifecycle behavior. This task intentionally runs after implementation tasks so the final script reflects the tests that actually exist.

## Dependencies

**Depends on:** task-02-server-lifecycle-persistence-browser.md, task-03-helper-key-reconnect.md, task-04-start-stop-ownership-flags.md
**Blocks:** None

**Context from dependencies:** Task 02 creates `browser-launcher.test.js` and `lifecycle.test.js`; Task 03 creates `helper.test.js`; Task 04 creates `start-server.test.sh` and `stop-server.test.sh` and fixes `windows-lifecycle.test.sh`. This task wires those test files into `tests/brainstorm-server/package.json`, adds a root targeted script, and documents the hardened companion behavior.

## Files to Create

None.

## Files to Modify

- `package.json` - add a root `test:brainstorm-server` script for targeted test execution.
- `tests/brainstorm-server/package.json` - update the nested `test` script to run all targeted companion tests.
- `skills/brainstorming/visual-companion.md` - document key-bearing URLs, sensitive state files, `--open`, `--idle-timeout-minutes`, and default timeout behavior.

## Technical Details

### Implementation Steps

1. Update `tests/brainstorm-server/package.json`:
   - Keep package name and `ws` dependency unchanged.
   - Replace the current script:

   ```json
   "test": "node server.test.js"
   ```

   with:

   ```json
   "test": "node ws-protocol.test.js && node helper.test.js && node browser-launcher.test.js && node auth.test.js && node server.test.js && node lifecycle.test.js && bash start-server.test.sh && bash stop-server.test.sh"
   ```

   - Do not include `windows-lifecycle.test.sh` in the default nested test script unless it has been made fast and reliable on non-Windows shells. It remains available as an explicit targeted check from Task 04.

2. Update root `package.json`:
   - Add:

   ```json
   "test:brainstorm-server": "npm --prefix tests/brainstorm-server test"
   ```

   - Do not add `test:brainstorm-server` to the root `test` chain in this slice. The design explicitly calls for a targeted entrypoint without changing the broader `npm test` contract.
   - Preserve existing scripts and ordering.

3. Check lockfiles:
   - No dependency changes are expected, so `tests/brainstorm-server/package-lock.json` should not need changes.
   - If npm changes the lockfile only because package metadata changed, inspect the diff and keep it only if necessary for npm consistency.

4. Update `skills/brainstorming/visual-companion.md`:
   - Startup JSON examples must show URL with `?key=<token>`.
   - Explain that the URL is sensitive because it contains the session key.
   - `server-info` path remains `$STATE_DIR/server-info`; mention that it may include the key-bearing URL and should be treated as local session state.
   - Document `--open` as opt-in browser opening:

   ```bash
   scripts/start-server.sh --project-dir /path/to/project --open
   ```

   - Document `--idle-timeout-minutes <minutes>`:

   ```bash
   scripts/start-server.sh --project-dir /path/to/project --idle-timeout-minutes 30
   ```

   - Update the old "auto-exits after 30 minutes" statement to the new default of 4 hours unless overridden.
   - In remote/containerized setup docs, mention that binding `--host 0.0.0.0` still requires opening the key-bearing URL printed by the server.
   - Stop instructions remain:

   ```bash
   scripts/stop-server.sh $SESSION_DIR
   ```

   - Keep the `.s-kit/brainstorm/` persistence guidance.

5. Do not update unrelated docs:
   - No README/catalog changes are required unless verification proves a skill asset surface references stale companion startup behavior.
   - Do not edit docs for Kimi, Antigravity, or unrelated Superpowers features.

### Code Snippets

Root script:

```json
"test:brainstorm-server": "npm --prefix tests/brainstorm-server test"
```

Nested script:

```json
"test": "node ws-protocol.test.js && node helper.test.js && node browser-launcher.test.js && node auth.test.js && node server.test.js && node lifecycle.test.js && bash start-server.test.sh && bash stop-server.test.sh"
```

### Environment Variables

None.

## Verification Plan

### RED

- Command: `npm run test:brainstorm-server`
- Expected: fails before this task because the root script is not defined.

### GREEN

- Command: `npm run test:brainstorm-server`
- Expected: runs the nested brainstorm-server suite and exits 0.

### Final Verification

- Command: `npm run verify:naming`
- Expected: exits 0.

- Command: `npm run verify:assets`
- Expected: exits 0.

- Command: `npm run verify:agents`
- Expected: exits 0.

- Command: `npm run verify:workflow`
- Expected: exits 0.

- Command: `npm run verify:hooks`
- Expected: exits 0.

- Command: `npm test`
- Expected: run after targeted checks if practical. If it still fails only at known `verify:branding` generated `graphify-out` mismatch, record that as an unrelated blocker in `implementation-log.md` rather than expanding this feature.

## Acceptance Criteria

- [ ] Root `package.json` includes `test:brainstorm-server`.
- [ ] Root `npm test` is not broadened to include brainstorm-server tests in this slice.
- [ ] Nested brainstorm-server `npm test` runs the expanded targeted suite.
- [ ] Visual companion docs show key-bearing URLs and treat them as sensitive.
- [ ] Visual companion docs document `--open`.
- [ ] Visual companion docs document `--idle-timeout-minutes`.
- [ ] Visual companion docs mention the 4-hour default idle timeout.
- [ ] Remote bind docs still use `--host` and `--url-host` but clarify the key-bearing URL requirement.

## Notes

After implementation, run `graphify update .` before final completion because the repo instructions require graph refresh after code changes.
