# Task 04: Action-Language Cleanup

## Status

complete

## Phase

2

## Description

Clean shared `s-kit` skill prose so it describes actions rather than hardcoding one runtime's tool names. Superpowers `dev` moved in this direction with platform tool references and action-language vocabulary. `s-kit` should adopt the useful part while preserving canonical workflow names and runtime-specific reference files.

## Dependencies

**Depends on:** task-01-reviewer-safety-scoped-ranges.md
**Blocks:** None

**Context from dependencies:** Task 01 updates review prompt and reviewer-agent safety wording first. This task may touch some of the same workflow surfaces later, after the safety contract is already in place.

## Files to Create

None.

## Files to Modify

- `skills/using-s-kit/SKILL.md` — clarify action-language and reference-file routing.
- `skills/using-s-kit/references/codex-tools.md` — ensure Codex tool mappings remain host-specific.
- `skills/using-s-kit/references/gemini-tools.md` — ensure Gemini tool mappings remain host-specific.
- `skills/using-s-kit/references/copilot-tools.md` — ensure Copilot tool mappings remain host-specific.
- `skills/build-feature/SKILL.md` — replace runtime-specific tool references in shared prose where practical.
- `skills/dispatching-parallel-agents/SKILL.md` — use action-language for subagent dispatch where practical.
- `skills/requesting-code-review/SKILL.md` — use action-language for review dispatch where practical.
- `scripts/verify-skill-names.ps1` — add focused guardrails if needed.

## Technical Details

### Implementation Steps

1. Search shared skill prose for runtime-specific tool names such as `TodoWrite`, `Task tool`, `Skill tool`, `Read`, `Write`, `Edit`, `Bash`, and runtime-specific dispatch syntax.
2. Do not blindly replace every occurrence. Keep tool names inside runtime-specific reference files and explicit runtime sections.
3. Replace shared prose with action-language such as:
   - create or update a todo
   - dispatch a subagent
   - load a skill
   - read a file
   - edit a file
   - run a shell command
   - inspect a diff
4. Preserve canonical `s-kit` terms:
   - `brainstorming`
   - `plan-feature`
   - `build-feature`
   - `grill-me`
   - `grill-with-docs`
5. Add or adjust verifier coverage only for durable rules. Avoid brittle checks for every sentence.

### Code Snippets

Preferred wording:

```markdown
Dispatch a general-purpose subagent with the task file and requirements context. Use the runtime-specific tool mapping in `skills/using-s-kit/references/` to choose the native dispatch mechanism.
```

Avoid shared prose like:

```markdown
Use the Task tool with general-purpose type.
```

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `rg -n "TodoWrite|Task tool|Skill tool" skills -g "SKILL.md" -g "*.md"`
- Expected: Before implementation, this may show shared-prose occurrences that are not runtime-specific references.

### GREEN

- Command: `npm run verify:naming`
- Expected: Naming verification passes and no retired workflow names were introduced.

### Final Verification

- Command: `npm test`
- Expected: All verification gates pass.

## Acceptance Criteria

- [ ] Shared skill prose uses action-language where practical.
- [ ] Runtime-specific tool names remain in reference files or explicit runtime sections.
- [ ] Canonical `s-kit` workflow names are preserved.
- [ ] No retired Superpowers workflow names are introduced.
- [ ] `npm test` passes.

## Notes

Keep this task scoped. Do not rewrite every skill for style. Focus on wording that affects agent behavior or cross-runtime portability.
