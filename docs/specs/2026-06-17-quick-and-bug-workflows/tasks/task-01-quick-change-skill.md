# Task 01: Quick Change Skill

## Status

complete

## Wave

1

## Description

Create a first-class `quick-change` skill for small, clear, low-blast-radius edits. The skill should be fast by avoiding dated design/spec artifacts, but still require assumptions, success criteria, scoped file inspection, minimal edits, and fresh verification before completion claims.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** task-04-verification-and-trigger-tests.md

**Context from dependencies:** None. This task creates the new skill that later verifier and trigger tests will require.

## Files to Create

- `skills/quick-change/SKILL.md` - scoped workflow instructions for quick changes.

## Files to Modify

None.

## Technical Details

### Implementation Steps

1. Create `skills/quick-change/SKILL.md`.

2. Use the same concise structure as existing `s-kit` skills:
   - frontmatter with `name: quick-change`
   - short description
   - mandatory workflow instructions
   - related skills section

3. Define the quick-change criteria:
   - clear requested outcome
   - low blast radius
   - expected change around 1-3 files
   - no design or architecture decision
   - direct verification command is available or can be discovered

4. Define the required workflow:
   - state assumptions and success criteria
   - inspect `git status --short`
   - read relevant files before editing
   - name the verification command before editing when knowable
   - make the smallest scoped change
   - use `test-driven-development` first when behavior changes and a correct test seam exists
   - remove only unused code introduced by this change
   - run `verification-before-completion`
   - use `requesting-code-review` when behavior changed, the diff is nontrivial, or the area is security or workflow sensitive
   - report changed files, verification evidence, review status if used, and residual risk

5. Add escalation rules:
   - if scope expands beyond the quick-change criteria, stop and route to `brainstorming`
   - if the issue is broken behavior, route to `systematic-debugging`
   - if the change becomes architectural, route to `brainstorming` or `grill-with-docs` as appropriate

6. Explicitly state that quick changes do not create dated `docs/design/` or `docs/specs/` folders.

### Code Snippets

Expected frontmatter shape:

```markdown
---
name: quick-change
description: Use for small scoped changes with clear success criteria and direct verification, when dated design/spec workflow would be unnecessary.
---
```

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "Test-Path skills/quick-change/SKILL.md"`
- Expected: fails before implementation because the skill file does not exist.

### GREEN

- Command: `powershell -NoProfile -Command "Select-String -Path skills/quick-change/SKILL.md -Pattern 'quick-change','verification-before-completion','requesting-code-review'"`
- Expected: all required skill references are present.

### Final Verification

- Command: `powershell -NoProfile -Command "Select-String -Path skills/quick-change/SKILL.md -Pattern 'docs/design','docs/specs','brainstorming','systematic-debugging'"`
- Expected: the skill documents no dated spec folders for quick work and escalation to the right lanes.

## Acceptance Criteria

- [ ] `skills/quick-change/SKILL.md` exists.
- [ ] The skill describes the quick-change criteria.
- [ ] The skill requires assumptions, success criteria, relevant file reads, scoped edits, and verification.
- [ ] The skill routes behavior-changing edits through TDD when a correct test seam exists.
- [ ] The skill invokes `verification-before-completion`.
- [ ] The skill invokes `requesting-code-review` for nontrivial, behavior-changing, security-sensitive, or workflow-sensitive changes.
- [ ] The skill explicitly avoids dated design/spec folders.
- [ ] The skill escalates out of the quick lane when scope or ambiguity grows.

## Notes

Keep this skill small. It exists to reduce ceremony for tiny work, not to become a second feature workflow.
