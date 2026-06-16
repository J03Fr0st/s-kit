# Task 05: Writing Quality Guardrails

## Status

complete

## Wave

4

## Description

Add lightweight writing-quality guardrails for agent-facing docs so skills, prompts, and playbooks stay concrete. This borrows the useful "avoid AI-ish prose" lesson without adding subjective automated linting.

## Dependencies

**Depends on:** task-04-smoke-checks-as-contracts.md
**Blocks:** None

**Context from dependencies:** task-04 creates the smoke-check playbook. This task adds a companion quality playbook and references it from skill-authoring guidance.

## Files to Create

- `docs/playbooks/agent-doc-writing-quality.md` - Checklist for clear, concrete agent-facing prose.

## Files to Modify

- `skills/writing-skills/SKILL.md` - Reference the writing-quality guardrails when creating or editing skills.
- `docs/playbooks/smoke-checks.md` - Include the writing-quality playbook in related checks or references.

## Technical Details

### Implementation Steps

1. Create a concise writing-quality playbook.
2. Include checks for concrete instructions, explicit inputs/outputs, avoided filler, avoided inflated claims, stable terminology, and no fake-collaborative closers.
3. Make clear this is a human/reviewer checklist, not a hard natural-language linter.
4. Reference it from `skills/writing-skills/SKILL.md`.
5. Add it to related playbook references where useful.

### Code Snippets

No fixed snippet required.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `Test-Path docs/playbooks/agent-doc-writing-quality.md`
- Expected: Before implementation, the playbook does not exist.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes with the new docs and skill reference.

### Final Verification

- Command: `npm test`
- Expected: Full verification passes.

## Acceptance Criteria

- [ ] Writing-quality playbook exists.
- [ ] `writing-skills` references the playbook.
- [ ] Guardrails are concrete and not a subjective blocker.
- [ ] Existing verification passes.
