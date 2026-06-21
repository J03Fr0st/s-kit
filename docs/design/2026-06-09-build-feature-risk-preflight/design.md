# Design: Build Feature Risk Preflight

## Context

`build-feature` is intentionally rigorous: it dispatches task agents Phase by Phase, runs simplification, then runs spec-compliance and code-quality review before accepting a Phase. That rigor is useful, but the current loop can become slow when one integration boundary produces several serial discoveries.

The triggering example is `D:\Source\pubg-ts\docs\specs\2026-06-09-architecture-deepening\implementation-log.md`. Phase 2 repeatedly cycled through issues that all belonged to the same Node/browser observability boundary: compatibility entrypoints, singleton type shape, default imports, module-load timers, open handles, and browser package mappings. The workflow found those issues one at a time through normal review/fix cycles.

This design speeds up that flow without weakening the default review model. It adds a pre-Phase risk preflight and changes repeat-failure behavior so a risky boundary gets one complete punch list instead of a chain of narrow discoveries.

## Approved Approach

Add a lightweight "Phase Risk Preflight" step to `build-feature` after Phase preparation and before coder dispatch.

The preflight is read-only. It derives likely integration risks from the approved design, requirements, current Phase task files, `spec.json` file ownership, completed task summaries, and verification commands. It records shared contracts that coder, simplifier, and reviewer prompts must consider during that Phase.

If a Phase fails review more than once in the same boundary, the workflow switches from another narrow fix cycle to a complete punch-list review for that boundary. The next reviewer is asked to inspect the whole affected boundary and return all blocking issues together. Fix agents then address that complete list before the normal review gates resume.

This keeps `build-feature` rigorous for feature work while reducing avoidable churn in integration-heavy Phases.

## Alternatives Considered

- Add a fast lane/full lane split - Useful for small changes, but broader than this problem. It would not directly fix repeated same-boundary review churn in full feature specs.
- Replace subagent review with inline self-review - Faster, but it weakens the independent review property that makes `build-feature` valuable for multi-task work.
- Raise or remove the three-cycle cap - This gives the workflow more time to churn instead of helping it discover boundary issues earlier.

## Architecture

The change lands in the existing `build-feature` surfaces rather than introducing a new skill or agent.

Primary surfaces:

- `skills/build-feature/SKILL.md`
- `skills/build-feature/references/coder-prompt-template.md`
- `skills/build-feature/references/review-prompt-template.md`
- `skills/build-feature/references/fix-prompt-template.md`, only if fix prompts need the punch-list context explicitly

The preflight becomes a new build-feature orchestration concept:

1. Load and validate the spec as today.
2. Determine the current Phase as today.
3. Prepare Phase tasks and check dependencies/file overlap as today.
4. Run Phase Risk Preflight.
5. Dispatch coder agents with the preflight included.
6. Collect coder results as today.
7. Run simplification as today, using the preflight as boundary context.
8. Run spec-compliance and code-quality review as today, with the preflight included in review scope.
9. If review failures repeat in the same boundary, request a complete punch list before another fix loop.

The preflight should identify likely shared contracts, not prove correctness. Examples:

- Public exports and compatibility entrypoints.
- Browser/Node or platform-specific substitutions.
- Runtime side effects at module import time.
- Timers, handles, cleanup, and process lifetime behavior.
- Generated artifacts and package metadata.
- Cross-task shared types or constructors.
- Auth, filesystem, shell, network, or security-sensitive boundaries.
- Verification commands that should be grouped because one command only proves part of the boundary.

The complete punch-list mode is triggered when review failures clearly cluster around the same boundary after at least one fix attempt. It does not replace the three-cycle cap; it makes the later cycles broader and more useful.

Post-fix simplification remains part of the workflow, but the design allows a no-op simplification result for trivial targeted fixes. The workflow should not encourage extra cleanup after a one-line fix unless the fix adds duplication, changes structure, or creates maintainability risk.

## Configuration and Inputs

No stored configuration is required.

The preflight uses existing inputs:

- `docs/design/YYYY-MM-DD-{feature-name}/design.md`
- `requirements.md`
- `spec.json`
- Current Phase task files
- Completed task summaries
- Current Phase verification commands
- Prior review/fix outcomes from `implementation-log.md` when resuming

No command-line flags are required for the initial design. If later implementation needs an override, the default should be "preflight enabled" for `build-feature` because it is read-only and cheap compared with coder/review loops.

## Decisions

- Keep this inside `build-feature`; do not add a new skill.
- Keep independent spec-compliance and code-quality review gates.
- Add risk context before coding, not only after review failures.
- Treat repeated same-boundary failures as a signal to broaden review scope.
- Keep the punch-list review read-only.
- Do not add persistent cross-project memory or a pattern library.
- Do not include the broader fast lane/full lane decision in this feature.

## Risks and Constraints

- The preflight can become generic noise if it lists every possible risk. It must stay tied to the current Phase's files, tasks, and design.
- A complete punch-list review can be more expensive than a narrow review. It should trigger only after repeat same-boundary failure, not after every first failure.
- The workflow should not overfit to the `pubg-ts` observability example. The risk categories must be general enough for other integration boundaries.
- Prompt changes may affect tests or verifier fixtures that assert workflow wording.
- The design must preserve the existing `brainstorming -> plan-feature -> build-feature` contract.

## Verification Strategy

Implementation should be verified through documentation/workflow checks rather than runtime app tests.

Expected checks:

- Existing `npm test` still passes.
- `scripts/verify-workflow.ps1` still passes.
- `scripts/verify-skill-names.ps1` still passes.
- Prompt templates contain explicit placeholders or instructions for Phase risk preflight context.
- `build-feature` instructions define when to create the preflight, how to pass it to coder/simplifier/review prompts, and when to trigger complete punch-list mode.
- Existing examples and status values remain compatible; no new task status is introduced.

Manual review should confirm the workflow stays concise and does not turn every Phase into a heavy architecture review.
