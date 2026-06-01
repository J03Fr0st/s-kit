# Requirements: Superpowers Dev Port Review

## Summary

This feature turns the approved Superpowers `dev` branch comparison into implementable `s-kit` improvements without merging or mirroring the upstream branch wholesale. The source branch is `obra/superpowers@dev` at commit `deceaec78df64a1cabae01fb85e39140b6d833fb`, which is 53 commits ahead of `main` and 1 commit behind `main`.

The work must preserve `s-kit`'s compact, canonical workflow: `brainstorming -> plan-feature -> build-feature -> verification/review -> ship`. It should selectively port the highest-value ideas: safer review agents, operational harness-porting guidance, action-language cleanup, Codex hook compatibility work, and an eval-harness strategy.

## Goals

- Make `build-feature` review agents explicitly read-only and scoped to the relevant git range or task diff.
- Add durable harness-porting guidance under `docs/playbooks/`.
- Define a cautious eval-harness strategy before any migration or test deletion.
- Clean shared skill prose toward action-language while preserving runtime-specific mappings in `skills/using-s-kit/references/`.
- Investigate and, if supported, add Codex native hook support through declared plugin surfaces rather than manual user config edits.

## Non-Goals

- Do not merge or cherry-pick the entire Superpowers `dev` branch.
- Do not reintroduce Superpowers canonical names or retired `s-kit` workflow aliases.
- Do not delete existing tests unless a coverage map proves the assertions are represented elsewhere.
- Do not build a full eval harness in the first pass.
- Do not add manual user configuration requirements for plugin installation.

## Acceptance Criteria

- [ ] Review prompts and/or reviewer agents clearly forbid mutation of the working tree, index, HEAD, branch state, or staged files.
- [ ] Review prompts receive or request a concrete git range/task diff and report what range was reviewed.
- [ ] `docs/playbooks/port-new-harness.md` exists and documents the harness-porting workflow for `s-kit`.
- [ ] A durable eval strategy artifact exists and states which existing tests are structural versus behavior candidates.
- [ ] Shared skill prose touched by this feature uses action-language where practical and keeps host-specific tool names in mapping references.
- [ ] Codex native hook support is either implemented with tests and doctor coverage or explicitly documented as deferred with evidence.
- [ ] `npm test`, `npm run doctor`, version check, and OpenCode plugin tests pass after implementation.

## Assumptions

- The approved design path is `docs/design/2026-06-01-superpowers-dev-port/design.md`.
- `s-kit` remains a compact plugin/workflow repository rather than becoming a broad app or package monorepo.
- GitHub CLI and internet access were used to inspect Superpowers `dev`; implementation can rely on the captured commit SHA and design summary without re-querying unless current compatibility details matter.
- Codex hook support may be unstable or app-version dependent and must be verified before implementation.

## Technical Constraints

- Keep dated design/spec paths canonical: `docs/design/YYYY-MM-DD-feature/design.md` and `docs/specs/YYYY-MM-DD-feature/`.
- Use existing verifiers where possible and extend them deliberately when adding new surfaces.
- Keep docs and task files ASCII-compatible unless existing file content requires otherwise.
- Avoid same-wave tasks modifying the same files.
- Use `apply_patch` or normal editor-safe edits; do not generate specs or code by ad hoc shell writes.
