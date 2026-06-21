# Task 05: Codex Native Hook Compatibility

## Status

complete

## Phase

3

## Description

Investigate and, if supported, add Codex native hook support through `s-kit`'s declared plugin surfaces. Superpowers `dev` added `hooks/hooks-codex.json` and `hooks/session-start-codex`, but `s-kit` should verify current Codex app/plugin compatibility before copying shapes. If support cannot be confirmed, document the deferral instead of adding dead files.

## Dependencies

**Depends on:** task-02-harness-porting-playbook.md, task-03-eval-harness-strategy.md
**Blocks:** None

**Context from dependencies:** Task 02 defines the harness-porting rules, especially no manual user config edits and use of declared install mechanisms. Task 03 defines test deletion and eval constraints so hook tests do not accidentally replace behavior coverage without a map.

## Files to Create

- `tests/codex-plugin-sync/test-codex-hooks.sh` — Codex plugin hook packaging/path test.

## Files to Modify

- `.codex-plugin/plugin.json` — declare Codex hook support if supported by the plugin schema.
- `hooks/hooks.json` — use the Codex plugin `PLUGIN_ROOT` environment variable for the declared hook command.
- `scripts/doctor.ps1` — check hook files and manifest paths.

## Technical Details

### Implementation Steps

1. Verify current Codex plugin hook support from local installed plugin behavior or current official docs. Because Codex app details can change, do not rely solely on Superpowers `dev`.
2. Use the documented Codex plugin hook surface:
   - declare `hooks` as `./hooks/hooks.json` in `.codex-plugin/plugin.json`
   - reuse the existing `hooks/hooks.json` `SessionStart` hook and `hooks/session-start` script with the documented `PLUGIN_ROOT` command root
   - do not add unsupported `hooks/hooks-codex.json` or `hooks/session-start-codex` files
   - add a test under `tests/codex-plugin-sync/` proving the manifest, hook file, and session-start output are valid
   - extend `scripts/doctor.ps1` to validate the hook surface
3. Avoid any approach requiring manual edits to user config.

### Code Snippets

If hooks are supported, the manifest shape should be based on verified Codex plugin schema, not guessed. A placeholder example is intentionally omitted to prevent cargo-culting an unsupported schema.

### Environment Variables

None expected. If a hook needs environment variables, document them in the hook file and `action-required.md` before implementation proceeds.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `node -e "const p=require('./.codex-plugin/plugin.json'); if (p.hooks !== './hooks/hooks.json') process.exit(1)"`
- Expected: Before implementation, this fails because the Codex plugin manifest does not declare the documented hook surface.

### GREEN

- Command: `npm run doctor`
- Expected: Doctor passes and validates either implemented Codex hooks or the documented current non-support/deferral state.

### Final Verification

- Command: `npm test`
- Expected: All package, asset, agent, naming, and workflow verification gates pass.

## Acceptance Criteria

- [x] Current Codex hook support is verified before implementation.
- [x] Hook files are declared through `.codex-plugin/plugin.json` and covered by doctor/tests.
- [x] Unsupported Codex-specific hook filenames are not added.
- [x] No manual user config edit is required.
- [x] `npm run doctor` and `npm test` pass.

## Notes

This task intentionally runs after the playbook and eval strategy. It should follow the new porting rules and should not change test architecture while adding hook support.
