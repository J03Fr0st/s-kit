# Task 04: Verification Surfaces

## Status

complete

## Phase

4

## Description

Update verifier/catalog expectations for the new skills and run the repo's verification gates. Refresh Graphify after the skill/doc changes so generated graph artifacts reflect the new surfaces.

## Dependencies

**Depends on:** task-03-workflow-integration.md
**Blocks:** None

**Context from dependencies:** task-03 updates existing workflow surfaces. This task adjusts verifiers if they enforce a fixed skill catalog and then proves the integrated change works.

## Files to Create

None.

## Files to Modify

- `scripts/doctor.ps1` - include the new skills if required by doctor checks.
- `scripts/verify-skill-names.ps1` - include the new skill names in any allowlists or trigger checks.
- `scripts/verify-workflow.ps1` - include required routing text only if existing workflow checks need it.
- `graphify-out/*` - generated graph refresh from `graphify update .`.

## Technical Details

### Implementation Steps

1. Inspect verifier failures before editing scripts.
2. Make the minimum verifier changes needed for the new first-class skills.
3. Run targeted verifiers first.
4. Run `npm test`.
5. Run `graphify update .` after source/docs changes.
6. Re-run targeted verification if Graphify changes affect branding/workflow checks.

### Code Snippets

No code snippets required.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `npm test`
- Expected: Before verifier updates, fixed catalog checks may fail on missing/unknown new skills.

### GREEN

- Command: `npm test`
- Expected: Project checks pass after verifier/catalog updates.

### Final Verification

- Command: `graphify update .`
- Expected: Graphify refresh completes successfully and generated graph files are updated.

## Acceptance Criteria

- [ ] Verifier changes are minimal and directly tied to the new skills.
- [ ] `npm test` is run and result recorded.
- [ ] `graphify update .` is run and result recorded.
- [ ] Final diff is reviewed for unrelated changes.
