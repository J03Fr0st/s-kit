# Task 03: Session-Start Hook Slimming

## Status

complete

## Wave

1

## Description

The `hooks/session-start` bash script currently reads the entire `skills/using-s-kit/SKILL.md` (~130 lines) and injects it as `additionalContext` on every SessionStart event — and `hooks.json` registers that hook for all four matchers (startup, resume, clear, compact). That re-injects a large static block many times per working day. Replace the full-skill injection with a short pointer that tells the agent s-kit is active and to load `using-s-kit` via the Skill tool. The conditional legacy-path warning stays exactly as it is.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** None

**Context from dependencies:** None. This task edits one bash script. The platform-detection logic at the bottom of the script (Cursor `additional_context` / Claude Code `hookSpecificOutput.additionalContext` / Copilot-and-others `additionalContext`) must not change — it encodes hard-won host quirks, including a documented bash 5.3+ heredoc hang workaround using `printf`.

## Files to Create

None.

## Files to Modify

- `hooks/session-start` — replace full SKILL.md injection with a short pointer message.

## Technical Details

### Implementation Steps

1. Read `hooks/session-start` fully first (it is ~57 lines).

2. Remove the block that reads the skill file:

   ```bash
   # Read using-s-kit content
   using_s_kit_content=$(cat "${PLUGIN_ROOT}/skills/using-s-kit/SKILL.md" 2>&1 || echo "Error reading using-s-kit skill")
   ```

   and the corresponding `using_s_kit_escaped=$(escape_for_json "$using_s_kit_content")` line. The `PLUGIN_ROOT` derivation can stay (harmless) or be removed if nothing else uses it — check before removing.

3. Replace the `session_context` assignment with a short pointer (3 lines of content). New value:

   ```bash
   session_context="<EXTREMELY_IMPORTANT>\nYou have s-kit. Before responding to any task, load the 's-kit:using-s-kit' skill with the Skill tool and follow it - it routes work to the right s-kit skill and lane.\nCanonical workflow: brainstorming -> plan-feature -> build-feature. Small changes use the lanes documented in using-s-kit.\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
   ```

   Keep `\n` escapes literal (the string is embedded into JSON via `printf`, exactly as the current code does). Keep the `escape_for_json` function — it is still used for `warning_escaped`.

4. Leave untouched:
   - The legacy-skills warning block (`~/.config/s-kit/skills` detection and `warning_message`).
   - The `escape_for_json` function.
   - The entire platform-detection / output section (`CURSOR_PLUGIN_ROOT` / `CLAUDE_PLUGIN_ROOT` / `COPILOT_CLI` branches with `printf`).
   - `hooks.json` and `hooks-cursor.json` (all four matchers stay registered — the hook is now cheap).

5. Preserve `set -euo pipefail` and the shebang.

## Verification Plan

### RED

- Command: `bash -c "grep -c 'skills/using-s-kit/SKILL.md' hooks/session-start"`
- Expected: outputs `1` before implementation — the full-skill read is present.

### GREEN

- Command: `bash -n hooks/session-start && bash -c "! grep -q 'cat .*using-s-kit/SKILL.md' hooks/session-start && grep -q 'Skill tool' hooks/session-start && grep -q 'warning_escaped' hooks/session-start && echo OK"`
- Expected: outputs `OK` — script parses, no longer cats the skill file, contains the pointer text, and still wires the legacy warning.
- Additional check: `bash -c "CLAUDE_PLUGIN_ROOT=/tmp bash hooks/session-start"` produces valid JSON with `hookSpecificOutput.additionalContext` (pipe through `python -m json.tool` or `node -e "JSON.parse(require('fs').readFileSync(0,'utf8'))"` to confirm it parses).

### Final Verification

- Command: `npm test`
- Expected: all verification gates pass.

## Acceptance Criteria

- [ ] `hooks/session-start` no longer reads or embeds `skills/using-s-kit/SKILL.md`.
- [ ] The injected context is a short pointer (load using-s-kit via the Skill tool; canonical workflow line; lanes mention) inside the existing `<EXTREMELY_IMPORTANT>` wrapper.
- [ ] The legacy-path warning behavior is unchanged (only emitted when `~/.config/s-kit/skills` exists).
- [ ] All three platform output branches emit valid JSON (verified for at least the Claude Code branch).
- [ ] `bash -n hooks/session-start` passes and `npm test` passes.

## Notes

Do not switch the `printf` output to a heredoc — the comment in the script documents a bash 5.3+ heredoc hang that the `printf` form works around. The pointer text mentions lanes, which task-01 adds to using-s-kit; the two tasks are independent because the pointer only references the skill, it does not quote it.
