# Task 02: Plan-Feature Hardening

## Status

complete

## Phase

1

## Description

Harden `plan-feature` with three additions: a hard existence check on the design file before any spec file is written (today a wrong path fails silently and `build-feature`'s preflight only catches it later), an annotation that two of the seven task statuses are execution-only, and an optional offer to dispatch the `s-kit-pattern-mapper` agent before task decomposition so task files carry real repo-convention evidence. The pattern-mapper agent is shipped but never invoked by any skill today.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** None

**Context from dependencies:** None. This task edits one skill file. The `s-kit-pattern-mapper` agent already exists at `agents/s-kit-pattern-mapper.md` (read-only; returns Recommended Pattern / Supporting Patterns / Implementation Guidance / Watchouts with file:line evidence) — this task only adds invocation guidance.

## Files to Create

None.

## Files to Modify

- `skills/plan-feature/SKILL.md` — design-existence hard check in Step 1, status annotation in Step 5, pattern-mapper offer between Steps 2 and 3.

## Technical Details

### Implementation Steps

1. Read `skills/plan-feature/SKILL.md` fully first.

2. **Step 1 (Verify Approved Design):** after the existing numbered list, add a hard-stop rule:

   ```markdown
   Before writing any spec file, verify the design file exists at the derived path (`docs/design/YYYY-MM-DD-{feature-name}/design.md`). If it does not, report the exact expected path and stop. Do not create the spec folder, and do not guess an alternative location.
   ```

3. **Between Step 2 and Step 3** (after deriving the spec folder, before decomposing into tasks), add an optional preparation note:

   ```markdown
   ### Optional: Map Existing Patterns First

   Before decomposing into tasks, offer to dispatch the `s-kit-pattern-mapper` agent with the approved design as input. Its report (recommended patterns with file:line evidence, implementation guidance, watchouts) feeds directly into each task file's Technical Details so coder agents follow the repo's real conventions instead of inventing a style. Skip this for repos the conversation already knows well.
   ```

   Number/renumber nothing — add it as an unnumbered subsection so existing step references ("Step 3", "Step 5" etc.) elsewhere in the file and in other skills stay valid.

4. **Step 5 (status list):** immediately after the existing 7-item status list, add:

   ```markdown
   `done-with-concerns` and `review-failed` are execution-only statuses assigned by `build-feature` during implementation and review. `plan-feature` always creates tasks as `pending`; the full list stays in `spec.json.allowedTaskStatuses` because `build-feature`'s preflight requires exactly these seven values.
   ```

5. Do not change the `allowedTaskStatuses` list itself, the templates under `skills/plan-feature/references/`, or any path conventions. `scripts/verify-workflow.ps1` validates spec folders against the exact 7-status array; the annotation is documentation only.

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "if (Select-String -Path 'skills/plan-feature/SKILL.md' -Pattern 's-kit-pattern-mapper' -Quiet) { exit 1 } else { exit 0 }"`
- Expected: exits 0 before implementation — no pattern-mapper reference exists in the skill yet.

### GREEN

- Command: `powershell -NoProfile -Command "(Select-String -Path 'skills/plan-feature/SKILL.md' -Pattern 's-kit-pattern-mapper' -Quiet) -and (Select-String -Path 'skills/plan-feature/SKILL.md' -Pattern 'report the exact expected path and stop' -Quiet) -and (Select-String -Path 'skills/plan-feature/SKILL.md' -Pattern 'execution-only statuses' -Quiet)"`
- Expected: outputs `True` — all three additions present.

### Final Verification

- Command: `npm test`
- Expected: all verification gates pass.

## Acceptance Criteria

- [ ] `plan-feature` Step 1 hard-stops with the expected path when the design file is missing, before any spec file is written.
- [ ] The pattern-mapper offer exists as an optional, unnumbered subsection between spec-folder derivation and task decomposition.
- [ ] The status annotation marks `done-with-concerns` and `review-failed` as execution-only while keeping all 7 values in `allowedTaskStatuses`.
- [ ] No templates under `references/` and no existing numbered steps were changed.
- [ ] `npm test` passes.

## Notes

The 7-value status list must remain untouched: `build-feature`'s spec preflight checks `spec.json.allowedTaskStatuses` contains exactly those values, and `verify-workflow.ps1` enforces the same array on every spec folder in the repo.
