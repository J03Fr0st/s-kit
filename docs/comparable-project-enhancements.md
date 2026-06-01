# Comparable-Project Enhancement Opportunities

Research date: 2026-05-31

This is the detailed, per-project companion to [future-development-research.md](future-development-research.md). That note gives the high-level position and a numbered recommendation list (Rec 1–8). This note goes project by project, extracts the **specific** pattern worth borrowing, and maps it to the exact `s-kit` surface it would land in — so each item is concrete enough to brainstorm or spec from.

How to read each entry:

- **Pattern** — what the comparable project actually does.
- **Enhancement for s-kit** — the concrete change.
- **Lands in** — the file(s)/skill(s) it touches.
- **Effort / Fit** — rough size and how well it fits the compact, dated-artifact ethos.
- **Rec** — links to the matching recommendation in `future-development-research.md` where one exists.

`s-kit`'s ethos still governs: stay compact, keep dated `docs/design` + `docs/specs` artifacts canonical, lean on host primitives over reimplementation, and don't grow a broad command/agent catalog. Some patterns below are explicitly *not* worth adopting; those are called out.

---

## GitHub Spec Kit

Repo: [github/spec-kit](https://github.com/github/spec-kit). Workflow: `/constitution → /specify → /clarify → /plan → /tasks → /analyze → /implement`.

### 1. A semantic cross-artifact check (`/analyze` equivalent)

- **Pattern:** `/speckit.analyze` is a read-only pass run after tasks and before implementation. It checks the spec, plan, tasks, and constitution for inconsistencies, duplications, ambiguities, and underspecified items, and produces a findings report without editing anything. Constitution conflicts are auto-marked CRITICAL. ([analyze.md](https://github.com/github/spec-kit/blob/main/templates/commands/analyze.md))
- **Enhancement for s-kit:** `s-kit` already has a *structural* preflight in `build-feature` Step 1 (manifest/README/task consistency, wave file-ownership, required headings via `verify-workflow.ps1`). Add a *semantic* layer: dispatch the existing `s-kit-spec-reviewer` as a gate between `plan-feature` and `build-feature` that checks the design ↔ requirements ↔ tasks for coverage gaps, duplicate scope, ambiguous acceptance criteria, and design decisions with no owning task. Read-only; emits findings, fixes nothing.
- **Lands in:** `skills/plan-feature/SKILL.md` (new final "analyze" step or handoff), `agents/s-kit-spec-reviewer.md`.
- **Effort / Fit:** Small–medium. Strong fit — `s-kit` already has the reviewer agent and the artifacts; this just formalizes a semantic gate the structural verifier can't cover.

### 2. `/clarify` as an explicit ambiguity-resolution step

- **Pattern:** `/clarify` resolves spec ambiguities *before* planning, so the agent and human share scope.
- **Enhancement for s-kit:** This already exists implicitly in `brainstorming` (one-question-at-a-time clarification + design approval). Worth making the "resolve open questions" beat explicit in the brainstorming checklist so designs don't reach `plan-feature` with unresolved ambiguities. Low-value-add; mostly already covered.
- **Lands in:** `skills/brainstorming/SKILL.md`.
- **Effort / Fit:** Trivial. Largely redundant — note and likely skip.

### 3. `/constitution` ↔ project principles

- **Pattern:** `/constitution` defines non-negotiable project rules every later command honors; `/analyze` marks constitution conflicts CRITICAL.
- **Enhancement for s-kit:** `s-kit` has the building blocks already — `grill-with-docs` pressures `CONTEXT.md` and `docs/adr/`. Make the design/spec workflow *reference* `CONTEXT.md` + ADRs as binding constraints during the semantic check (item 1), so a task that violates a documented decision is flagged.
- **Lands in:** `skills/grill-with-docs/SKILL.md`, the analyze step in item 1.
- **Effort / Fit:** Small. Good fit; reuses existing concepts rather than adding a new artifact type.

---

## claude-code-spec-workflow (Pimzino)

Repo: [Pimzino/claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow) (~3.8k★). Kiro-style `/spec-create → /spec-execute`, plus a bug-fix workflow and a live dashboard.

### 4. Steering documents (product / tech / structure context)

- **Pattern:** "Steering documents" capture durable product, technology, and structure context that every spec inherits.
- **Enhancement for s-kit:** Equivalent to a structured `CONTEXT.md`. If a repo lacks one, `grill-with-docs` could offer to scaffold a minimal product/tech/structure context file that designs then inherit — keeping terminology stable across features.
- **Lands in:** `skills/grill-with-docs/SKILL.md`.
- **Effort / Fit:** Small. Good fit; overlaps with item 3.

### 5. A dedicated bug-fix workflow

- **Pattern:** Separate `/bug-create → /bug-analyze → /bug-fix → /bug-verify` track for small fixes that don't deserve a full spec.
- **Enhancement for s-kit:** `s-kit` routes everything through `brainstorming → plan-feature → build-feature`, which is heavy for a one-line bug. `systematic-debugging` exists but isn't wired as a lightweight delivery path. Consider a documented "small change" lane (debug → fix → verify) that skips the dated spec folder. Overlaps with scale-adaptive ceremony (item 12, Rec 7).
- **Lands in:** `skills/using-s-kit/SKILL.md` (routing), `skills/systematic-debugging/SKILL.md`.
- **Effort / Fit:** Medium. Good fit but needs a design decision about when the lightweight lane is allowed.

### 6. Spec dashboard

- **Pattern:** `claude-spec-dashboard` renders spec/task status in a browser, with tunnel sharing.
- **Enhancement for s-kit:** **Do not adopt as a UI.** `s-kit` non-goals rule out a UI before text reports prove useful. The legitimate slice is local run reports (item 16, Rec 5) routed through native Monitors.
- **Lands in:** n/a.
- **Effort / Fit:** Skip per non-goals.

---

## ccpm (automazeio)

Repo: [automazeio/ccpm](https://github.com/automazeio/ccpm) (~8.2k★). GitHub Issues as source of truth + git worktrees for parallel agents; PRD → epic → task → issue with full traceability ("every line of code must trace back to a specification").

### 7. Spec-to-Issues with bidirectional traceability

- **Pattern:** Each task becomes a GitHub issue; epics and PRDs link down to issues and back up, so every change traces to a spec.
- **Enhancement for s-kit:** `spec.json` already holds task identity, waves, dependencies, file ownership, and verification commands — everything needed to mint issues. Add a dry-run export that creates one issue per task with links back to design/requirements/spec, preserving wave/deps/verification in the body and labels like `s-kit`, `wave-1`, `security-review`.
- **Lands in:** new `scripts/spec-to-issues.ps1` (+ dry-run), `skills/plan-feature/references/spec-json-template.json`.
- **Effort / Fit:** Medium. Excellent fit. **Rec 3.**

### 8. Per-task `metadata` for idempotent round-tripping

- **Pattern:** ccpm and Taskmaster both persist external identifiers so re-syncs don't duplicate issues.
- **Enhancement for s-kit:** Add an optional `metadata` object to each `spec.json` task to store the created issue number / external IDs, so re-export is idempotent and progress can sync back.
- **Lands in:** `skills/plan-feature/references/spec-json-template.json`, `scripts/verify-workflow.ps1` (allow but don't require the field).
- **Effort / Fit:** Small. Excellent fit. **Rec 3.**

### 9. Worktree-per-wave isolation

- **Pattern:** Agents work in isolated git worktrees so parallel streams don't collide.
- **Enhancement for s-kit:** `s-kit` already prevents same-wave file collisions via manifest ownership checks and has `using-git-worktrees`. Document the explicit option to run a wave's coder agents in a shared worktree for true isolation, then merge — strengthening the existing same-branch caveat in `build-feature`.
- **Lands in:** `skills/build-feature/SKILL.md` (Step 4 host-adapter notes), `skills/using-git-worktrees/SKILL.md`.
- **Effort / Fit:** Small (doc). Good fit.

---

## Citadel (SethGammon)

Repo: [SethGammon/Citadel](https://github.com/SethGammon/Citadel). Orchestration harness: four-tier routing (`/do`), campaign persistence across sessions, parallel agents in isolated worktrees, discovery relay between waves, lifecycle hooks, circuit breaker, self-improving pattern library.

### 10. Discovery relay between waves

- **Pattern:** Discoveries from one wave (e.g., an API-contract change) are explicitly relayed to later waves' agents.
- **Enhancement for s-kit:** `build-feature` already passes `{completed_tasks_summary}` forward, but it's a generic summary. Add a structured "discoveries / contract changes / gotchas" block to the coder/fix completion report that is explicitly threaded into later waves' prompts — so a wave-2 agent learns wave-1 changed a shared type.
- **Lands in:** `skills/build-feature/references/coder-prompt-template.md`, `fix-prompt-template.md`, `build-feature/SKILL.md` (Step 5 collect / Step 4 dispatch).
- **Effort / Fit:** Small–medium. Strong fit; sharpens an existing mechanism.

### 11. Campaign persistence / circuit breaker (already partly present)

- **Pattern:** Sessions resume where they left off; a circuit breaker stops runaway loops.
- **Enhancement for s-kit:** `build-feature` is *already* resumable (manifest-driven, picks up the first non-`complete` wave) and *already* has a circuit breaker (3 simplification/review cycles per wave). Citadel's "self-improving pattern library" (scoring outcomes, updating heuristics across runs) is **out of scope** — it adds persistent cross-project state `s-kit` deliberately avoids. Document that these are intentionally bounded, not missing.
- **Lands in:** n/a (note only).
- **Effort / Fit:** Skip the pattern library; affirm existing behavior.

---

## BMAD Method V6

Repo: [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD). Scale-adaptive intelligence, Skills Architecture, sub-agent inclusion, BMad Builder, Dev Loop Automation, installer/doctor.

### 12. Scale-adaptive ceremony

- **Pattern:** Workflow rigor scales to task size; a tiny change doesn't get the full process.
- **Enhancement for s-kit:** Let the workflow pick a lane by size — a one-file change can skip the dated spec folder and run a debug→fix→verify path (item 5), while a multi-task feature gets the full `plan-feature`/`build-feature` waves. Make the decision explicit and documented rather than implicit.
- **Lands in:** `skills/using-s-kit/SKILL.md`, `skills/brainstorming/SKILL.md`.
- **Effort / Fit:** Medium (design decision). Good fit. **Rec 7.**

### 13. Installer / doctor confidence

- **Pattern:** BMAD and SuperClaude both ship a `doctor`/help path that validates the install.
- **Enhancement for s-kit:** Add `scripts/doctor.ps1` validating version consistency across the six packaging surfaces (`.claude-plugin`, `.codex-plugin`, `.cursor-plugin`, `.opencode`, hooks, `gemini-extension.json`), required assets/skills/agents, absence of old paths (`skills/create-spec/`, `skills/implement-feature/`), and that `npm test` runs from a clean checkout.
- **Lands in:** new `scripts/doctor.ps1`, `package.json` script entry.
- **Effort / Fit:** Small–medium. Excellent fit. **Rec 2.**

---

## Taskmaster (eyaltoledano)

Repo: [eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master). Per-task JSON metadata, tagged/multi-context lists, orchestrator/executor/**checker** agents, MCP + CLI.

### 14. A dedicated "checker" verification agent

- **Pattern:** Taskmaster separates executor from a **checker** agent that validates task output.
- **Enhancement for s-kit:** `s-kit` already separates coder from a two-stage reviewer (spec-compliance + code-quality) plus a simplifier — arguably *more* rigorous than a single checker. The borrowable nuance: have the checker run the task's *own* `verificationCommands` and report RED/GREEN evidence independently of the coder's self-report, reducing "the coder said it passed" trust. Fold into the code-quality review's "run the listed verification commands" step (already present) by requiring independent re-run evidence.
- **Lands in:** `skills/build-feature/references/review-prompt-template.md`.
- **Effort / Fit:** Small. Good fit; mostly tightening existing wording.

### 15. Tagged / multi-context task lists

- **Pattern:** Separate isolated task lists per feature/branch/experiment.
- **Enhancement for s-kit:** Already covered by the dated `docs/specs/YYYY-MM-DD-{feature}/` folders — each feature is its own isolated context. No change needed; note as already-solved.
- **Lands in:** n/a.
- **Effort / Fit:** Skip — already solved by dated folders.

---

## Superpowers (obra)

Repo: [obra/superpowers](https://github.com/obra/superpowers). The lineage repo. v5.0.x replaced subagent review loops with **inline self-review** for speed and added a fast **Spec Self-Review checklist**.

### 16. Speed vs. rigor: a deliberate review-cost decision

- **Pattern:** Superpowers *removed* subagent review loops in favor of inline self-review (large run-time savings) plus a ~30-second Spec Self-Review checklist that catches several bugs cheaply.
- **Enhancement for s-kit:** This is a direct tension — `s-kit` recently went *heavier* (added a simplification pass and two-stage agent review). Options: (a) keep full agent review for multi-task features but allow an inline self-review lane for small/scale-adaptive changes (item 12); (b) add a fast pre-dispatch "spec self-review checklist" to `plan-feature` that catches obvious gaps in ~30s before any agent runs. Decide explicitly; don't drift.
- **Lands in:** `skills/plan-feature/SKILL.md` (self-review checklist), `skills/build-feature/SKILL.md` (lane selection).
- **Effort / Fit:** Medium (decision). High value. **Rec 8 (cost/quality trade-off).**

### 17. Keep tracking upstream process changes

- **Pattern:** Superpowers ships frequent methodology refinements (brainstorm server, Copilot tool mapping, SessionStart injection).
- **Enhancement for s-kit:** `s-kit` already mirrors much of this lineage. Keep a periodic upstream-compare playbook (item 18) so process improvements are reviewed deliberately, not copied wholesale.
- **Lands in:** playbooks (item 18).
- **Effort / Fit:** Small. Good fit.

---

## Operational / supportability (SuperClaude, Maestro, Agent Farm, observability)

### 18. Lightweight markdown playbooks

- **Pattern:** Maestro ships playbooks; SuperClaude ships polished operational docs.
- **Enhancement for s-kit:** Add text-first playbooks: `release-s-kit.md`, `add-skill.md`, `add-agent.md`, `compare-upstream.md`, `security-audit.md`, `spec-to-issues.md` — each with inputs, steps, verification, expected file changes, rollback.
- **Lands in:** new `docs/playbooks/`.
- **Effort / Fit:** Small. Good fit. **Rec 4.**

### 19. CI + release trust

- **Pattern:** Comparable projects surface CI/version/license badges and run their verification gate on every PR.
- **Enhancement for s-kit:** Add `.github/workflows/ci.yml` running `npm test` (PowerShell + node) and a Linux job running `bash tests/opencode/run-tests.sh` (the suite was dead until recently and still isn't in `npm test`). Add badges to `README.md`.
- **Lands in:** new `.github/workflows/ci.yml`, `README.md`.
- **Effort / Fit:** Small. Excellent fit. **Rec 1.**

### 20. Run reports via native Monitors (not a dashboard)

- **Pattern:** Agent Farm and the observability project build progress reports / event dashboards.
- **Enhancement for s-kit:** Have `build-feature` optionally emit `run-report.md` (tasks attempted, agents dispatched, files changed, verification outcomes, review findings, fix loops, residual risks) and machine-readable JSONL events that the host's native **Monitors** can consume — no bespoke dashboard.
- **Lands in:** `skills/build-feature/SKILL.md` (Step 9), optional report template.
- **Effort / Fit:** Medium. Good fit. **Rec 5.**

### 21. Map orchestration onto native Agent Teams where available

- **Pattern:** Claude Code now ships **Agent Teams** (team lead + peer teammates, shared task list, mailbox) natively; Citadel layers routing/persistence on top of an existing agent rather than reimplementing it.
- **Enhancement for s-kit:** Evaluate mapping `build-feature` waves onto native Agent Teams where present (`spec.json` is already a shared task contract), falling back to the current host-adapter dispatch elsewhere. Brainstorm before building — it touches the core orchestration contract.
- **Lands in:** `skills/build-feature/SKILL.md` (Step 4 host adapter).
- **Effort / Fit:** Large / design-first. **Rec 8.**

---

## Security (trailofbits/skills, CodeGuard, OWASP)

### 22. Checklist-driven security auditor aligned to OWASP ASI Top 10

- **Pattern:** Project CodeGuard applies security rules across plan/generate/review; the OWASP Top 10 for Agentic Applications (2026, ASI01–ASI10) is the peer-reviewed risk taxonomy; [trailofbits/skills](https://github.com/trailofbits/skills) shows audit-grade security skills in the Claude Code format.
- **Enhancement for s-kit:** Make `s-kit-security-auditor` explicitly checklist-driven: secrets, shell construction, filesystem writes/deletes, auth/authz, dependency & supply-chain (incl. MCP servers/plugins — OWASP ASI04), input validation, network/external services, data/log privacy. Run it during spec review for risky features *and* after implementation for risky surfaces.
- **Lands in:** `agents/s-kit-security-auditor.md`.
- **Effort / Fit:** Small–medium. Excellent fit. **Rec 6.**

### 23. Packaging / artifact hygiene check

- **Pattern:** The Mar 2026 Claude Code npm source-map leak (~512k lines exposed via a packaging misconfig) and VibeGuard's focus on artifact hygiene / packaging-config drift.
- **Enhancement for s-kit:** `s-kit` publishes across six packaging surfaces, so packaging drift is a realistic risk. Add a hygiene check (in `scripts/doctor.ps1`, item 13) that the published surfaces contain no source maps, secrets, or stray build output, and that declared paths resolve.
- **Lands in:** `scripts/doctor.ps1`.
- **Effort / Fit:** Small. Excellent fit. **Rec 6.**

---

## Consolidated Backlog

Ordered by value-to-effort, keyed to the per-project items above and the recommendations in `future-development-research.md`.

| # | Enhancement | Items | Rec | Effort | Risk |
| --- | --- | --- | --- | --- | --- |
| A | CI workflow (incl. Linux bash suite) + README badges | 19 | 1 | S | Low |
| B | `scripts/doctor.ps1` + packaging/artifact hygiene | 13, 23 | 2, 6 | S–M | Low |
| C | `spec.json` `metadata` field + dry-run spec-to-issues | 7, 8 | 3 | M | Low–Med |
| D | Security auditor → checklist aligned to OWASP ASI Top 10 | 22 | 6 | S–M | Low |
| E | Semantic cross-artifact "analyze" gate (spec-reviewer) | 1, 3 | — | S–M | Low |
| F | Lightweight playbooks under `docs/playbooks/` | 18 | 4 | S | Low |
| G | Discovery relay + independent checker evidence | 10, 14 | — | S–M | Low |
| H | Build-feature run reports via native Monitors | 20 | 5 | M | Med |
| I | Scale-adaptive ceremony + small-change lane | 5, 12, 16 | 7, 8 | M | Med |
| J | Map waves onto native Agent Teams | 21 | 8 | L | Med–High (design-first) |

A–D map to the research doc's "Recommended First Slice." E (semantic analyze gate) is a high-fit addition not previously called out as its own recommendation. I and J are design-first — brainstorm before building, since they touch the core workflow/orchestration contract.

## Deliberately Not Adopting

- Spec dashboards / any UI (item 6) — non-goal until text reports prove useful.
- Citadel's self-improving pattern library (item 11) — adds persistent cross-project state `s-kit` avoids by design.
- Tagged multi-context task lists (item 15) — already solved by dated `docs/specs/` folders.
- Broad command/agent catalogs (VoltAgent-style) — keep the agent surface compact.
- Legacy aliases for old workflow names.
