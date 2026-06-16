# Task 02: Semantic Spec Review Gate

## Status

complete

## Wave

1

## Description

Make semantic spec review explicit after `plan-feature` creates a spec and before `build-feature` implements it. The goal is to catch design coverage gaps, ambiguous requirements, unsafe waves, and weak verification while the fix is still cheap.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** task-03-run-state-semantics.md

**Context from dependencies:** This task starts from the approved design. Run-state semantics in the next task depend on this gate being clearly positioned in the workflow.

## Files to Create

None.

## Files to Modify

- `skills/plan-feature/SKILL.md` - Add a post-spec semantic review step and report language.
- `agents/s-kit-spec-reviewer.md` - Ensure the agent describes its role as the post-spec semantic gate.

## Technical Details

### Implementation Steps

1. In `plan-feature`, add a step after file creation and structural consistency checks that instructs the agent to run or hand off to `s-kit-spec-reviewer`.
2. The review must be read-only and should cover design coverage, ambiguity, task independence, verification quality, and manifest consistency.
3. Add report wording so users know implementation should wait for the review to pass or for requested changes to be addressed.
4. Update `s-kit-spec-reviewer` only if needed to reflect that it is the semantic pre-implementation gate.
5. Preserve current `plan-feature` behavior and generated artifact structure.

### Code Snippets

No fixed snippet required. Keep the wording concise and exact.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `rg -n "semantic|s-kit-spec-reviewer|pre-implementation" skills/plan-feature/SKILL.md agents/s-kit-spec-reviewer.md`
- Expected: Before implementation, the post-spec semantic gate is not explicit enough in `plan-feature`.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow structural verification passes after the new step.

### Final Verification

- Command: `npm run verify:agents`
- Expected: Agent catalog verification passes.

## Acceptance Criteria

- [ ] `plan-feature` clearly calls for semantic review before implementation.
- [ ] The gate uses existing `s-kit-spec-reviewer`.
- [ ] The review remains read-only.
- [ ] User-facing next steps mention review before `build-feature`.
