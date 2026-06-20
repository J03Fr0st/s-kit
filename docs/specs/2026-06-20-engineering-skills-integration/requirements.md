# Requirements: Engineering Skills Integration

## Functional Requirements

1. `s-kit` must expose `domain-modeling` as a supporting skill for active glossary and ADR maintenance.
2. `s-kit` must expose `codebase-design` as a supporting skill for deep-module architecture vocabulary.
3. `s-kit` must expose `prototype` as a supporting skill for throwaway runnable design experiments.
4. `brainstorming` must mention `prototype` as an optional detour when a design question cannot be settled in conversation.
5. `grill-with-docs` must point to `domain-modeling` for glossary and ADR mechanics while retaining its interview role.
6. `test-driven-development` must emphasize behavior-through-interface tests and avoid implementation-detail testing.
7. `systematic-debugging` must emphasize a tight red-capable feedback loop before hypotheses.
8. README and `using-s-kit` must list and route the new skills without replacing the existing core workflow.
9. Skill trigger and explicit request tests must cover the new skills.
10. Project verification must pass with the new skill set.

## Non-Goals

- Do not add issue/PRD export, triage, or setup workflows in this slice.
- Do not change plugin packaging behavior beyond catalog/verifier updates required for the new skills.
- Do not refactor unrelated skill text.
- Do not alter existing dirty worktree changes except where this feature directly requires it.

## Acceptance Criteria

- [ ] `skills/domain-modeling/SKILL.md` exists with valid frontmatter and supporting reference files.
- [ ] `skills/codebase-design/SKILL.md` exists with valid frontmatter and supporting reference files.
- [ ] `skills/prototype/SKILL.md` exists with valid frontmatter and supporting reference files.
- [ ] README and `using-s-kit` include the new skills in the supporting workflow.
- [ ] Existing workflow skills route to the new skills in the approved places.
- [ ] Trigger tests include prompts for all three new skills.
- [ ] `npm test` passes or any failures are reported with exact evidence.
- [ ] `graphify update .` is run after modifications.
