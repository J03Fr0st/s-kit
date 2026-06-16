# Task 03: Run-State Semantics

## Status

complete

## Wave

2

## Description

Add clearer run-state and resume semantics to existing spec artifacts and build guidance. This borrows the useful state/resume lesson from workflow engines without introducing a new engine.

## Dependencies

**Depends on:** task-02-semantic-spec-review-gate.md
**Blocks:** task-04-smoke-checks-as-contracts.md

**Context from dependencies:** task-02 positions semantic review before implementation. This task describes how the existing manifest, README checkboxes, and implementation log express paused, failed, resumed, and completed work once implementation starts.

## Files to Create

None.

## Files to Modify

- `skills/plan-feature/references/spec-json-template.json` - Add optional run-state metadata shape.
- `skills/plan-feature/references/readme-template.md` - Add concise run-state guidance.
- `skills/plan-feature/SKILL.md` - Instruct generated specs to include the run-state conventions.
- `skills/build-feature/SKILL.md` - Clarify resume behavior using existing statuses and logs.

## Technical Details

### Implementation Steps

1. Add an optional top-level `runState` example to the manifest template with values such as `not-started`, `running`, `paused`, `review-failed`, `blocked`, and `complete`.
2. Make clear that task status remains the source of truth for individual tasks.
3. Update README template guidance so generated specs explain resume state through README checkboxes, `spec.json`, and `implementation-log.md`.
4. Update `build-feature` wording to append resume/failure evidence to the implementation log instead of relying on chat history.
5. Preserve the canonical allowed task statuses already enforced by the verifier.

### Code Snippets

Example manifest shape:

```json
"runState": {
  "status": "not-started",
  "lastCompletedWave": 0,
  "currentWave": 1,
  "resumeNotes": []
}
```

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `rg -n "runState|resumeNotes|lastCompletedWave" skills/plan-feature skills/build-feature`
- Expected: Before implementation, the explicit run-state shape is absent.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes with the new run-state text.

### Final Verification

- Command: `npm test`
- Expected: The full suite passes.

## Acceptance Criteria

- [ ] Manifest template includes optional run-state metadata.
- [ ] README template explains where resume status is tracked.
- [ ] `build-feature` tells agents to record resume and failure evidence in `implementation-log.md`.
- [ ] Existing task statuses are not replaced or renamed.
