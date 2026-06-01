# Task 03: Eval Harness Strategy

## Status

complete

## Wave

1

## Description

Create a strategy document for whether and how `s-kit` should adopt behavior-level evals. Superpowers `dev` moved many bash tests into a drill/evals harness, but `s-kit` should not copy that architecture blindly. This task produces a coverage-aware strategy and explicitly prevents test deletion without mapped replacement coverage.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** task-05-codex-native-hooks.md

**Context from dependencies:** None. This task creates the eval/testing strategy constraints that later harness work should respect.

## Files to Create

- `docs/eval-harness-strategy.md` — strategy document for behavior-level evals versus structural tests.

## Files to Modify

None.

## Technical Details

### Implementation Steps

1. Create `docs/eval-harness-strategy.md`.
2. Summarize the Superpowers `dev` eval-harness direction:
   - evals become canonical skill-behavior checks
   - some bash tests are removed only after coverage mapping
   - retained bash tests are annotated when no eval equivalent exists
3. Map current `s-kit` test categories:
   - `tests/opencode/` plugin structure/bootstrap tests
   - `tests/codex-plugin-sync/` packaging sync tests
   - `tests/claude-code/` behavior/integration tests
   - `tests/explicit-skill-requests/` skill invocation behavior tests
   - `tests/skill-triggering/` trigger behavior tests
   - `tests/build-feature/` fixture-driven implementation tests
   - `scripts/verify-*.ps1` structural verification gates
4. Classify tests into:
   - structural tests that should stay as scripts
   - behavior tests that are candidates for future evals
   - integration tests that may stay optional
5. State the deletion rule: no test deletion without a coverage map proving each assertion is represented by a new eval criterion.
6. Recommend a first eval spike, but do not implement an eval harness in this task.

### Code Snippets

Include a coverage-map template:

```markdown
| Existing Test | Assertion | Candidate Eval | Delete? | Evidence |
| --- | --- | --- | --- | --- |
| `tests/...` | ... | ... | No | No eval exists yet |
```

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `Test-Path docs/eval-harness-strategy.md`
- Expected: Before implementation, the path does not exist.

### GREEN

- Command: `git diff --check -- docs/eval-harness-strategy.md`
- Expected: No whitespace errors in the strategy document.

### Final Verification

- Command: `npm test`
- Expected: Existing test and verifier suite still passes; no tests have been removed by this strategy task.

## Acceptance Criteria

- [ ] `docs/eval-harness-strategy.md` exists.
- [ ] The document distinguishes structural tests from behavior-eval candidates.
- [ ] The document includes the no-deletion-without-coverage-map rule.
- [ ] The document recommends a first eval spike without implementing the harness.
- [ ] `npm test` passes.

## Notes

Do not add a submodule, vendored eval harness, or new test runner in this task. This is a strategy artifact by design.
