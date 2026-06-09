# Task 02: Complete Punch-List Mode

## Status

complete

## Wave

2

## Description

Add complete punch-list behavior to the `build-feature` fix loop. When repeated review failures clearly cluster around the same integration boundary, the workflow should ask for one complete boundary review before sending another narrow fix. This keeps the three-cycle cap meaningful and reduces serial discovery of related issues.

## Dependencies

**Depends on:** task-01-wave-risk-preflight.md
**Blocks:** task-03-verification-guardrails.md

**Context from dependencies:** task-01 adds Wave Risk Preflight as a named wave context that coder, simplifier, and review prompts receive. This task builds on that concept by using preflight and review history to decide when a repeated boundary failure needs a complete punch-list review.

## Files to Create

None.

## Files to Modify

- `skills/build-feature/SKILL.md` - Add complete punch-list trigger and fix-loop behavior.
- `skills/build-feature/references/review-prompt-template.md` - Add review instructions for complete punch-list mode.
- `skills/build-feature/references/fix-prompt-template.md` - Include punch-list issues and boundary context in fix prompts when applicable.
- `skills/build-feature/references/simplifier-prompt-template.md` - Clarify when no-op simplification is acceptable after trivial targeted fixes.

## Technical Details

### Implementation Steps

1. In `skills/build-feature/SKILL.md`, update the fix loop to detect repeated failures in the same boundary after at least one fix attempt.
2. Define "same boundary" pragmatically: failures share the same files, public contract, runtime behavior, package/config mapping, generated artifact, or cross-task integration point.
3. When repeated same-boundary failure is detected, instruct the orchestrator to request a complete punch-list review for that boundary before dispatching further fix agents.
4. The complete punch-list review must be read-only and must return all blocking issues it can find within the concrete boundary scope.
5. The workflow must still keep the existing three simplification/review cycle cap.
6. Update review prompt wording so a reviewer can be explicitly asked for complete punch-list mode.
7. Update fix prompt wording so fix agents receive the full punch list, boundary context, source review type, and relevant task files.
8. Update simplifier guidance to allow a `no-op` result for trivial targeted fixes when the fix does not add duplication, alter structure, or create maintainability risk.
9. Do not remove the normal spec-compliance and code-quality review sequence.

### Code Snippets

Suggested trigger language:

```text
If a wave fails review more than once in the same boundary, request a complete punch-list review for that boundary before dispatching another narrow fix.
```

Suggested simplifier language:

```text
After a trivial targeted fix, the simplifier may return `no-op` when no behavior-preserving cleanup is warranted.
```

### Environment Variables

Not applicable.

### API Endpoints

Not applicable.

## Verification Plan

### RED

- Command: `Select-String -Path skills/build-feature/SKILL.md,skills/build-feature/references/*.md -Pattern 'complete punch-list'`
- Expected: Before implementation, complete punch-list behavior is absent from active build-feature workflow surfaces.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes after punch-list behavior is added.

### Final Verification

- Command: `npm run verify:naming`
- Expected: Canonical workflow naming still passes and no retired workflow names are introduced.

## Acceptance Criteria

- [x] `build-feature` defines when repeated same-boundary failures trigger complete punch-list review.
- [x] Complete punch-list review is read-only and uses a concrete boundary scope.
- [x] Fix prompts can receive and act on the complete punch list.
- [x] The existing three-cycle cap remains in place.
- [x] Trivial targeted fixes can produce an explicit no-op simplification result.
- [x] Independent spec-compliance and code-quality review gates remain intact.

## Notes

Do not make every first review failure use complete punch-list mode. The design only broadens review after repeat same-boundary failure.
