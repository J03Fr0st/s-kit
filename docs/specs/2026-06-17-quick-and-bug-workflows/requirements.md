# Requirements: Quick and Bug Workflows

## Summary

`s-kit` has a deliberately rigorous full-feature workflow, but clear one-file or few-file edits need a lighter lane, and defect work needs a sharper route that composes the existing debugging, TDD, verification, and review skills. This feature adds one new `quick-change` skill and documents the bug-fix lane as a workflow contract rather than creating a second debugging methodology.

## Goals

- Add a first-class `quick-change` skill for low-blast-radius work with clear success criteria and direct verification.
- Update `using-s-kit` routing so quick changes, bug fixes, full features, and hotfixes have distinct criteria.
- Keep quick changes out of dated design/spec folders unless they reveal ambiguity or broader scope.
- Tighten the bug lane around `systematic-debugging -> test-driven-development -> verification-before-completion`.
- Require escalation from quick work or bug work to brainstorming when scope, ownership, or architecture questions emerge.
- Document optional `.s-kit/debug/YYYY-MM-DD-{slug}.md` notes for nontrivial or long-running bug investigations.
- Update README workflow documentation so users and agents can choose the correct lane quickly.
- Update verifiers and trigger tests so the new skill and lane contracts are enforced.

## Non-Goals

- Do not introduce a workflow engine or persistent task runner.
- Do not create a new bug skill family.
- Do not change `build-feature` orchestration.
- Do not change shipping, PR, or commit workflow behavior.
- Do not migrate existing feature specs or dated design folders.
- Do not add agents, MCP servers, or runtime dependencies for this feature.

## Acceptance Criteria

- [ ] `skills/quick-change/SKILL.md` exists and defines a small scoped workflow for quick changes.
- [ ] `quick-change` requires assumptions, success criteria, relevant file reads, scoped edits, and fresh verification.
- [ ] `quick-change` explicitly says not to create dated design/spec folders.
- [ ] `quick-change` routes behavior changes through `test-driven-development` when a correct test seam exists.
- [ ] `quick-change` escalates to `brainstorming` when ambiguity, ownership, architecture, or broad blast radius appears.
- [ ] `skills/using-s-kit/SKILL.md` documents quick-change, bug-fix, full-feature, and hotfix lanes with criteria.
- [ ] Bug-fix routing composes `systematic-debugging`, `test-driven-development`, and `verification-before-completion`.
- [ ] `skills/systematic-debugging/SKILL.md` includes an `s-kit Bug Lane Contract` section.
- [ ] Nontrivial bug investigations can use optional `.s-kit/debug/YYYY-MM-DD-{slug}.md` notes without making them mandatory for every bug.
- [ ] README lists the new quick workflow and clarifies that quick and bug lanes normally skip dated specs.
- [ ] `scripts/verify-skill-names.ps1` recognizes `quick-change` as canonical.
- [ ] `scripts/doctor.ps1` treats `quick-change` as a required packaged skill.
- [ ] `scripts/verify-workflow.ps1` checks the quick lane and bug lane composition.
- [ ] `scripts/verify-branding.ps1` ignores generated `graphify-out` content and intentional negative test assertions so `npm test` remains a meaningful gate.
- [ ] Skill-triggering tests select `quick-change` for small scoped change prompts.
- [ ] Existing bug/debug prompts continue selecting `systematic-debugging`.
- [ ] `npm test` passes after implementation.

## Assumptions

- The current full-feature workflow remains `brainstorming -> plan-feature -> build-feature`.
- `systematic-debugging`, `test-driven-development`, `verification-before-completion`, and `requesting-code-review` remain the canonical bug-fix support skills.
- The skill-triggering tests are the right place to encode prompt routing behavior.
- Pure docs or trivial nonbehavior quick changes may skip `requesting-code-review`, but complex bugs and workflow-sensitive changes require it.

## Technical Constraints

- Keep all new skill instructions plain Markdown under `skills/`.
- Preserve canonical skill names; do not add compatibility redirects for retired names.
- Keep changes surgical to routing, docs, verifiers, and trigger tests.
- Do not add external dependencies.
- Do not alter generated `graphify-out` content manually.
- After implementation changes, run `graphify update .` to keep the knowledge graph current.
