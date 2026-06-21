# Task 01: Skill Trigger Tests

## Status

complete

## Phase

1

## Description

Add test prompts for the three new skills before implementing their bodies. This gives the skill changes a RED phase: the suite should not yet be able to find `domain-modeling`, `codebase-design`, or `prototype` as first-class skill surfaces until the later tasks add them.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-02-new-engineering-skills.md

**Context from dependencies:** None.

## Files to Create

- `tests/skill-triggering/prompts/domain-modeling.txt` - model-invoked trigger prompt for domain terminology work.
- `tests/skill-triggering/prompts/codebase-design.txt` - model-invoked trigger prompt for deep-module/interface design work.
- `tests/skill-triggering/prompts/prototype.txt` - model-invoked trigger prompt for throwaway prototype work.
- `tests/explicit-skill-requests/prompts/use-domain-modeling.txt` - explicit skill request prompt.
- `tests/explicit-skill-requests/prompts/use-codebase-design.txt` - explicit skill request prompt.
- `tests/explicit-skill-requests/prompts/use-prototype.txt` - explicit skill request prompt.

## Files to Modify

- `tests/skill-triggering/run-all.sh` - include the three new trigger prompts.
- `tests/explicit-skill-requests/run-all.sh` - include explicit request coverage for the three new skills.

## Technical Details

### Implementation Steps

1. Inspect the existing shell test harnesses to match the prompt naming and expected-skill style.
2. Add one prompt per new skill in both suites where appropriate.
3. Keep prompts short and clear. They should mention the behavior that should trigger the skill, not implementation details.
4. Run the targeted shell suites with Git Bash on Windows.

### Code Snippets

Use existing `run-test.sh` invocations as the pattern. Do not introduce a new test harness.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `C:\Program Files\Git\bin\bash.exe tests/skill-triggering/run-all.sh`
- Expected: Before later tasks, the new prompts should fail because the new skills are not present or not routed.

### GREEN

- Command: `C:\Program Files\Git\bin\bash.exe tests/skill-triggering/run-all.sh`
- Expected: After later tasks, all trigger prompts pass.

### Final Verification

- Command: `C:\Program Files\Git\bin\bash.exe tests/explicit-skill-requests/run-all.sh`
- Expected: Explicit requests for the new skills pass along with existing explicit request coverage.

## Acceptance Criteria

- [ ] Trigger prompts exist for `domain-modeling`, `codebase-design`, and `prototype`.
- [ ] Explicit request prompts exist for the same three skills.
- [ ] Harness entries follow existing style.
- [ ] The test additions fail before the new skills are implemented and pass after implementation.
