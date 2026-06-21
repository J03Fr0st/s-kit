# Task 03: Bug Lane Contract

## Status

complete

## Phase

1

## Description

Tighten `systematic-debugging` with an explicit `s-kit Bug Lane Contract` so bug fixes compose root-cause diagnosis, TDD regression checks, fresh verification, and review when risk warrants.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-04-verification-and-trigger-tests.md

**Context from dependencies:** None. This task updates only the existing debugging skill.

## Files to Create

None.

## Files to Modify

- `skills/systematic-debugging/SKILL.md` - add bug-lane composition and optional debug-note guidance.

## Technical Details

### Implementation Steps

1. Add a short section titled `s-kit Bug Lane Contract`.

2. State the composition explicitly:
   - `systematic-debugging` establishes root cause and a reproducible feedback loop
   - `test-driven-development` turns the minimized repro into a failing regression check when a correct seam exists
   - `verification-before-completion` reruns the original symptom and the regression check
   - `requesting-code-review` is required for complex bugs, workflow-sensitive areas, security-sensitive areas, or any fix with broad impact

3. Add optional debug-note guidance for nontrivial or long-running bugs:

   ```text
   .s-kit/debug/YYYY-MM-DD-{slug}.md
   ```

4. The note should capture:
   - symptoms
   - repro command
   - evidence
   - hypotheses
   - current focus
   - root cause
   - fix summary
   - regression check
   - remaining risk

5. Keep the existing root-cause-first instructions intact. Do not weaken the existing "no fixes without root cause" discipline.

6. Add escalation language:
   - if a bug grows beyond roughly 3 files or needs architecture decisions, stop and route to `brainstorming` or an architecture-focused skill after recording the evidence

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Select-String -Path skills/systematic-debugging/SKILL.md -Pattern 's-kit Bug Lane Contract'"`
- Expected: fails or returns no match before implementation.

### GREEN

- Command: `powershell -NoProfile -Command "Select-String -Path skills/systematic-debugging/SKILL.md -Pattern 's-kit Bug Lane Contract','test-driven-development','verification-before-completion','.s-kit/debug'"`
- Expected: all required contract terms are present.

### Final Verification

- Command: `npm run verify:workflow`
- Expected: passes after task 04 updates workflow verification.

## Acceptance Criteria

- [ ] `systematic-debugging` includes `s-kit Bug Lane Contract`.
- [ ] The section preserves root-cause-first debugging.
- [ ] The section names TDD regression checks when a correct seam exists.
- [ ] The section names fresh verification of the original symptom and regression check.
- [ ] The section requires review for complex, sensitive, or broad-impact bugs.
- [ ] Optional `.s-kit/debug/YYYY-MM-DD-{slug}.md` notes are documented for nontrivial investigations.
- [ ] Bug-lane escalation to design/architecture work is documented.

## Notes

Do not create a separate bug skill. The approved design keeps bug work as a lane contract over existing skills.
