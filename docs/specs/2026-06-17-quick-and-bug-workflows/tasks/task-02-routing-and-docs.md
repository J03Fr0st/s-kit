# Task 02: Routing and Docs

## Status

complete

## Phase

1

## Description

Update `using-s-kit` and the README so the workflow router clearly distinguishes quick changes, bug fixes, full features, and hotfixes. This task is documentation and routing text only; it does not modify verifier scripts or tests.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-04-verification-and-trigger-tests.md

**Context from dependencies:** None. The target route references the `quick-change` skill created by task 01, but the text can be updated independently.

## Files to Create

None.

## Files to Modify

- `skills/using-s-kit/SKILL.md` - add quick-change route criteria and boundary rules.
- `README.md` - list the quick workflow and clarify bug workflow behavior.

## Technical Details

### Implementation Steps

1. Update `skills/using-s-kit/SKILL.md` lane selection to include:
   - Quick change: `quick-change -> verification-before-completion`
   - Bug fix: `systematic-debugging -> test-driven-development -> verification-before-completion`
   - Full feature: `brainstorming -> plan-feature -> build-feature`
   - Hotfix: bug lane with user-approved expedited review and follow-up notes for skipped review depth

2. Add boundary rules:
   - quick changes escalate to `brainstorming` when design questions, unclear ownership, or broader blast radius appears
   - small broken behavior is still a bug lane, not a quick-change lane
   - bug fixes escalate to `brainstorming` or architecture-focused skills when they become broad or design-heavy

3. Update README workflow documentation:
   - list `quick-change` in the available workflow skills
   - explain that quick changes and ordinary bugs normally skip dated design/spec folders
   - preserve the existing full-feature workflow documentation
   - keep canonical skill names only

4. Avoid changing unrelated README sections.

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Select-String -Path skills/using-s-kit/SKILL.md -Pattern 'quick-change'"`
- Expected: fails or returns no match before implementation.

### GREEN

- Command: `powershell -NoProfile -Command "Select-String -Path skills/using-s-kit/SKILL.md -Pattern 'quick-change','systematic-debugging','test-driven-development','verification-before-completion'"`
- Expected: the router documents quick-change and bug-lane composition.

- Command: `powershell -NoProfile -Command "Select-String -Path README.md -Pattern 'quick-change','systematic-debugging'"`
- Expected: README documents the quick workflow and bug workflow.

### Final Verification

- Command: `npm run verify:workflow`
- Expected: passes after task 04 updates the verifier to enforce these contracts.

## Acceptance Criteria

- [ ] `using-s-kit` includes a quick-change lane with clear criteria.
- [ ] `using-s-kit` keeps bug fixes routed through systematic debugging, TDD, and verification.
- [ ] `using-s-kit` documents escalation boundaries between quick, bug, and full-feature work.
- [ ] README lists `quick-change`.
- [ ] README explains that quick and ordinary bug lanes normally skip dated design/spec artifacts.
- [ ] Existing full-feature workflow language remains intact.

## Notes

Do not route quick changes through `brainstorming`; the key value of this feature is scale-aware ceremony.
