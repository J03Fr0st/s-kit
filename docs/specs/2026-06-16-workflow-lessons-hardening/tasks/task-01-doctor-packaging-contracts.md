# Task 01: Doctor Packaging Contracts

## Status

complete

## Wave

1

## Description

Strengthen `scripts/doctor.ps1` so it treats cross-harness packaging surfaces as explicit contracts. This pulls the useful "one source, harness-native outputs, validate drift" lesson into `s-kit` without adding a marketplace generator.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** task-04-smoke-checks-as-contracts.md

**Context from dependencies:** This task starts from the approved design. Later smoke-check documentation depends on the contract names and checks made explicit here.

## Files to Create

None.

## Files to Modify

- `scripts/doctor.ps1` - Add clearer contract checks for package scripts, expected harness surfaces, and local smoke entry points.

## Technical Details

### Implementation Steps

1. Keep `doctor.ps1` deterministic and local.
2. Add validation that `package.json` exposes `doctor`, `test`, `verify:workflow`, `verify:agents`, `verify:assets`, `verify:naming`, `verify:hooks`, and `verify:branding`.
3. Add a small contract table/list inside the script for known packaging surfaces: Codex, Claude, Cursor, OpenCode, Gemini, hooks, assets.
4. Verify each surface has at least one concrete local smoke check or manifest/path validation.
5. Preserve existing checks and exact failure behavior.

### Code Snippets

No fixed snippet required. Prefer small helper functions over a broad rewrite.

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `npm run doctor`
- Expected: Before implementation, the command passes but does not validate package-script smoke contracts.

### GREEN

- Command: `npm run doctor`
- Expected: The command passes and includes the new package-script and surface contract checks.

### Final Verification

- Command: `npm test`
- Expected: The full existing verification suite passes.

## Acceptance Criteria

- [ ] `doctor.ps1` validates required package scripts.
- [ ] `doctor.ps1` groups or names packaging surface contracts clearly.
- [ ] Existing manifest, path, retired-path, syntax, and hygiene checks remain intact.
- [ ] No network or external harness installation is required.
