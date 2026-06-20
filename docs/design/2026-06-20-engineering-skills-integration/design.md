# Design: Engineering Skills Integration

## Context

Matt Pocock's engineering skills contain several practices that overlap with `s-kit`, but a few are worth adopting because they sharpen codebase language, architecture decisions, and design discovery before implementation. The current `s-kit` workflow already has dated design/spec artifacts, quick-change and bug lanes, review gates, verification, and delivery skills. Copying the upstream tree wholesale would create duplicate workflows and dilute the compact `s-kit` model.

This design integrates only the upstream practices that strengthen existing lanes without replacing them.

## Approved Approach

Add three supporting skills and wire them into the current workflow:

- `domain-modeling` for active glossary and ADR maintenance.
- `codebase-design` for deep-module architecture vocabulary.
- `prototype` for throwaway runnable design experiments.

Update existing skills and docs to route to those skills where they add leverage:

- `grill-with-docs` remains the domain-heavy interview entrypoint and delegates vocabulary/ADR mechanics to `domain-modeling`.
- `brainstorming` can detour through `prototype` when conversation alone cannot answer a design question.
- `test-driven-development` and `systematic-debugging` adopt the useful upstream emphasis on behavior-through-interface tests and tight red-capable feedback loops.
- `using-s-kit` and `README.md` document the new supporting skills without changing the core dated design/spec workflow.

## Alternatives Considered

- Copy the full upstream engineering skill tree - rejected because `ask-matt`, `implement`, `to-prd`, `to-issues`, `triage`, and setup skills duplicate or bypass `s-kit`'s dated design/spec workflow.
- Only merge upstream language into existing skills - rejected because domain modeling, codebase design, and prototyping are reusable concerns that should be independently discoverable.
- Build issue/PRD export now - rejected for this slice. `spec-to-issues` is still valuable, but it needs a separate design around `spec.json` metadata and idempotent issue sync.

## Architecture

The integration is documentation and workflow-surface only. No runtime package code is required.

New skill folders:

```text
skills/domain-modeling/SKILL.md
skills/domain-modeling/CONTEXT-FORMAT.md
skills/domain-modeling/ADR-FORMAT.md
skills/codebase-design/SKILL.md
skills/codebase-design/DEEPENING.md
skills/codebase-design/DESIGN-IT-TWICE.md
skills/prototype/SKILL.md
skills/prototype/LOGIC.md
skills/prototype/UI.md
```

Existing surfaces to update:

- `README.md` skill catalog and workflow description.
- `skills/using-s-kit/SKILL.md` lane routing.
- `skills/brainstorming/SKILL.md` optional prototype detour.
- `skills/grill-with-docs/SKILL.md` delegation to `domain-modeling`.
- `skills/test-driven-development/SKILL.md` behavior/interface language.
- `skills/systematic-debugging/SKILL.md` tighter feedback-loop language.
- Skill-name and workflow verification scripts/tests so the new skills are first-class and discoverable.

## Configuration and Inputs

No persisted runtime configuration is introduced.

Inputs are existing repo-local documentation surfaces:

- `CONTEXT.md` or `CONTEXT-MAP.md` when present.
- `docs/adr/` when present.
- Current `docs/design/YYYY-MM-DD-{feature-name}/design.md` and `docs/specs/YYYY-MM-DD-{feature-name}/` artifacts.

The new skills create `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` only lazily when a resolved term or accepted ADR justifies it.

## Decisions

- Keep `brainstorming -> plan-feature -> build-feature` as the core feature path.
- Keep issue tracker workflows out of this slice.
- Make new skills concise and trigger-focused, not copied verbatim from upstream.
- Treat `prototype` as a design question tool, not a production implementation lane.
- Use tests and verifier updates as the deployment gate for new skills.

## Risks and Constraints

- The worktree already contains unrelated dirty files. Implementation must avoid reverting or sweeping those changes into this feature.
- Skill descriptions must avoid summarizing whole workflows so agents still read the full skill body.
- Adding skills requires updating name/catalog verifiers and trigger tests, or `npm test` will fail.
- Generated `graphify-out/` files are expected to change after code/docs edits; refresh them after implementation.

## Verification Strategy

- Add trigger prompts for `domain-modeling`, `codebase-design`, and `prototype`.
- Update explicit skill-request tests if the suite enumerates skills.
- Run targeted verification scripts for skill names/workflow invariants.
- Run `npm test`.
- Run `graphify update .` after modifications to keep graph artifacts current.
