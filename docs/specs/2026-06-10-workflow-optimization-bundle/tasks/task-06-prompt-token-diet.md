# Task 06: Prompt Token Diet for Build-Feature Templates

## Status

pending

## Wave

2

## Description

Restructure the build-feature prompt templates to stop over-injecting context. Today every coder receives full `requirements.md` + `design.md` + the Wave Risk Preflight; the simplifier also receives the preflight; reviewers receive full task-file content inside `{task_summaries}`. After this task: coders get a `{design_digest}` (10–20 line orchestrator-written digest) instead of the full documents and no preflight; the simplifier loses the preflight; reviewers keep full design/requirements but get task excerpts (acceptance criteria + verification plan) instead of full task files; completed-task summaries are explicitly one line per task everywhere. `scripts/verify-workflow.ps1`'s template invariants are updated in the same task so `npm test` stays green.

## Dependencies

**Depends on:** task-05-read-only-contract-dedupe.md
**Blocks:** task-07-build-feature-orchestration-rework.md

**Context from dependencies:** task-05 already replaced the inline read-only contract in `review-prompt-template.md` with a `{read_only_contract}` placeholder and rewrote the contract-related checks in `verify-workflow.ps1` (shared file `references/read-only-review-contract.md` + reference checks). Build on that state — do not reintroduce inline contract text, and extend (don't rewrite) the script's template check blocks.

## Files to Create

None.

## Files to Modify

- `skills/build-feature/references/coder-prompt-template.md` — design digest replaces full docs; preflight removed.
- `skills/build-feature/references/simplifier-prompt-template.md` — preflight removed; no-op verification tightened.
- `skills/build-feature/references/review-prompt-template.md` — `{task_summaries}` slimmed to excerpts.
- `scripts/verify-workflow.ps1` — template invariants updated to the new shape.

## Technical Details

### Implementation Steps

1. **Coder template** (`coder-prompt-template.md`):
   - Remove the `## Feature Context` / `{requirements}`, `## Approved Design` / `{design}`, and `## Wave Risk Preflight` / `{wave_risk_preflight}` sections from the template body.
   - Add in their place:

     ```text
     ## Design Digest

     {design_digest}
     ```

   - Instruction list: replace "Account for the Wave Risk Preflight contracts while staying within this task's scope" with "Account for the contracts and conventions in the Design Digest while staying within this task's scope". Keep all other instructions (verification commands, no commit, report format, one-paragraph summary) unchanged.
   - Placeholder Details: remove the `{requirements}`, `{design}`, and `{wave_risk_preflight}` entries; add:

     ```markdown
     - **{design_digest}**: a 10-20 line digest the orchestrator writes per wave from the approved design and requirements. It must cover: the design decisions and shared contracts relevant to this wave's tasks (public exports, types, schemas, naming, error-handling conventions), and quote any Wave Risk Preflight line that directly affects this task. It is not the full design - reviewers hold the full design and will catch deviations.
     ```

   - Keep `{spec_manifest}`, `{completed_tasks_summary}` (its 1–2 line example format already exists — tighten the wording to "one line per task"), and `{task_content}`.

2. **Simplifier template** (`simplifier-prompt-template.md`):
   - Remove the `## Wave Risk Preflight` / `{wave_risk_preflight}` section and its Placeholder Details entry.
   - Instruction 3 "Preserve contracts called out in the Wave Risk Preflight." becomes "Preserve contracts called out in the approved design and task summaries."
   - Instruction 8 tightens to: "Run the listed verification commands after edits. If you return `no-op`, you must still run each task's Final Verification command and report its output - a `no-op` without verification evidence is not acceptable."
   - Keep `{requirements}` and `{design}` (the design decision keeps full docs for the simplifier), `{task_summaries}`, `{changed_files}`, `{verification_commands}`, and the `no-op` status option.
   - In the `{task_summaries}` placeholder details, change "task file content" to "task file content for this wave's tasks" (current-wave content is needed to judge intended behavior) and state that completed-task context from earlier waves is one line per task.

3. **Review template** (`review-prompt-template.md`):
   - In Placeholder Details, rewrite `{task_summaries}` to: "for each task in the wave, include the task title, manifest entry, the task file's Acceptance Criteria and Verification Plan sections (not the full task file), files created/modified, verification evidence, coder or fixer completion summary, and simplifier summary and verification evidence. Completed tasks from earlier waves: one line each."
   - Keep `{requirements}` and `{design}` as full text (reviewers judge design conformance), keep `{wave_risk_preflight}` (reviewers are the preflight's primary audience), keep `{read_only_contract}` from task-05, keep `{review_scope}` and the verdict format.
   - The literal string `simplifier summary and verification evidence` must remain somewhere in the template — `verify-workflow.ps1` requires it.

4. **`scripts/verify-workflow.ps1`** — update the template invariant blocks:
   - Coder template block (currently requires `'## Wave Risk Preflight'`, `'{wave_risk_preflight}'`, `'Account for the Wave Risk Preflight contracts'`): require instead `'## Design Digest'`, `'{design_digest}'`, and `'Account for the contracts and conventions in the Design Digest'`; add negative checks that the coder template does NOT contain `'{wave_risk_preflight}'`, `'{requirements}'`, or `'{design}'` (use `.Contains(...)` with a failure when found; note `'{design}'` must not false-positive on `'{design_digest}'` — check for `'{design}'` as an exact placeholder token, e.g. regex `\{design\}`).
   - Simplifier template block: drop the `'## Wave Risk Preflight'` / `'{wave_risk_preflight}'` requirements; keep the no-op requirement and add `'you must still run each task''s Final Verification command'` (mind PowerShell single-quote escaping); add a negative check that `'{wave_risk_preflight}'` is absent.
   - Review template block: keep `'{wave_risk_preflight}'` and `'simplifier summary and verification evidence'` requirements; add `'Acceptance Criteria and Verification Plan sections'`.
   - Fix template block: unchanged (fix prompts keep the preflight).
   - Build-feature SKILL.md block: unchanged in this task (task-07 owns SKILL.md and will reconcile).

5. Run `npm run verify:workflow` after all four files are edited — it must pass in the final state of this task. (Note: the SKILL.md still describes the old placeholder flow until task-07; that is acceptable because the script's SKILL.md checks don't reference the removed coder/simplifier placeholders.)

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Select-String -Path 'skills/build-feature/references/coder-prompt-template.md' -Pattern '\{design_digest\}' -Quiet"`
- Expected: `False` before implementation.

### GREEN

- Command: `npm run verify:workflow`
- Expected: passes with the new invariants (digest required in coder template, preflight forbidden in coder/simplifier templates, excerpt wording required in review template).
- Spot check: `powershell -NoProfile -Command "-not (Select-String -Path 'skills/build-feature/references/coder-prompt-template.md','skills/build-feature/references/simplifier-prompt-template.md' -Pattern '\{wave_risk_preflight\}' -Quiet)"` outputs `True`.

### Final Verification

- Command: `npm test`
- Expected: full chain passes.

## Acceptance Criteria

- [ ] Coder template: `{design_digest}` present with a placeholder spec (10–20 lines, contracts/naming/error-handling, quotes relevant preflight lines); `{requirements}`, `{design}`, `{wave_risk_preflight}` absent.
- [ ] Simplifier template: preflight absent; `no-op` explicitly requires Final Verification evidence; full design/requirements retained.
- [ ] Review template: task summaries are excerpts (Acceptance Criteria + Verification Plan), full design/requirements and preflight retained, `simplifier summary and verification evidence` string retained.
- [ ] Completed-task summaries documented as one line per task in all three templates.
- [ ] `verify-workflow.ps1` enforces the new shape including negative checks, and `npm test` passes.

## Notes

The quality backstop for removing full docs from coder prompts is twofold: task files are self-contained by plan-feature's core invariant, and reviewers still hold the full design — a coder deviation surfaces at the existing spec-compliance gate. Do not weaken any review-template content beyond the task-summary slimming described here.
