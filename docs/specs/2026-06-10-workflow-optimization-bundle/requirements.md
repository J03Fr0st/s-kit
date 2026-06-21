# Requirements: Workflow Optimization Bundle

## Summary

s-kit's core pipeline (`brainstorming → plan-feature → build-feature`) has accreted weight over recent releases — a simplification pass, two-stage review, and a Phase risk preflight — without a matching pass to remove redundancy. A fresh full review found four problem clusters: per-Phase prompt bloat (full `design.md` + `requirements.md` injected into every agent, the Phase Risk Preflight copied into 5 prompt contexts, unbounded completed-task summaries, a final integration review that re-injects everything), no small-change lane (one-line bugfixes route through the full dated design/spec ceremony), internal inconsistencies (three bundled agents never invoked by any skill, the read-only review contract duplicated verbatim in 3 files, execution-only statuses unannotated, no hooks sync check, a session-start hook that injects the full using-s-kit skill on every startup/resume/clear/compact), and missing handoff validations (no design-path check before spec creation, no baseline verification before coder dispatch, undefined simplifier `no-op` semantics, no task-reopen procedure).

This feature implements a balanced optimization bundle: a conservative token diet for build-feature prompts, routing-rule lanes for small changes, wiring for the three orphaned agents, dedupe of the read-only contract, a hooks sync verification script, a slimmed session-start hook, and the missing handoff validations. The two-stage review gate and the dated-artifact model are untouched.

## Goals

- Cut per-Phase prompt token cost in `build-feature` without weakening the spec-compliance → code-quality review gate.
- Give small changes (bugfix, refactor/docs, hotfix) a documented lane that skips the dated spec folder.
- Make every bundled agent reachable from the workflow: `s-kit-codebase-mapper` and `s-kit-pattern-mapper` as optional planning-side steps, `s-kit-security-auditor` on a risky-surface trigger in build-feature.
- Single-source the read-only review contract and verify it by reference, not by triplicated text.
- Detect hooks-file and packaging-version drift in `npm test`.
- Stop re-injecting the full using-s-kit skill at every session boundary.
- Fail fast on missing design files, failing baselines, ambiguous `no-op` results, and reopened completed tasks.

## Non-Goals

- Collapsing the two-stage review into one pass, or inline self-review for any lane.
- Mapping Phases onto native Agent Teams.
- Spec-to-issues export, run reports, or any dashboard/UI.
- Removing any of the seven `allowedTaskStatuses` values (manifest compatibility is preserved).
- New skills — the small-change lane is routing documentation only.
- Changing the dated `docs/design` / `docs/specs` artifact model.

## Acceptance Criteria

- [ ] Coder prompts contain a design digest, not full `design.md`/`requirements.md`, and no Phase Risk Preflight; reviewers and fixers still receive the preflight; reviewers still receive full design and requirements.
- [ ] Completed-task summaries are specified as one line per task in coder, simplifier, and review prompts.
- [ ] The final integration review is project verification plus one diff-scoped code-quality review; per-Phase spec-compliance verdicts are the compliance record.
- [ ] `using-s-kit` documents four lanes (full feature, bug fix, refactor/docs, hotfix) with criteria, paths, and a boundary rule; `brainstorming` reroutes lane-matching requests.
- [ ] `brainstorming` offers `s-kit-codebase-mapper`, `plan-feature` offers `s-kit-pattern-mapper`, and `build-feature` dispatches `s-kit-security-auditor` when a Phase touches risky surfaces.
- [ ] The read-only review contract lives in one shared reference file; the two reviewer agents and the review prompt template reference it; `verify-workflow.ps1` checks the shared file and the references.
- [ ] `scripts/verify-hooks.ps1` exists, compares `hooks.json` with `hooks-cursor.json`, asserts packaging version consistency, and runs as part of `npm test`.
- [ ] `hooks/session-start` injects a short pointer instead of the full using-s-kit SKILL.md; the legacy warning still appears only when `~/.config/s-kit/skills` exists.
- [ ] `plan-feature` hard-stops when the design file is missing at the derived path; `build-feature` runs a baseline verification before dispatching Phase 1 and asks the user how to proceed on failure.
- [ ] Simplifier `no-op` requires Final Verification evidence or the task becomes `done-with-concerns`; reopening a `complete` task reverts transitive dependents to `blocked` with a log entry.
- [ ] `npm test` passes after every task.

## Assumptions

- Task files produced by `plan-feature` are genuinely self-contained (this is already a stated invariant), so coders do not need full design/requirements text.
- `scripts/doctor.ps1` already validates version consistency via `.version-bump.json`; `verify-hooks.ps1` reuses the same declared-files mechanism rather than inventing a second one.
- The skills shipped in this repo (`skills/…`) are the source files for all six packaging surfaces, so skill/template edits propagate identically; only hooks/packaging metadata differ per host.

## Technical Constraints

- All changes are markdown skills/templates, agent definitions, PowerShell scripts, one bash hook script, and `package.json` — no runtime code, no new dependencies.
- `verify-workflow.ps1` enforces literal required-text invariants on `skills/build-feature/SKILL.md` and the prompt templates. Any task that edits those files must keep the script and the files in agreement within the same task, so `npm test` stays green after every task.
- `allowedTaskStatuses` keeps all 7 values; `done-with-concerns` and `review-failed` are annotated as execution-only.
- The two-stage review gate (spec compliance before code quality) must remain intact in all edits.
