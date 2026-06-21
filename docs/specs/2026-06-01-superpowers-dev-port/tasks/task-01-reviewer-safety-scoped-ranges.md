# Task 01: Reviewer Safety and Scoped Ranges

## Status

complete

## Phase

1

## Description

Harden `s-kit` review agents and `build-feature` review prompts so reviewers are explicitly read-only and scoped to the relevant task diff or git range. Superpowers `dev` added this after reviewers crawled too much history and one reviewer detached HEAD during review. `s-kit` has the same class of risk because `build-feature` dispatches spec-compliance and code-quality review agents.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-04-action-language-cleanup.md

**Context from dependencies:** None. This is the first safety slice and should be implemented before broader prose cleanup touches shared workflow text.

## Files to Create

None.

## Files to Modify

- `skills/build-feature/SKILL.md` — ensure review dispatch requires a concrete reviewed range/diff and read-only behavior.
- `skills/build-feature/references/review-prompt-template.md` — add the read-only review contract and reviewed-range reporting requirement.
- `agents/s-kit-spec-reviewer.md` — make the agent read-only and require it to report the reviewed range.
- `agents/s-kit-code-reviewer.md` — make the agent read-only and require it to report the reviewed range.
- `scripts/verify-workflow.ps1` — add regression checks for the new safety wording.

## Technical Details

### Implementation Steps

1. Inspect the current `build-feature` review flow and the two reviewer agents before editing.
2. Add a read-only review rule with this meaning: reviewers must not mutate the working tree, index, HEAD, branch state, staged files, or task status files.
3. Permit historical comparison only through read-only commands or a separate temporary worktree.
4. Require every reviewer output to state the git range, task diff, or file set it reviewed.
5. Update the review prompt template so the orchestration prompt passes concrete review context instead of asking reviewers to discover the entire repo.
6. Add verifier coverage in `scripts/verify-workflow.ps1` for the key safety phrases.

### Code Snippets

Use wording close to this in review surfaces:

```markdown
## Read-Only Review Contract

You are reviewing only. Do not modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts. If you need to inspect another revision, use read-only git commands or a separate temporary worktree. Your output must state the git range, task diff, or file set reviewed.
```

Verifier checks can use `Require-Contains`-style assertions matching existing PowerShell verifier patterns.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `Select-String -Path skills/build-feature/references/review-prompt-template.md,agents/s-kit-spec-reviewer.md,agents/s-kit-code-reviewer.md -Pattern 'Read-Only Review Contract'`
- Expected: Before implementation, the search should not find the required contract in all review surfaces.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes and includes regression checks for read-only review wording and reviewed-range reporting.

### Final Verification

- Command: `npm test`
- Expected: Branding, assets, agents, naming, and workflow verification all pass.

## Acceptance Criteria

- [ ] Review prompt template forbids reviewer mutation of files, index, HEAD, branch state, staged files, task statuses, and generated artifacts.
- [ ] Spec reviewer agent has the same read-only contract.
- [ ] Code reviewer agent has the same read-only contract.
- [ ] Review outputs are required to identify the git range, task diff, or file set reviewed.
- [ ] `scripts/verify-workflow.ps1` protects the new behavior.
- [ ] `npm test` passes.

## Notes

Do not broaden this task into action-language cleanup. That is task 04 and runs later to avoid overlapping shared prompt files in the same Phase.
