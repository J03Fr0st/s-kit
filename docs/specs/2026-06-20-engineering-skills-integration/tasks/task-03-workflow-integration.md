# Task 03: Workflow Integration

## Status

complete

## Phase

3

## Description

Wire the new skills into the existing `s-kit` workflow surfaces. The core feature workflow stays unchanged; this task only adds routing language so agents know when the supporting skills apply.

## Dependencies

**Depends on:** task-02-new-engineering-skills.md
**Blocks:** task-04-verification-surfaces.md

**Context from dependencies:** task-02 creates the new skill folders and reference files. This task updates existing skills and README to reference those new surfaces.

## Files to Create

None.

## Files to Modify

- `README.md` - add the new skills to workflow and skill catalog.
- `skills/using-s-kit/SKILL.md` - add supporting-skill routing in lane guidance.
- `skills/brainstorming/SKILL.md` - add prototype detour before design approval.
- `skills/grill-with-docs/SKILL.md` - delegate glossary/ADR mechanics to `domain-modeling`.
- `skills/test-driven-development/SKILL.md` - add behavior-through-interface language.
- `skills/systematic-debugging/SKILL.md` - tighten red-capable feedback-loop wording if not already present.

## Technical Details

### Implementation Steps

1. Keep the existing canonical workflow wording intact.
2. Add `prototype` only as an optional detour from `brainstorming` when conversation cannot answer a design question.
3. Add `domain-modeling` and `codebase-design` as supporting skills, not primary workflow steps.
4. Avoid adding PRD/issue/triage routing in this task.
5. Keep edits surgical and do not reformat unrelated paragraphs.

### Code Snippets

No code snippets required.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-workflow.ps1`
- Expected: Before verifier updates, workflow checks may fail if they enforce exact skill lists.

### GREEN

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-workflow.ps1`
- Expected: Workflow invariants pass with the new routing text.

### Final Verification

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skill-names.ps1`
- Expected: Skill-name invariants pass with no stale names.

## Acceptance Criteria

- [ ] README lists the three new skills.
- [ ] `using-s-kit` routes domain-heavy, architecture-heavy, and prototype-needed work correctly.
- [ ] `brainstorming` offers `prototype` as a design detour before approval.
- [ ] `grill-with-docs` references `domain-modeling` without duplicating all of it.
- [ ] TDD/debugging wording improves test and feedback-loop discipline without widening scope.
