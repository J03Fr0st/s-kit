# Task 02: Harness Porting Playbook

## Status

complete

## Phase

1

## Description

Add a durable operational playbook for porting `s-kit` to a new harness, based on the Superpowers `dev` `docs/porting-to-a-new-harness.md` concept. The playbook should be adapted to `s-kit` and should not copy Superpowers naming or assumptions. It gives future maintainers a safe checklist for adding support for IDEs, CLIs, or agent runners.

## Dependencies

**Depends on:** None (Phase 1)
**Blocks:** task-05-codex-native-hooks.md

**Context from dependencies:** None. This task creates the harness-porting guidance that the Codex hook task should follow.

## Files to Create

- `docs/playbooks/port-new-harness.md` — durable operational guide for adding a new `s-kit` harness integration.

## Files to Modify

- `scripts/verify-branding.ps1` — keep shipped product branding checks strict while exempting dated planning artifacts that legitimately cite upstream comparison targets.
- `scripts/verify-skill-names.ps1` — keep shipped product naming checks strict while exempting dated planning artifacts that legitimately discuss retired-name guardrails.

## Technical Details

### Implementation Steps

1. Create `docs/playbooks/` if it does not exist.
2. Create `docs/playbooks/port-new-harness.md`.
3. Write the playbook in `s-kit` language, not Superpowers language.
4. Include sections for:
   - harness discovery
   - install mechanism
   - skill discovery and invocation
   - bootstrap/session-start behavior
   - tool mapping
   - acceptance tests
   - local install verification
   - distribution and release checks
5. Include non-negotiables:
   - do not edit skill bodies for one harness
   - do not require manual user config edits when a plugin install path exists
   - keep runtime-specific mapping in references or harness-specific surfaces
6. Include a short checklist maintainers can follow before opening a PR.
7. Ensure repository verification still passes when dated `docs/design/**` and `docs/specs/**` artifacts cite upstream projects or retired-name guardrails. Exempt only those dated planning artifacts; do not weaken shipped product-surface scans.

### Code Snippets

The playbook should include a checklist like:

```markdown
## Port Checklist

- [ ] Identify the harness install mechanism.
- [ ] Identify how the harness discovers skills.
- [ ] Identify how bootstrap/session-start context is loaded.
- [ ] Map action-language operations to native tools.
- [ ] Add or update plugin manifest files.
- [ ] Add local install verification.
- [ ] Add packaging/doctor checks.
- [ ] Run `npm test` and `npm run doctor`.
```

### Environment Variables

None.

### API Endpoints

None.

## Verification Plan

### RED

- Command: `Test-Path docs/playbooks/port-new-harness.md`
- Expected: Before implementation, the path does not exist.

### GREEN

- Command: `git diff --check -- docs/playbooks/port-new-harness.md`
- Expected: No whitespace errors in the new playbook.

### Final Verification

- Command: `npm run doctor`
- Expected: Doctor passes after the new docs folder/file exists.

## Acceptance Criteria

- [ ] `docs/playbooks/port-new-harness.md` exists.
- [ ] The playbook is written for `s-kit` rather than Superpowers.
- [ ] The playbook covers discovery, install, bootstrap, tool mapping, tests, local verification, and distribution.
- [ ] The playbook states the non-negotiables from the approved design.
- [ ] Branding and naming verifiers still scan shipped product surfaces while allowing dated planning artifacts to cite upstream comparison targets and retired-name guardrails.
- [ ] `git diff --check -- docs/playbooks/port-new-harness.md` passes.

## Notes

This task should not modify README or package manifests. Keep the first playbook standalone unless a later review asks for index links.
