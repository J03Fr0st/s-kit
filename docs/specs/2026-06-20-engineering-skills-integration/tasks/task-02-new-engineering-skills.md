# Task 02: New Engineering Skills

## Status

complete

## Wave

2

## Description

Add the three new supporting skill folders: `domain-modeling`, `codebase-design`, and `prototype`. These should be concise s-kit-native adaptations of the upstream ideas, not verbatim copies, and should follow the repo's current skill authoring conventions.

## Dependencies

**Depends on:** task-01-skill-trigger-tests.md
**Blocks:** task-03-workflow-integration.md

**Context from dependencies:** task-01 adds prompt coverage that expects these skills to exist and be discoverable.

## Files to Create

- `skills/domain-modeling/SKILL.md` - active glossary and ADR maintenance skill.
- `skills/domain-modeling/CONTEXT-FORMAT.md` - glossary format reference.
- `skills/domain-modeling/ADR-FORMAT.md` - ADR format reference.
- `skills/codebase-design/SKILL.md` - deep-module design vocabulary.
- `skills/codebase-design/DEEPENING.md` - focused reference for deepening shallow modules.
- `skills/codebase-design/DESIGN-IT-TWICE.md` - reference for comparing alternative interfaces.
- `skills/prototype/SKILL.md` - prototype routing and lifecycle rules.
- `skills/prototype/LOGIC.md` - logic/state prototype reference.
- `skills/prototype/UI.md` - UI prototype reference.

## Files to Modify

None.

## Technical Details

### Implementation Steps

1. Create each skill folder with valid frontmatter.
2. Use descriptions that start with `Use when...` and only describe trigger conditions.
3. Keep bodies short enough for frequent use, moving heavier examples into reference files.
4. Include explicit "when not to use" boundaries so these skills do not replace `brainstorming`, `plan-feature`, or `build-feature`.
5. Use ASCII-only punctuation.

### Code Snippets

No code snippets are required unless a reference file needs a tiny illustrative example.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skill-names.ps1`
- Expected: Before adding/verifier updates, the new skill names may be missing from expected surfaces.

### GREEN

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skill-names.ps1`
- Expected: New skill folders have valid names and no stale names are introduced.

### Final Verification

- Command: `npm run verify:assets`
- Expected: Asset/catalog checks pass with the new skill folders.

## Acceptance Criteria

- [ ] All three new `SKILL.md` files have valid `name` and `description` frontmatter.
- [ ] `domain-modeling` covers glossary updates, code cross-checks, and ADR thresholds.
- [ ] `codebase-design` covers module/interface/seam/adapter/depth/leverage/locality vocabulary.
- [ ] `prototype` covers logic and UI prototype branches and deletion/absorption rules.
- [ ] Reference files exist only for material too heavy for the main skill.
