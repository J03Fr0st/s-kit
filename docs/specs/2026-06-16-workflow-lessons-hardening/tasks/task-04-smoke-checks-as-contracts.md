# Task 04: Smoke Checks as Contracts

## Status

complete

## Wave

3

## Description

Document named smoke checks as contracts so maintainers and agents know which local commands prove each packaging or workflow surface. This should make release confidence easier without creating a dashboard or new runtime.

## Dependencies

**Depends on:** task-01-doctor-packaging-contracts.md, task-03-run-state-semantics.md
**Blocks:** task-05-writing-quality-guardrails.md

**Context from dependencies:** task-01 strengthens the doctor contract checks. task-03 clarifies state tracking in generated specs. This task documents the checks that prove those surfaces.

## Files to Create

- `docs/playbooks/smoke-checks.md` - Text-first smoke check catalog.

## Files to Modify

- `README.md` - Link or summarize the smoke check catalog.
- `package.json` - Add script alias only if it improves clarity without duplicating existing commands.

## Technical Details

### Implementation Steps

1. Create a playbook listing smoke checks by surface: workflow, agents, assets, naming, hooks, doctor, OpenCode plugin syntax, full test suite.
2. Include command, purpose, and expected result for each.
3. Link the playbook from README verification docs.
4. Add a `smoke` script only if it maps cleanly to an existing command such as `npm test`; do not add overlapping command chains that drift from existing verification.

### Code Snippets

No fixed snippet required.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `Test-Path docs/playbooks/smoke-checks.md`
- Expected: Before implementation, the playbook does not exist.

### GREEN

- Command: `npm run doctor`
- Expected: Doctor passes after README/package updates.

### Final Verification

- Command: `npm test`
- Expected: Full verification passes.

## Acceptance Criteria

- [ ] A smoke-check playbook exists.
- [ ] README links to the playbook.
- [ ] Commands and expected outcomes are concrete.
- [ ] Any package script addition is minimal and non-duplicative.
