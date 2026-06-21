# Task 04: Verification and Trigger Tests

## Status

complete

## Phase

2

## Description

Update verification and trigger-test coverage so the new quick-change skill and bug-lane contract are enforced by the repository's normal checks.

## Dependencies

**Depends on:** task-01-quick-change-skill.md, task-02-routing-and-docs.md, task-03-bug-lane-contract.md
**Blocks:** None

**Context from dependencies:** The skill, router text, README text, and bug-lane contract must exist before verifier and trigger tests can assert them.

## Files to Create

- `tests/skill-triggering/prompts/quick-change.txt` - prompt fixture that should select `quick-change`.
- `tests/explicit-skill-requests/prompts/use-quick-change.txt` - explicit skill request fixture for `quick-change`.

## Files to Modify

- `scripts/verify-branding.ps1` - exclude generated graph output and intentional negative test assertions from branding scans.
- `scripts/doctor.ps1` - include `quick-change` in required packaged skill checks.
- `scripts/verify-skill-names.ps1` - recognize `quick-change` as canonical while preserving retired-name rejection.
- `scripts/verify-workflow.ps1` - enforce quick lane and bug lane composition.
- `tests/skill-triggering/run-all.sh` - add quick-change trigger expectation while preserving bug/debug expectations.
- `tests/explicit-skill-requests/run-all.sh` - add explicit `quick-change` request expectation if this harness requires one entry per first-class skill.

## Technical Details

### Implementation Steps

1. Inspect the current verifier scripts and test harnesses before editing. Match their existing style and failure-message conventions.

2. Update `scripts/verify-branding.ps1`:
   - exclude generated `graphify-out/**` content from branding and old path scans
   - exclude the intentional negative `.superpowers` assertion in `tests/brainstorm-server/start-server.test.sh`
   - keep shipped product surfaces covered by the branding scan

3. Update `scripts/verify-skill-names.ps1`:
   - add `skills/quick-change/SKILL.md` to required first-class skills
   - ensure `quick-change` is considered canonical
   - do not reintroduce retired workflow aliases

4. Update `scripts/doctor.ps1`:
   - add `quick-change` to required skill/file checks using the existing doctor pattern

5. Update `scripts/verify-workflow.ps1`:
   - assert `skills/using-s-kit/SKILL.md` mentions `quick-change`
   - assert the quick lane includes `verification-before-completion`
   - assert the bug lane includes `systematic-debugging`, `test-driven-development`, and `verification-before-completion`
   - assert `skills/systematic-debugging/SKILL.md` contains `s-kit Bug Lane Contract`

6. Add trigger fixtures:
   - quick-change prompt should describe a clear small docs or one-file tweak
   - bug/debug prompts should continue expecting `systematic-debugging`

7. Update run scripts with the minimal extra cases needed for coverage.

8. Run targeted verification first, then `npm test`.

## Verification Plan

### RED

- Command: `npm run verify:naming`
- Expected: fails before implementation because `quick-change` is missing from canonical verifier expectations.

- Command: `npm run verify:branding`
- Expected: fails before implementation when generated graph output or intentional negative assertions contain upstream branding text.

- Command: `npm run verify:workflow`
- Expected: fails before implementation because quick lane and bug-lane contract checks are not present or not satisfied.

### GREEN

- Command: `npm run verify:naming`
- Expected: passes and recognizes `quick-change`.

- Command: `npm run verify:branding`
- Expected: passes while still scanning shipped product surfaces.

- Command: `npm run verify:workflow`
- Expected: passes and enforces quick and bug lane text.

- Command: `bash tests/skill-triggering/run-all.sh`
- Expected: quick-change prompt selects `quick-change`; bug prompts still select `systematic-debugging`.

- Command: `bash tests/explicit-skill-requests/run-all.sh`
- Expected: explicit `quick-change` request is recognized.

### Final Verification

- Command: `npm test`
- Expected: all repository verification checks pass.

## Acceptance Criteria

- [ ] `verify-skill-names` accepts `quick-change` and still rejects retired aliases.
- [ ] `verify-branding` ignores generated graph output and intentional negative test assertions.
- [ ] `doctor` requires the packaged `quick-change` skill.
- [ ] `verify-workflow` enforces quick lane routing and bug lane composition.
- [ ] Skill-triggering tests cover quick-change prompts.
- [ ] Existing systematic-debugging trigger coverage remains intact.
- [ ] Explicit skill request tests cover `quick-change` where applicable.
- [ ] `npm test` passes.

## Notes

Keep verifier changes targeted. This task should not modify the skill content created by Phase 1 except to fix a failed assertion that exposes a real Phase 1 miss.
