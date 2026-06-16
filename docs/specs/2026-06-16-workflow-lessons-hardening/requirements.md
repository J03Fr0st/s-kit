# Requirements: Workflow Lessons Hardening

## Summary

The feature incorporates lessons from comparable local tool copies into `s-kit` by strengthening existing workflow surfaces. The goal is better confidence and clearer agent behavior, not a larger orchestration system.

The implementation must preserve the current dated design/spec/build workflow and avoid adding dashboards, persistent learning stores, external runtime dependencies, or copied assets from the research cache.

## Goals

- Strengthen local packaging and cross-harness validation through `scripts/doctor.ps1`.
- Make semantic spec review an explicit post-`plan-feature`, pre-`build-feature` gate.
- Make task/spec run-state and resume semantics clearer in generated artifacts and build guidance.
- Treat named smoke checks as contracts for install/runtime confidence.
- Add lightweight writing-quality guardrails for skills, prompts, agents, and docs.

## Non-Goals

- Add a new YAML workflow engine.
- Add a dashboard or browser UI.
- Add persistent cross-project memory or learning.
- Copy runtime assets, commands, or plugin catalogs from the Forgekit cache.
- Replace the existing verifier scripts or dated artifact structure.

## Acceptance Criteria

- [ ] `doctor` validates stronger packaging contracts without requiring network access or external harness installation.
- [ ] `plan-feature` clearly routes specs through semantic review before implementation.
- [ ] Spec artifacts and `build-feature` language describe run-state/resume behavior using existing files.
- [ ] README and/or playbooks list named smoke checks with expected purpose.
- [ ] Agent-facing writing-quality guardrails exist and are referenced from verification or authoring guidance.
- [ ] Existing workflow, naming, asset, agent, doctor, and package tests pass or any unrelated blocker is documented.

## Assumptions

- The existing `s-kit-spec-reviewer` agent remains the right semantic review surface.
- `doctor.ps1` can remain deterministic and local.
- Natural-language quality should be guided by checklist text before adding a brittle linter.

## Technical Constraints

- Preserve existing exact phrases required by `scripts/verify-workflow.ps1`.
- Keep same-wave task file ownership non-overlapping.
- Avoid new runtime dependencies.
- Use existing package scripts where possible.
