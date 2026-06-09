# Task 01: Wave Risk Preflight

## Status

complete

## Wave

1

## Description

Add a read-only Wave Risk Preflight step to `build-feature` before coder dispatch. The step should identify likely integration contracts for the current wave and thread that context into coder, simplifier, and review prompts. This reduces slow review/fix churn by making risky boundaries explicit before agents write code.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** task-02-complete-punch-list-mode.md

**Context from dependencies:** No implementation dependencies. This task establishes the preflight concept that later punch-list behavior depends on.

## Files to Create

None.

## Files to Modify

- `skills/build-feature/SKILL.md` - Add the Wave Risk Preflight orchestration step and describe where it fits in the wave flow.
- `skills/build-feature/references/coder-prompt-template.md` - Add preflight context to coder prompts.
- `skills/build-feature/references/review-prompt-template.md` - Add preflight context to review prompts and scope expectations.
- `skills/build-feature/references/simplifier-prompt-template.md` - Add preflight context to simplification prompts.

## Technical Details

### Implementation Steps

1. In `skills/build-feature/SKILL.md`, add a Wave Risk Preflight step after wave preparation and before coder dispatch.
2. The preflight must be read-only and derived from existing inputs:
   - Approved design.
   - Requirements.
   - Current wave task files.
   - `spec.json` file ownership.
   - Completed task summaries.
   - Current wave verification commands.
3. The preflight should identify likely shared contracts, not prove correctness. Include examples such as public exports, compatibility entrypoints, platform substitutions, module-load side effects, timers, generated artifacts, cross-task shared types, auth/filesystem/shell/network/security boundaries, and grouped verification needs.
4. Update the coder prompt template so the orchestrator can pass the preflight as explicit implementation risk context.
5. Update the review prompt template so reviewers are required to use the preflight as part of the review scope.
6. Update the simplifier prompt template so simplification keeps the preflight boundary in mind and does not simplify across protected contracts accidentally.
7. Keep terminology concise. Do not add a new skill, agent, status value, or persistent state.

### Code Snippets

Suggested placeholder wording for prompt templates:

```text
## Wave Risk Preflight

{wave_risk_preflight}
```

Suggested SKILL wording:

```text
The preflight is not a review verdict. It is a short list of contracts and risks that coder, simplifier, and review agents must account for during this wave.
```

### Environment Variables

Not applicable.

### API Endpoints

Not applicable.

## Verification Plan

### RED

- Command: `Select-String -Path skills/build-feature/SKILL.md,skills/build-feature/references/*.md -Pattern 'Wave Risk Preflight'`
- Expected: Before implementation, the term is absent from active build-feature workflow surfaces.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes after the new preflight wording is added.

### Final Verification

- Command: `npm run verify:naming`
- Expected: Canonical workflow naming still passes and no retired workflow names are introduced.

## Acceptance Criteria

- [x] `build-feature` defines a read-only Wave Risk Preflight step before coder dispatch.
- [x] The preflight uses only existing spec/design/task/log inputs.
- [x] Coder prompts accept and display wave risk preflight context.
- [x] Review prompts require reviewers to consider the preflight.
- [x] Simplifier prompts include the preflight as boundary context.
- [x] No new skill, agent, task status, or persistent state is introduced.

## Notes

Keep the preflight practical. It should be a focused wave-specific checklist, not a generic architecture review.
