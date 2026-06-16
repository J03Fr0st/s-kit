# Design: Workflow Lessons Hardening

## Context

The Forgekit research cache under `D:\Source\forgekit\.forgekit` contains local copies of comparable agent workflow tools. The useful lesson is not to copy their large catalogs or runtimes, but to pull small workflow-hardening patterns into `s-kit`: stronger packaging contracts, semantic spec review, explicit run-state language, smoke checks as contracts, and clearer writing-quality expectations for agent-facing docs.

This work is for `s-kit` maintainers and agents using the dated design/spec/build flow. It should improve confidence without changing the core workflow shape.

## Approved Approach

Implement one bounded workflow-hardening feature with five slices:

1. Expand doctor and verification language around cross-harness packaging contracts.
2. Make the semantic `s-kit-spec-reviewer` gate explicit after `plan-feature`.
3. Add lightweight run-state semantics to spec artifacts and execution guidance.
4. Document named smoke checks as contracts instead of relying on vague "run tests" wording.
5. Add writing-quality guardrails for skill and prompt prose.

This approach keeps the canonical `brainstorming -> plan-feature -> build-feature -> verification/review -> ship-it` flow intact. It improves the existing text-first surfaces and scripts rather than adding a dashboard, a workflow engine, or persistent cross-project learning.

## Alternatives Considered

- Single large implementation pass - fastest, but it would blur unrelated concerns and make review harder.
- Separate specs for each lesson - cleaner isolation, but too much ceremony for tightly related workflow hardening.
- Copy comparable-tool runtime assets - rejected because it would bloat `s-kit` and violate the compact, host-native design.

## Architecture

The changes stay in existing ownership boundaries:

- `scripts/doctor.ps1` remains the primary packaging confidence check.
- `skills/plan-feature/SKILL.md` owns post-spec creation guidance before implementation.
- `skills/plan-feature/references/*` owns generated spec artifact shape.
- `skills/build-feature/SKILL.md` owns runtime execution, resume, and review behavior.
- `agents/s-kit-spec-reviewer.md` owns semantic spec review criteria.
- `README.md` and `docs/playbooks/*` surface named smoke checks and writing-quality expectations.

No new command framework, YAML workflow runner, dashboard, or cached external tool dependency will be introduced.

## Configuration and Inputs

No runtime configuration or secrets are added.

Inputs are the current repository files, existing plugin manifests, generated design/spec artifacts, and the already-copied Forgekit research cache used as background evidence. No implementation should read or depend on that cache at runtime.

## Decisions

- Keep all work text-first and script-backed.
- Treat packaging surfaces as contracts that doctor can validate.
- Use `s-kit-spec-reviewer` as the semantic gate; do not create a new reviewer.
- Add run-state semantics to existing `spec.json` and `implementation-log.md` conventions instead of adding a workflow database.
- Make writing-quality checks human-readable first; avoid brittle natural-language linting.

## Risks and Constraints

- `verify-workflow.ps1` has exact text checks for several workflow surfaces, so edits must preserve current required phrases while adding new ones.
- `scripts/doctor.ps1` should stay deterministic and local; it should not require network access or installed external harnesses.
- Writing-quality guardrails must not become a subjective blocker that rejects clear technical prose.
- The repository currently expects compact docs and narrow changes; avoid broad rewrites.

## Verification Strategy

Use targeted and project-level verification:

- `npm run verify:workflow`
- `npm run verify:agents`
- `npm run verify:assets`
- `npm run verify:naming`
- `npm run doctor`
- `npm test`
- `graphify update .` after code/doc changes to refresh the knowledge graph
