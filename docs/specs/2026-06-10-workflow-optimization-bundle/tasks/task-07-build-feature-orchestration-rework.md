# Task 07: Build-Feature Orchestration Rework

## Status

complete

## Wave

3

## Description

Bring `skills/build-feature/SKILL.md` in line with the dieted templates and add the remaining design items that live in the orchestration text: the per-wave design digest, the narrowed preflight audience, one-line completed-task summaries, a baseline verification before Wave 1, the security-auditor trigger for risky surfaces, explicit simplifier `no-op` semantics, a slimmed final integration review, and the task-reopen cascade procedure. Update `scripts/verify-workflow.ps1`'s SKILL.md invariants where the reworked text changes a required string.

## Dependencies

**Depends on:** task-06-prompt-token-diet.md
**Blocks:** None

**Context from dependencies:** task-06 already reshaped the templates: the coder template now has `## Design Digest` / `{design_digest}` and no `{requirements}`/`{design}`/`{wave_risk_preflight}`; the simplifier template has no preflight and requires Final Verification evidence on `no-op`; the review template takes task excerpts; `verify-workflow.ps1` enforces that shape with positive and negative checks. task-05 (wave 1) extracted the read-only contract to `skills/build-feature/references/read-only-review-contract.md` with a `{read_only_contract}` placeholder in the review template. This task makes the SKILL.md orchestration instructions match.

## Files to Create

None.

## Files to Modify

- `skills/build-feature/SKILL.md` — all orchestration changes below.
- `scripts/verify-workflow.ps1` — reconcile SKILL.md required-text invariants with the reworked wording.

## Technical Details

### Implementation Steps

Read both files fully first. Then apply these changes to `skills/build-feature/SKILL.md`:

1. **Step 1 (Load the Spec) — baseline verification.** After the spec preflight (current item 4) and before parsing tasks, add:

   ```markdown
   5. Run a baseline verification before dispatching any wave: execute the project-level verification commands referenced by the spec (the project-level entries in `spec.json.tasks[].verificationCommands`, or the repository's standard test command). If the baseline fails, report the failing commands and ask the user whether to proceed (failures will be attributed to the pre-existing baseline in `implementation-log.md`) or stop. Record the baseline result in `implementation-log.md` either way.
   ```

   Renumber the following items.

2. **Step 3A (Wave Risk Preflight) — narrowed audience + risky-surface flag.**
   - Change item 5 from "Pass the same Wave Risk Preflight text into coder, simplifier, spec-compliance review, and code-quality review prompts." to "Pass the same Wave Risk Preflight text into spec-compliance review, code-quality review, and fix prompts. Coder and simplifier prompts do not receive the preflight; instead, quote any preflight line that directly affects a task inside that wave's Design Digest."
   - Add a new item: "Flag the wave as security-sensitive when its owned files touch secrets or credentials, shell command construction, package installs, filesystem writes or deletes, auth or permissions, network calls, or user-controlled input. Record the flag in the preflight summary."

3. **Step 4 (Dispatch Coder Agents) — digest placeholder.** Replace the placeholder list entries for `{requirements}` and `{design}` with:

   ```markdown
   - **{design_digest}**: a 10-20 line digest of the approved design and requirements scoped to this wave: shared contracts (public exports, types, schemas), naming and error-handling conventions, and any Wave Risk Preflight lines that directly affect the task. Reviewers hold the full design; the digest is working context, not the contract of record.
   ```

   Remove `{wave_risk_preflight}` from the coder placeholder list. Keep `{spec_manifest}`, `{completed_tasks_summary}` ("one line per completed task"), and `{task_content}`.

4. **Step 5A (Simplification Pass) — no-op semantics + no preflight.**
   - Remove `{wave_risk_preflight}` from the simplifier placeholder list; adjust item 3's "respect the Wave Risk Preflight contracts" to "respect the contracts in the approved design and task summaries".
   - Add: "A `no-op` result must include Final Verification command output for each task in scope. A `no-op` without verification evidence sets the affected tasks to `done-with-concerns` instead of allowing `complete`."

5. **Step 6B (Code Quality Review) — security auditor.** Add after the dispatch instruction:

   ```markdown
   If the wave was flagged security-sensitive in the Wave Risk Preflight, also dispatch the `s-kit-security-auditor` agent (read-only) in parallel with the code-quality review, scoped to the same concrete review scope. Treat a `CHANGES REQUESTED` audit verdict exactly like a code-quality review **FAIL**: set affected tasks to `review-failed`, append the findings to `implementation-log.md`, and go to Step 7.
   ```

6. **Step 9 (Final Integration Review) — slimmed.** Replace the current items 2–3 with:

   ```markdown
   2. Build the full feature scope as a git range or exact file set from the accepted task diffs.
   3. Dispatch one code-quality review agent for that scope. Do not dispatch a full-feature spec-compliance review: the per-wave spec-compliance verdicts recorded in `implementation-log.md` are the compliance record. Do not re-inject all task summaries; the review receives the scope, the design, the requirements, and the verification commands.
   ```

   Update the final status report block accordingly (replace the "Full spec compliance review" line with "Per-wave spec compliance verdicts: {all PASS / list exceptions}").

7. **Error Handling — task-reopen cascade.** Add a bullet:

   ```markdown
   - **Reopened completed task**: if a `complete` task is reopened (set back to `in-progress`, `needs-context`, or `review-failed`), revert every transitive dependent task to `blocked`, update `spec.json`, task files, and README checkboxes consistently, and append a dated entry to `implementation-log.md` stating the reason before any re-dispatch.
   ```

8. **Key Principles** — adjust "Completed task summaries are brief. One paragraph per task…" to "one line per task". Add: "Coders build from self-contained task files plus a design digest; reviewers hold the full design. Review is the contract of record."

9. **`scripts/verify-workflow.ps1` SKILL.md block** — reconcile required strings:
   - `'coder or fixer completion summary, simplifier summary, and simplifier verification evidence'` — keep the SKILL.md sentence containing it intact if possible; if Step 5A rewording changes it, update the required string to the new exact sentence.
   - All other existing required strings (`'### Step 3A: Wave Risk Preflight'`, `'{wave_risk_preflight}'`, punch-list strings, read-only scope strings) must still match — preserve those exact phrases in the rework; `'{wave_risk_preflight}'` still appears in SKILL.md (Steps 3A/6A/6B/7 review and fix contexts).
   - Add new required strings: `'{design_digest}'`, `'baseline verification'`, `'s-kit-security-auditor'`, `'Reopened completed task'`, `'A `no-op` result must include Final Verification command output'` (adjust quoting for PowerShell).

10. Run `npm run verify:workflow` and iterate until green; the script and SKILL.md must agree in this task's final state.

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Select-String -Path 'skills/build-feature/SKILL.md' -Pattern 's-kit-security-auditor' -Quiet"`
- Expected: `False` before implementation — the auditor is not referenced by the skill.

### GREEN

- Command: `npm run verify:workflow`
- Expected: passes with the new SKILL.md invariants (design digest, baseline verification, security auditor, reopen cascade, no-op evidence).
- Spot check: `powershell -NoProfile -Command "(Select-String -Path 'skills/build-feature/SKILL.md' -Pattern '\{design_digest\}' -Quiet) -and (Select-String -Path 'skills/build-feature/SKILL.md' -Pattern 'baseline verification' -Quiet) -and (Select-String -Path 'skills/build-feature/SKILL.md' -Pattern 'Reopened completed task' -Quiet)"` outputs `True`.

### Final Verification

- Command: `npm test`
- Expected: full chain passes.

## Acceptance Criteria

- [ ] Step 1 runs a baseline verification before Wave 1 with a proceed/stop user decision on failure, logged either way.
- [ ] The preflight audience is reviewers + fixers; coder/simplifier dispatch instructions reference the design digest instead.
- [ ] Step 4's placeholder list matches the task-06 coder template exactly (`{design_digest}`, no `{requirements}`/`{design}`/`{wave_risk_preflight}`).
- [ ] Security-sensitive waves dispatch `s-kit-security-auditor` alongside code-quality review, with `CHANGES REQUESTED` treated as FAIL.
- [ ] `no-op` without Final Verification evidence yields `done-with-concerns`.
- [ ] Step 9 is project verification + one diff-scoped code-quality review; per-wave spec-compliance verdicts are the compliance record.
- [ ] The task-reopen cascade is documented in Error Handling.
- [ ] The two-stage per-wave review (6A before 6B) is unchanged.
- [ ] `verify-workflow.ps1` and SKILL.md agree; `npm test` passes.

## Notes

This task deliberately runs alone in Wave 3: it owns both `skills/build-feature/SKILL.md` and `scripts/verify-workflow.ps1`, and the script's literal-string invariants make cross-task coordination on these files fragile. Preserve every existing required string listed in the script unless this task explicitly updates both sides.
