# Requirements: Build Feature Risk Preflight

## Summary

`build-feature` currently runs coder agents, simplification, spec-compliance review, code-quality review, and targeted fix loops per Phase. That is the right default for multi-task feature work, but it can become slow when a Phase has one integration boundary whose risks are discovered one issue at a time.

This feature adds a read-only Phase risk preflight before coder dispatch. The preflight records likely shared contracts for the current Phase and threads that context into coder, simplifier, and reviewer prompts. It also adds complete punch-list behavior when repeated review failures clearly cluster around the same boundary.

The expected outcome is fewer serial review/fix loops for integration-heavy Phases without removing independent review, changing task statuses, or adding new agents.

## Goals

- Add a Phase Risk Preflight step to `build-feature` before coder dispatch.
- Include preflight context in coder, simplifier, review, and fix-loop guidance where relevant.
- Add complete punch-list mode for repeated same-boundary review failures.
- Allow trivial targeted fixes to produce an explicit no-op simplification result instead of encouraging unnecessary cleanup.
- Preserve the existing `brainstorming -> plan-feature -> build-feature -> verification/review -> ship` workflow.

## Non-Goals

- Add a new skill or agent.
- Add a dashboard or persistent cross-project pattern library.
- Add a fast lane/full lane workflow split.
- Remove spec-compliance or code-quality review gates.
- Add a new task status.
- Change the dated `docs/design` and `docs/specs` artifact structure.

## Acceptance Criteria

- [ ] `build-feature` documents when and how Phase Risk Preflight runs.
- [ ] Coder prompts receive preflight context as explicit implementation risk context.
- [ ] Review prompts require reviewers to use preflight context as part of the review scope.
- [ ] Fix-loop instructions define when repeated same-boundary failures trigger complete punch-list review.
- [ ] Simplification guidance permits an explicit no-op result for trivial targeted fixes.
- [ ] Workflow verification checks protect the new contract.
- [ ] Existing workflow, naming, and package verification commands pass.

## Assumptions

- The preflight can be expressed as orchestration guidance and prompt context; no executable analyzer is required for the first version.
- Existing review agents can perform complete punch-list review when prompted with a concrete boundary and scope.
- Workflow checks can validate required text without enforcing brittle full prompt content.
- The `pubg-ts` observability run is a representative example but should not be hard-coded into the workflow.

## Technical Constraints

- Keep changes scoped to `build-feature` workflow surfaces and verification scripts.
- Keep all edits ASCII.
- Do not introduce new task status values.
- Preserve read-only review safety language.
- Keep the preflight tied to the current Phase's files, tasks, design, completed task summaries, and verification commands.
- Use existing `npm test`, `verify:workflow`, and `verify:naming` checks for validation.
