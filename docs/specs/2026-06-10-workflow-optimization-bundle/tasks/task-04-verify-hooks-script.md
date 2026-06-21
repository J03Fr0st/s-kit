# Task 04: Hooks and Packaging Sync Verification Script

## Status

complete

## Phase

1

## Description

Create `scripts/verify-hooks.ps1` and wire it into `npm test`. s-kit ships two hook registration files — `hooks/hooks.json` (Claude Code/Codex/OpenCode format) and `hooks/hooks-cursor.json` (Cursor format) — with no check that they stay in sync, and six packaging surfaces whose version fields can drift. The new script verifies both hooks files reference the same underlying hook scripts, that every referenced script exists, and that the declared version fields match (reusing the `.version-bump.json` declaration that `scripts/doctor.ps1` already uses).

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** None

**Context from dependencies:** None. Reference facts you need:

- `hooks/hooks.json` shape: `{ "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact", "hooks": [ { "type": "command", "command": "\"${PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start", "async": false } ] } ] } }` — four matcher entries, all invoking `run-hook.cmd session-start`.
- `hooks/hooks-cursor.json` shape: `{ "version": 1, "hooks": { "sessionStart": [ { "command": "./hooks/run-hook.cmd session-start" } ] } }` — camelCase event name, single entry, relative path, no matchers (Cursor has no matcher concept; this is a documented platform difference, not drift).
- `.version-bump.json` declares the files and JSON fields that hold the version; `scripts/doctor.ps1` (lines ~129–155) already reads it and fails on drift. Reuse the same declaration format; do not invent a second source of truth.
- Existing verify scripts (`scripts/verify-workflow.ps1` etc.) use the pattern: `$ErrorActionPreference = 'Stop'`, a `$failures` list, `Add-Failure`, and exit non-zero with all messages printed at the end. Follow that pattern.

## Files to Create

- `scripts/verify-hooks.ps1` — the sync/version verification script.

## Files to Modify

- `package.json` — add `"verify:hooks"` script entry and append it to the `"test"` chain.

## Technical Details

### Implementation Steps

1. Read `scripts/verify-workflow.ps1` (top ~50 lines) and `scripts/doctor.ps1` first to copy the established failure-collection pattern and the `.version-bump.json` reading approach.

2. `scripts/verify-hooks.ps1` checks, in order:
   - `hooks/hooks.json` and `hooks/hooks-cursor.json` both exist and parse as JSON (`Get-Content -Raw | ConvertFrom-Json` in a try/catch; parse failure → `Add-Failure`).
   - Extract the set of hook invocations from each file. For `hooks.json`: every `hooks.<Event>[].hooks[].command`. For `hooks-cursor.json`: every `hooks.<event>[].command`. Normalize each command to its hook-script identity: strip quotes, strip `${PLUGIN_ROOT}/` and leading `./`, collapse to e.g. `hooks/run-hook.cmd session-start`.
   - Assert the normalized invocation sets are equal. A hook registered on one surface but not the other is a failure (message names the missing side). Matcher differences and event-name casing (`SessionStart` vs `sessionStart`) are documented platform differences — compare case-insensitively on the event name and ignore matchers. Put a comment block at the top of the script documenting these allowed differences.
   - Every referenced hook script file (e.g., `hooks/run-hook.cmd`, and the argument target `hooks/session-start`) exists on disk.
   - Version consistency: read `.version-bump.json`, and for each declared file/field, read the version value (same logic as doctor.ps1); fail if the unique-version count exceeds 1 or a declared field is missing. Keep this section short — it intentionally duplicates doctor's check so `npm test` (which does not run doctor) catches drift.
   - Print `verify-hooks: OK` and exit 0 when the failure list is empty; otherwise print each failure and exit 1.

3. `package.json` changes:
   - Add: `"verify:hooks": "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-hooks.ps1"`.
   - Append `&& npm run verify:hooks` to the existing `"test"` script chain (after `verify:workflow`).

### Code Snippets

Normalization sketch:

```powershell
function Get-NormalizedHookCommand {
  param([string] $Command)
  $value = $Command.Trim().Trim('"')
  $value = $value -replace '^\$\{PLUGIN_ROOT\}/', ''
  $value = $value -replace '^"?\$\{PLUGIN_ROOT\}/', ''
  $value = $value -replace '^\./', ''
  $value = $value -replace '"', ''
  return $value.Trim()
}
```

## Verification Plan

### RED

- Command: `npm run verify:hooks`
- Expected: fails before implementation — `scripts/verify-hooks.ps1` does not exist and the npm script is not defined ("Missing script" error).

### GREEN

- Command: `npm run verify:hooks`
- Expected: prints `verify-hooks: OK`, exit code 0 against the current repo state.
- Negative check: temporarily add a bogus entry to a *copy* of `hooks-cursor.json` outside the repo and point the script at it, or temporarily edit and revert — confirm the script fails with a named missing-side message. (Do not leave any temporary edit in place.)

### Final Verification

- Command: `npm test`
- Expected: full chain passes including the new `verify:hooks` step.

## Acceptance Criteria

- [ ] `scripts/verify-hooks.ps1` exists, follows the repo's Add-Failure pattern, and exits non-zero on any failure.
- [ ] Hook invocation sets are compared after normalization; a hook present in one file but not the other fails with a clear message.
- [ ] Allowed platform differences (matchers, event-name casing, path prefix style) are documented in a comment and not flagged.
- [ ] Referenced hook script files are checked for existence.
- [ ] Version consistency across `.version-bump.json`-declared files is asserted.
- [ ] `package.json` has `verify:hooks` and the `test` chain runs it.
- [ ] `npm test` passes.

## Notes

The version check intentionally overlaps `scripts/doctor.ps1`: doctor is on-demand, `npm test` is the gate. Reuse `.version-bump.json` as the single declaration of which files carry versions so the two checks can never disagree about scope.
