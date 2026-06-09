# Task 03: Verification Guardrails

## Status

done-with-concerns

## Wave

3

## Description

Add verification guardrails so the new `build-feature` risk preflight and complete punch-list behavior remain wired into active workflow surfaces. The verification should be durable but not brittle: check required concepts and prompt placeholders, not exact prose.

## Dependencies

**Depends on:** task-02-complete-punch-list-mode.md
**Blocks:** None

**Context from dependencies:** task-01 adds Wave Risk Preflight to build-feature and prompt templates. task-02 adds complete punch-list mode and targeted no-op simplification guidance. This task protects those workflow contracts in the existing verification script.

## Files to Create

None.

## Files to Modify

- `scripts/verify-workflow.ps1` - Add required-text checks for risk preflight, prompt threading, complete punch-list behavior, and no-op simplification guidance.

## Technical Details

### Implementation Steps

1. Inspect existing `scripts/verify-workflow.ps1` required-text checks.
2. Add checks for the new workflow concepts using concise required strings.
3. Required coverage should include:
   - `Wave Risk Preflight` in `skills/build-feature/SKILL.md`.
   - Preflight prompt placeholder or section in coder, review, and simplifier prompt templates.
   - Complete punch-list behavior in `skills/build-feature/SKILL.md`.
   - Complete punch-list review support in the review prompt template.
   - Fix prompt support for full punch-list context when applicable.
   - No-op simplification guidance after trivial targeted fixes.
4. Keep checks resilient to minor wording changes. Avoid asserting entire paragraphs.
5. Do not add new package scripts unless necessary. Prefer existing `npm run verify:workflow` and `npm test`.

### Code Snippets

Pattern to follow:

```powershell
foreach ($requiredText in @(
  'Wave Risk Preflight',
  '{wave_risk_preflight}'
)) {
  if (-not $buildFeatureSkill.Contains($requiredText)) {
    Add-Failure "build-feature workflow must include risk preflight text: $requiredText"
  }
}
```

Use the repo's existing helper patterns rather than introducing a new parser.

### Environment Variables

Not applicable.

### API Endpoints

Not applicable.

## Verification Plan

### RED

- Command: `npm run verify:workflow`
- Expected: Before implementation, adding the new required checks would fail because active workflow surfaces do not yet contain the new contract.

### GREEN

- Command: `npm run verify:workflow`
- Expected: Workflow verification passes after the active workflow surfaces and verification script agree.

### Final Verification

- Command: `npm test`
- Expected: Full package verification passes, including plugin syntax, branding, assets, agents, naming, and workflow checks.

## Acceptance Criteria

- [x] `verify-workflow.ps1` checks for risk preflight in active build-feature surfaces.
- [x] `verify-workflow.ps1` checks for complete punch-list behavior.
- [x] `verify-workflow.ps1` checks for no-op simplification guidance after trivial targeted fixes.
- [x] `npm run verify:workflow` passes.
- [x] `npm run verify:naming` passes.
- [ ] `npm test` passes.

## Notes

Keep this task limited to verification guardrails. Do not broaden it into unrelated workflow cleanup.
