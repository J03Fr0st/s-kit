# Task 05: Read-Only Review Contract Dedupe

## Status

complete

## Phase

1

## Description

The read-only review contract ("You are reviewing only. Do not modify files, the index, HEAD, branch state…") is duplicated verbatim in three places: `agents/s-kit-code-reviewer.md`, `agents/s-kit-spec-reviewer.md`, and `skills/build-feature/references/review-prompt-template.md`, and `scripts/verify-workflow.ps1` enforces the triplication by checking the literal text in each location. Extract the contract to one shared reference file, make the three consumers reference it (the prompt template via a placeholder the orchestrator fills with the shared file's content; the agent files via a pointer plus a one-sentence summary), and update the verification script to check the shared file plus the references instead of triplicated text.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-06-prompt-token-diet.md

**Context from dependencies:** None. Reference facts you need:

- The exact current contract text (identical in all three files):
  > You are reviewing only. Do not modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts. If you need to inspect another revision, use read-only git commands or a separate temporary worktree. Your output must state the git range, task diff, or file set reviewed.
- `scripts/verify-workflow.ps1` holds `$readOnlyReviewContractText` (lines ~12–17), an array of four literal strings, and checks it against the review prompt template (lines ~165–182) and both reviewer agent files (lines ~232–249). The build-feature SKILL.md check (lines ~138–160) also includes two contract-derived strings ('Do not ask them to modify files…' and 'read-only git commands or a separate temporary worktree') — leave the SKILL.md checks alone; this task does not touch `skills/build-feature/SKILL.md`.

## Files to Create

- `skills/build-feature/references/read-only-review-contract.md` — the single source of the contract text.

## Files to Modify

- `agents/s-kit-code-reviewer.md` — replace inline contract with summary + pointer.
- `agents/s-kit-spec-reviewer.md` — replace inline contract with summary + pointer.
- `skills/build-feature/references/review-prompt-template.md` — replace inline contract with a `{read_only_contract}` placeholder.
- `scripts/verify-workflow.ps1` — check the shared file's content and the consumers' references.

## Technical Details

### Implementation Steps

1. Create `skills/build-feature/references/read-only-review-contract.md`:

   ```markdown
   # Read-Only Review Contract

   Paste this contract verbatim into every review agent prompt. Reviewer agent definitions reference this file as their single source.

   ## Contract

   You are reviewing only. Do not modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts. If you need to inspect another revision, use read-only git commands or a separate temporary worktree. Your output must state the git range, task diff, or file set reviewed.
   ```

2. In `skills/build-feature/references/review-prompt-template.md`, replace the body under `## Read-Only Review Contract` (the full paragraph) with the placeholder `{read_only_contract}`, keep the section heading, and add to the Placeholder Details list:

   ```markdown
   - **{read_only_contract}**: paste the Contract section of `references/read-only-review-contract.md` verbatim.
   ```

3. In both `agents/s-kit-code-reviewer.md` and `agents/s-kit-spec-reviewer.md`, replace the paragraph under `## Read-Only Review Contract` with:

   ```markdown
   You are reviewing only — never edit files, git state, task statuses, or generated artifacts. Follow the full contract in `skills/build-feature/references/read-only-review-contract.md`; your output must state the git range, task diff, or file set reviewed.
   ```

   Keep the `## Read-Only Review Contract` heading and everything else in both agent files unchanged (Output formats, Rules including "Reviewed Scope:" and the "If the reviewed scope is missing or too vague…" rule).

4. In `scripts/verify-workflow.ps1`:
   - Add `$readOnlyContractPath = Join-Path $root 'skills/build-feature/references/read-only-review-contract.md'`.
   - New check: the shared file exists and contains all four `$readOnlyReviewContractText` strings (reuse the existing array against the new file).
   - Review prompt template check: remove `$readOnlyReviewContractText` from its required-text list; instead require `'{read_only_contract}'` and `'read-only-review-contract.md'`.
   - Reviewer agent checks: replace the `$readOnlyReviewContractText` requirement with `'read-only-review-contract.md'` and `'You are reviewing only'`; keep the existing `'Reviewed Scope:'` and "If the reviewed scope is missing or too vague…" requirements.
   - Do not modify the build-feature SKILL.md required-text block.

5. Order of edits matters for keeping `npm test` green only at task completion — make all five file changes, then run verification.

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Test-Path 'skills/build-feature/references/read-only-review-contract.md'"`
- Expected: `False` before implementation.

### GREEN

- Command: `npm run verify:workflow`
- Expected: passes with the new reference-based checks; fails if any consumer drops its pointer or the shared file loses contract text.
- Spot check: `powershell -NoProfile -Command "(Select-String -Path 'skills/build-feature/references/review-prompt-template.md' -Pattern '\{read_only_contract\}' -Quiet) -and (Select-String -Path 'agents/s-kit-code-reviewer.md','agents/s-kit-spec-reviewer.md' -Pattern 'read-only-review-contract.md' -Quiet)"` outputs `True`.

### Final Verification

- Command: `npm test`
- Expected: full chain passes.

## Acceptance Criteria

- [ ] The contract text exists in exactly one file: `skills/build-feature/references/read-only-review-contract.md`.
- [ ] The review prompt template uses `{read_only_contract}` with a placeholder-details entry telling the orchestrator to paste the shared file's Contract section.
- [ ] Both reviewer agents carry a one-sentence summary plus a pointer to the shared file, with all other content unchanged.
- [ ] `verify-workflow.ps1` validates the shared file's content and each consumer's reference; the triplicated-text checks are gone.
- [ ] The build-feature SKILL.md checks in `verify-workflow.ps1` are untouched.
- [ ] `npm test` passes.

## Notes

The agent files keep a one-sentence behavioral summary (not just a bare link) because hosts dispatch agents from the .md alone — an agent that has not read the shared file still must not edit anything. The orchestrator-side template gets the full text pasted at dispatch time via the placeholder.
