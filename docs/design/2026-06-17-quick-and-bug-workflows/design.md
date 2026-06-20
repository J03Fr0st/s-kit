# Design: Quick and Bug Workflows

Status: Approved 2026-06-17 (current-conversation approval; grill-me not run).

## Context

`s-kit` has a strong full-feature workflow:

```text
brainstorming -> plan-feature -> build-feature -> verification/review -> ship-it
```

That workflow is intentionally rigorous for behavior-changing feature work, but it is too heavy for clear one-file or few-file changes and for small reproducible bugs. Current routing in `skills/using-s-kit/SKILL.md` already names a bug-fix lane, and `docs/comparable-project-enhancements.md` already identifies scale-adaptive ceremony as a good fit. The missing piece is a crisp, reusable design for:

- a quick workflow that is fast without becoming casual or unverifiable
- a bug workflow that composes existing debugging, TDD, verification, and review skills without inventing a second debugging methodology

This design is for `s-kit` itself, informed by the deep dive into cached tooling repositories under `D:\Source\forgekit\.forgekit\cache\tooling-repos`.

## Approved Approach

Add an explicit `quick-change` skill for small scoped changes, and tighten the existing bug lane as a documented composition of existing skills.

The selected model is:

```text
Quick change:
using-s-kit -> quick-change -> verification-before-completion -> requesting-code-review when risk warrants

Bug fix:
using-s-kit -> systematic-debugging -> test-driven-development -> verification-before-completion -> requesting-code-review when complex

Full feature:
using-s-kit -> brainstorming -> plan-feature -> build-feature -> verification/review -> ship-it
```

The design keeps `s-kit` compact by adding one small skill only where a real gap exists. The bug workflow stays a lane contract, not a new bug skill family, because `systematic-debugging` and `test-driven-development` already contain the core discipline.

## Alternatives Considered

- Keep current routing only, no new skill - not selected because "small scoped work" currently has no dedicated reusable instructions, which leaves agents to improvise the amount of ceremony.
- Put quick workflow logic inside `brainstorming` - not selected because tiny changes should avoid entering the design/spec path in the first place.
- Create a full bug workflow skill with its own artifacts - not selected because it would duplicate `systematic-debugging` and risk diverging from the existing root-cause-first discipline.
- Adopt a Spec Kit or GSD-style executable workflow engine - not selected because `s-kit` is a compact skill kit; persisted state is useful selectively, but a workflow runner would be a product expansion.

## Architecture

### Routing

`skills/using-s-kit/SKILL.md` remains the router. Its lane table should distinguish:

| Lane | Criteria | Path |
|---|---|---|
| Quick change | Clear requested outcome, low blast radius, expected change around 1-3 files, no design decision, direct verification available | `quick-change -> verification-before-completion` |
| Bug fix | Reported wrong behavior, failed command, failing test, regression, or production issue | `systematic-debugging -> test-driven-development -> verification-before-completion` |
| Full feature | New behavior, architectural choice, ambiguous scope, multi-step work, or broad file ownership | `brainstorming -> plan-feature -> build-feature` |
| Hotfix | Urgent production bug | bug-fix lane with user-approved expedited review and a follow-up note for skipped review depth |

Boundary rules:

- If a quick change reveals design questions, unclear ownership, or wider blast radius, stop and route to `brainstorming`.
- If a quick change is actually broken behavior, route to the bug lane even when the expected code diff is small.
- If a bug fix grows beyond roughly 3 files or requires architecture decisions, stop and route to `brainstorming` or an architecture-focused skill after documenting the debugging evidence.

### New `quick-change` Skill

Create `skills/quick-change/SKILL.md`.

The skill should be small and rigid enough to prevent common mistakes:

1. State assumptions and success criteria.
2. Inspect `git status --short`.
3. Read the relevant files before editing.
4. Name the verification command before editing when knowable.
5. Make the smallest scoped change.
6. Use `test-driven-development` first if behavior changes and a correct test seam exists.
7. Remove only unused code introduced by this change.
8. Run `verification-before-completion`.
9. Use `requesting-code-review` when behavior changed, the diff is nontrivial, or the area is security or workflow sensitive.
10. Report files changed, verification evidence, review status if used, and residual risk.

The skill must explicitly say not to create dated design/spec folders.

### Bug Lane Tightening

`skills/systematic-debugging/SKILL.md` already has the important mechanics:

- no fixes without root-cause investigation
- reproduce consistently
- gather evidence across component boundaries
- form and test hypotheses
- create a failing test case before fixing
- implement one fix at a time
- stop after repeated failed fixes and question architecture

The implementation should add a short "s-kit Bug Lane Contract" section that makes the handoff explicit:

```text
systematic-debugging establishes root cause and the feedback loop.
test-driven-development turns the minimized repro into a failing regression check when a correct seam exists.
verification-before-completion reruns the original symptom and the regression check.
requesting-code-review is required for complex bugs, workflow-sensitive areas, security-sensitive areas, or any fix with broad impact.
```

For nontrivial or long-running bugs, the skill should recommend a lightweight local debug note:

```text
.s-kit/debug/YYYY-MM-DD-{slug}.md
```

The note is optional and local to the target project. It records symptoms, repro command, evidence, hypotheses, current focus, root cause, fix summary, regression check, and remaining risk. This borrows the resumability pattern from GSD without making `s-kit` depend on a workflow engine.

### Documentation and Triggering

Update:

- `README.md` skills/workflow section to list `quick-change` and clarify when bug lane skips dated specs.
- `skills/using-s-kit/SKILL.md` lane table and examples.
- skill-triggering tests so prompts like "make this small docs tweak" or "quick one-file change" select `quick-change`, while prompts like "this test is failing" or "debug this" still select `systematic-debugging`.
- explicit-skill request tests if the existing test layout expects one file per skill.

### Verification Integration

Update existing verification rather than adding a large new verifier:

- `scripts/verify-skill-names.ps1` should accept `quick-change` as a canonical skill and continue rejecting old redirected names.
- `scripts/verify-workflow.ps1` should check that `using-s-kit` mentions the quick-change lane and that the bug lane still composes `systematic-debugging`, `test-driven-development`, and `verification-before-completion`.
- `npm test` remains the project-level verification command.

## Configuration and Inputs

No secrets or external services are required.

Stored files:

- `skills/quick-change/SKILL.md` is a new first-class skill.
- Optional debug notes live in `.s-kit/debug/` in the target project, only when the bug investigation needs resumable state.
- Test prompt files under `tests/skill-triggering/prompts/` and possibly `tests/explicit-skill-requests/prompts/` encode routing expectations.

Runtime inputs:

- The user's request determines the lane.
- The repository's local test, lint, build, or repro commands determine verification.
- User approval is required only when a hotfix intentionally skips normal review depth or when a lane boundary is crossed.

Defaults:

- Quick changes do not create dated design/spec folders.
- Bug fixes do not create dated design/spec folders unless they grow into design work.
- Review is optional for pure docs or trivial nonbehavior quick changes, but required for complex bugs and sensitive surfaces.

## Decisions

- Add exactly one new skill: `quick-change`.
- Keep bug workflow as a routed composition of existing skills, not a new top-level skill.
- Preserve the full dated design/spec/build workflow for ambiguous, architectural, or multi-step work.
- Use optional local debug notes for resumability instead of introducing a workflow engine.
- Keep verification centralized through `verification-before-completion` and `npm test`.
- Make lane escalation explicit: quick to brainstorming, bug to brainstorming or architecture review when scope expands.

## Risks and Constraints

- Lane misuse could let agents classify feature work as quick work. Mitigation: strict criteria and an escalation rule in both `using-s-kit` and `quick-change`.
- A new `quick-change` skill increases catalog surface. Mitigation: keep it narrow and route-only; do not add agents or templates unless implementation evidence shows a need.
- Optional debug notes may become stale. Mitigation: use them only for nontrivial investigations and treat the repro command plus verification evidence as the source of truth.
- Bug fixes without a good test seam can still happen. Mitigation: require documentation of the missing seam and rerun the original symptom loop before completion claims.

## Verification Strategy

Implementation is correct when:

- `npm test` passes.
- `scripts/verify-skill-names.ps1` recognizes `quick-change` and still rejects retired workflow names.
- `scripts/verify-workflow.ps1` enforces that `using-s-kit` documents the quick lane and bug lane composition.
- Skill-triggering tests cover quick-change prompts and preserve systematic-debugging prompts.
- Manual read-through confirms `quick-change` does not create dated spec artifacts and that bug routing still uses root-cause-first debugging before TDD and verification.
