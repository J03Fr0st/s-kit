# Design: Workflow Optimization Bundle

Status: Approved 2026-06-10 (current-conversation approval; grill-me offered and declined).

## Context

s-kit's core pipeline (`brainstorming → plan-feature → build-feature`) has accreted weight over recent releases — a simplification pass, two-stage review, and a Phase risk preflight — without a matching pass to remove redundancy. A fresh full review (two read-only deep-dive agents over skills, prompt templates, agents, scripts, hooks, and packaging surfaces) found four problem clusters:

1. **Per-Phase prompt bloat**: full `design.md` + `requirements.md` injected into every coder, simplifier, and reviewer; the Phase Risk Preflight copied into 5 prompt contexts; completed-task summaries growing unboundedly across Phases; the final integration review re-injecting everything.
2. **No small-change lane**: every change, including one-line bugfixes, routes through the full dated design/spec ceremony.
3. **Internal inconsistencies**: three bundled agents (`s-kit-codebase-mapper`, `s-kit-pattern-mapper`, `s-kit-security-auditor`) never invoked by any skill; the read-only review contract duplicated verbatim in 3 files; execution-only statuses unannotated in plan-feature; no sync check between `hooks.json` and `hooks-cursor.json`; the session-start hook injecting the full using-s-kit skill on every startup/resume/clear/compact.
4. **Missing handoff validations**: no design-path existence check before spec creation; no baseline verification before coder dispatch; undefined simplifier `no-op` verification semantics; no procedure for reopening a completed task with dependents.

This change optimizes the workflow without touching the two-stage review gate or the dated-artifact model.

**Out of scope:** collapsing review stages, inline self-review, Agent Teams mapping, spec-to-issues export, run reports. These stay in the research backlog (`docs/future-development-research.md`, `docs/comparable-project-enhancements.md`).

## Approved Approach

A balanced optimization bundle covering all four themes with a **conservative token diet**: prompt-template restructuring and routing/validation additions only — no architecture change, and the spec-compliance + code-quality review gate is untouched. Chosen because it captures most of the measurable per-Phase savings, resolves every inconsistency the review found, and defers the speed-vs-rigor question (backlog Rec 8) until run data exists to decide with.

## Alternatives Considered

- **Aggressive review-cost cut** (collapse two-stage review into one pass for single-task Phases; inline self-review for the small lane, per Superpowers v5.0.x) — not selected: it weakens the two-stage gate the workflow was deliberately built around, and cutting review depth in the same release that adds other changes makes quality regressions hard to attribute.
- **Mechanical fixes only** (themes C + D, deferring the token diet and small-change lane) — not selected: it skips the two highest-value items.
- **Small-change lane as a new skill or as a size gate inside brainstorming** — not selected: a new skill grows the catalog s-kit keeps compact; a brainstorming size gate adds ceremony to tiny changes. Routing rules in `using-s-kit` were chosen instead.

## Architecture

Four themes, each landing in existing files plus two new files (`read-only-review-contract.md`, `verify-hooks.ps1`).

### Theme A — Prompt token diet (build-feature + references)

- **Coder prompts** (`skills/build-feature/references/coder-prompt-template.md`): drop full `{requirements}` and `{design}`. Replace with `{design_digest}` — a 10–20 line orchestrator-written digest of the design decisions relevant to the Phase (key contracts, naming, error-handling conventions). Task files remain the self-contained source of implementation detail (already guaranteed by plan-feature Step 6).
- **Preflight scope**: `{Phase_risk_preflight}` removed from coder and simplifier prompts; retained in spec-compliance review, code-quality review, and fix prompts. The preflight still lands in `implementation-log.md`; the orchestrator's design digest quotes any contract line that directly affects a coder's task.
- **Completed-task summaries**: capped at one line each (format: `task-NN-name: what was built; files created/modified`). Applies to coder, simplifier, and review prompts.
- **Review prompts** (`review-prompt-template.md`): keep full `design.md` + `requirements.md` (reviewers judge conformance) but drop full task-file content from `{task_summaries}` — replaced by each task's Acceptance Criteria + Verification Plan sections plus coder/simplifier completion summaries.
- **Final integration review** (`build-feature/SKILL.md` Step 9): replaced by project-level verification plus one diff-scoped code-quality review over the full feature git range. Per-Phase spec-compliance verdicts already on record serve as compliance evidence; no re-injection of all task summaries.

### Theme B — Small-change lane (routing rules only)

`skills/using-s-kit/SKILL.md` gains an explicit lane table:

| Lane | Criteria | Path |
|---|---|---|
| Full feature | New behavior, multi-file, or any change needing design decisions | brainstorming → plan-feature → build-feature |
| Bug fix | Defect with reproducible wrong behavior, ≤ ~3 files | systematic-debugging → test-driven-development → verification-before-completion |
| Refactor / docs | No behavior change | refactor or direct edit → verification-before-completion |
| Hotfix | Urgent production defect | bug-fix lane with user-approved expedited review; follow-up logged |

Small-lane changes skip the dated spec folder; the audit trail is the commit plus verification evidence the existing skills already require. Boundary rule: if a small-lane change sprouts design questions or exceeds the file budget, stop and route to brainstorming. `brainstorming/SKILL.md` gets a matching note: if a request matches a small lane, say so and route instead of starting a design.

### Theme C — Consistency hardening

- **Wire orphaned agents:** `brainstorming` Step 1 offers `s-kit-codebase-mapper` for unfamiliar repos; `plan-feature` offers `s-kit-pattern-mapper` before task decomposition (convention evidence for task files); `build-feature` Step 3A flags risky surfaces (secrets, shell, filesystem writes, auth, network, user input — the auditor's existing trigger list) and, when flagged, dispatches `s-kit-security-auditor` read-only alongside the code-quality review.
- **Read-only contract dedupe:** extract the contract to `skills/build-feature/references/read-only-review-contract.md`; `agents/s-kit-code-reviewer.md`, `agents/s-kit-spec-reviewer.md`, and `review-prompt-template.md` reference it; `scripts/verify-workflow.ps1` checks the shared file exists and is referenced rather than checking triplicated text.
- **Status annotation:** `plan-feature` keeps the full 7-value `allowedTaskStatuses` list (build-feature's preflight requires it in `spec.json`) but annotates `done-with-concerns` / `review-failed` as execution-only statuses never assigned during planning.
- **Hooks/packaging sync:** new `scripts/verify-hooks.ps1` comparing `hooks.json` vs `hooks-cursor.json` (modulo documented platform differences) and asserting version fields match across the six packaging surfaces; wired into `npm test`.
- **Session-start slimming:** `hooks/session-start` stops injecting the full using-s-kit SKILL.md; it injects a ~3-line pointer ("s-kit workflow active; route via the using-s-kit skill") and emits the legacy-path warning only when the legacy directory exists.

### Theme D — Handoff robustness

- **plan-feature Step 1:** hard check that the design file exists at the derived `docs/design/YYYY-MM-DD-{feature-name}/design.md` path before any spec file is written; on failure, report the expected path and stop.
- **build-feature Step 1:** after the spec preflight, run the project's baseline verification (test/lint commands from `spec.json` or project config). If failing, report and ask the user: proceed (failures attributed to baseline in the log) or stop.
- **Simplifier `no-op` semantics:** a `no-op` must still run each task's Final Verification command and report output; otherwise the task is `done-with-concerns`, not `complete`.
- **Task-reopen cascade:** documented procedure — reopening a `complete` task reverts all transitive dependents to `blocked`, with a dated `implementation-log.md` entry, before any re-dispatch.

## Configuration and Inputs

- No stored configuration or secrets. All changes are markdown skills/templates, agent definitions, PowerShell verification scripts, and the session-start hook script.
- `{design_digest}` is composed per-Phase by the orchestrator at dispatch time from the approved design — not persisted as a separate artifact.
- The baseline-verification commands in build-feature Step 1 come from `spec.json.tasks[].verificationCommands` plus any project-level test/lint commands already referenced by the spec; no new config field.
- `verify-hooks.ps1` takes no arguments; platform-specific allowed differences between the two hooks files are documented inline in the script.

## Decisions

- Keep the two-stage review gate intact; the token diet touches prompt composition only.
- Coders receive a design digest, not the full design; reviewers keep the full design and requirements.
- Phase Risk Preflight is a reviewer/fixer artifact, not a coder/simplifier artifact.
- Small-change lane is routing documentation in `using-s-kit`, not a new skill and not a brainstorming size gate.
- All three orphaned agents get wired in (mappers into planning-side skills as optional steps; security auditor into build-feature on risky-surface trigger) rather than removed.
- `allowedTaskStatuses` stays at 7 values for manifest compatibility; the execution-only statuses are annotated, not removed.
- Final integration review is verification + diff-scoped code-quality review; per-Phase spec-compliance verdicts are the compliance record.

## Risks and Constraints

- **Coder quality without full design text** — mitigated by the design digest plus self-contained task files; reviewers still hold the full design, so deviations are caught at the existing gate.
- **Lane misrouting** (a "bug fix" that is really a feature) — mitigated by the explicit boundary rule and brainstorming's reroute note.
- **Multi-host drift** — skill/template changes ship identically across all six packaging surfaces since they share the same files; only hooks/packaging metadata differ, now covered by `verify-hooks.ps1`.
- **Orchestrator-authored digest quality** — the digest is a new judgment task for the orchestrator; the design specifies its required content (contracts, naming, error-handling conventions relevant to the Phase) to keep it bounded.

## Verification Strategy

- `npm test` (existing branding/assets/agents/naming/workflow gates) passes throughout implementation.
- `scripts/verify-workflow.ps1` extended: the shared read-only contract file exists and is referenced by both reviewer agents and the review template; `{design_digest}` present in the coder template; `{Phase_risk_preflight}` absent from coder and simplifier templates.
- New `scripts/verify-hooks.ps1` wired into `npm test`.
- Manual smoke test: run a 2-task sample spec through build-feature on this repo and confirm the slimmed prompts, the security-auditor trigger on a risky surface, and the baseline check behave as specified.
