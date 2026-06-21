# Future Development Research

Research date: 2026-05-31 (refreshed 2026-05-31 with web research)

This note captures enhancement ideas from comparable AI agent workflow, spec-driven development, and Claude Code ecosystem projects. It is a planning reference, not an active feature spec.

For the detailed, per-project breakdown of what `s-kit` could borrow from each comparable (mapped to the exact files/skills it would touch), see [comparable-project-enhancements.md](comparable-project-enhancements.md).

## Current s-kit Position

`s-kit` is already strongest where many comparable projects are weak:

- A compact workflow: `brainstorming -> plan-feature -> build-feature -> verification/review -> ship`.
- Dated design and spec artifacts under `docs/design/YYYY-MM-DD-{feature-name}/` and `docs/specs/YYYY-MM-DD-{feature-name}/`.
- Purpose-built agents for codebase mapping, pattern mapping, spec review, coding, simplification, code review, fixing, and security audit.
- Verification gates through `npm test`, including branding, assets, agents, naming, and workflow invariants.

The main development direction should be trust, supportability, and workflow integration rather than copying broad command or agent catalogs.

## Ecosystem Shifts Since Last Review

The agent-workflow space moved fast in early 2026. The most decisive change is that **Claude Code now ships natively what many of these projects bolt on**, which should pull `s-kit` toward leaning on host primitives instead of reimplementing them.

- **Claude Code native primitives (April 2026 spec).** The host now treats Skills (commands folded into skills), Subagents, **Agent Teams**, Plugins, Hooks, MCP servers, **LSP servers**, and **Monitors** as first-class. There is a built-in plugin marketplace for browse/install/manage. ([plugins docs](https://code.claude.com/docs/en/plugins), [skills/subagents/plugins mental model](https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05))
- **Agent Teams = native orchestration.** An experimental built-in (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) where a "team lead" coordinates teammates that each have their own context window and talk peer-to-peer via a mailbox and shared task list. This overlaps directly with what `build-feature` orchestrates by hand. ([agent-teams docs](https://code.claude.com/docs/en/agent-teams))
- **Monitors = native observability.** The host exposes a monitor primitive, reducing the need to build a custom dashboard or event database for run visibility.
- **Spec Kit matured the spec-driven loop.** `Spec -> Plan -> Tasks -> Implement` with seven slash commands, now including `/constitution` (project principles), `/clarify` (resolve spec ambiguities before planning), and `/analyze` (cross-artifact consistency). Claims ~30 agent integrations with single-command agent switching. ([github/spec-kit](https://github.com/github/spec-kit), [Spec Kit docs](https://github.github.com/spec-kit/))
- **Superpowers (the lineage repo) cut review cost.** Releases 5.0.x (Mar–May 2026) **removed subagent review loops in favor of inline self-review** (reportedly cutting run time substantially) and added an integrated **Spec Self-Review checklist** that catches several bugs in ~30 seconds, plus a zero-dependency brainstorm server (RFC 6455 WebSockets) and Copilot CLI tool mapping with SessionStart injection. ([obra/superpowers](https://github.com/obra/superpowers))
- **BMAD V6 went scale-adaptive.** V6 (project created Jan 2026) adds a Skills Architecture, sub-agent inclusion, a BMad Builder, Dev Loop Automation, and **scale-adaptive intelligence** that varies ceremony by task size. ([bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD))
- **Taskmaster formalized task metadata.** Its Claude Code plugin (v0.29) adds orchestrator/executor/checker agents, an arbitrary-JSON **metadata field** on tasks (external IDs, integration data), and **tagged task lists** for multi-context work. ([eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master))
- **Security got a peer-reviewed agent standard.** The **OWASP Top 10 for Agentic Applications (2026)** (released Dec 2025, ASI01–ASI10) is the first peer-reviewed framework for autonomous-agent risk, explicitly covering tool misuse, privilege abuse, and **ASI04 agentic supply-chain risk** (MCP servers, plugins, registries). A real cautionary case — the Mar 31 2026 Claude Code npm package shipping a 59.8 MB source map exposing ~512k lines of source from a packaging misconfig — underlines artifact/packaging hygiene. ([OWASP Agentic Top 10](https://goteleport.com/blog/owasp-top-10-agentic-applications/), [VibeGuard](https://arxiv.org/pdf/2604.01052), [Project CodeGuard](https://blogs.cisco.com/ai/announcing-new-framework-securing-ai-generated-code))

## Comparable Projects

| Project | What It Does Well (2026) | Useful s-kit Takeaway |
| --- | --- | --- |
| [GSD Core](https://github.com/open-gsd/gsd-core) | Compact "Git. Ship. Done" workflow core and the closest upstream comparison target for agent/workflow surface checks. | Keep comparing selectively; avoid unrelated-history merges and port only workflow ideas that fit `s-kit`. |
| [Superpowers](https://github.com/obra/superpowers) | Lineage repo for the base workflow shape; v5.0.x replaced subagent review loops with inline self-review and added a fast Spec Self-Review checklist. | Track upstream; weigh an inline self-review/spec self-review checklist against `s-kit`'s heavier multi-stage agent review (a live tension — see Recommendation 8). |
| [GitHub Spec Kit](https://github.com/github/spec-kit) | `Spec -> Plan -> Tasks -> Implement` with `/constitution`, `/clarify`, `/analyze`; ~30 agent integrations and agent switching. | `/clarify` ≈ brainstorming gate; `/analyze` ≈ `verify-workflow.ps1` cross-artifact checks; `/constitution` ≈ `CONTEXT.md`/ADRs. Add issue export/import and lightweight template overrides. |
| [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) | V6 installer/modules, BMad Builder, Dev Loop Automation, and scale-adaptive ceremony by task size. | Add a `doctor`/help path; consider scaling workflow ceremony to task size instead of one fixed path. |
| [Taskmaster](https://github.com/eyaltoledano/claude-task-master) | Task dependencies, tagged/multi-context lists, per-task JSON metadata, MCP + CLI surfaces, orchestrator/executor/checker agents. | Carry external issue IDs and integration data in `spec.json` (metadata field); use it as the source for dependency export and progress tracking. |
| [SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) | Broad command surface, personas, MCP integration guidance, doctor command, multi-language docs, visible CI/version badges. | Borrow diagnostics and documentation polish, not the large command footprint. |
| [VoltAgent Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | Large categorized subagent catalog, plugin packaging by category, installer options, discoverability. | Keep `s-kit` compact; add only workflow-critical agents and maintain catalog validation. |
| [Maestro](https://github.com/RunMaestro/Maestro) | Agent orchestration, isolated sessions, playbooks, worktrees, CLI, usage dashboard, document graph. | Add lightweight markdown playbooks and local run reports before considering any UI; prefer native Monitors over a bespoke dashboard. |
| [Claude Code Agent Farm](https://github.com/Dicklesworthstone/claude_code_agent_farm) | Parallel agents, lock-based coordination, preflight doctor, monitoring, progress reports, safe-operation controls. | Strengthen Phase coordination, file-ownership checks, and execution reporting; evaluate native Agent Teams before custom locking. |
| [Claude Hooks Multi-Agent Observability](https://github.com/disler/claude-code-hooks-multi-agent-observability) | Hook-based event capture, SQLite/WebSocket dashboard, session/event filtering, agent lifecycle tracking. | Start with optional local JSONL/Markdown run reports; route through native Monitors rather than a full dashboard. |
| [Project CodeGuard](https://github.com/cosai-oasis/project-codeguard) | Security rules/skills applied before, during, and after generation, with agent-specific translation and validators. | Make `s-kit-security-auditor` checklist-driven and map it to the OWASP Agentic Top 10; validate risky specs earlier. |

## Repository Watchlist

Keep this list current when doing future upstream or ecosystem research.

### Core Lineage and Direct Comparison

- [GSD Core](https://github.com/open-gsd/gsd-core)
- [Superpowers](https://github.com/obra/superpowers)

### Spec and Workflow Frameworks

- [GitHub Spec Kit](https://github.com/github/spec-kit)
- [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD)
- [Taskmaster](https://github.com/eyaltoledano/claude-task-master)
- [SuperClaude Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)

### Agent Catalogs and Orchestration

- [VoltAgent Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [Maestro](https://github.com/RunMaestro/Maestro)
- [Claude Code Agent Farm](https://github.com/Dicklesworthstone/claude_code_agent_farm)
- [Claude Hooks Multi-Agent Observability](https://github.com/disler/claude-code-hooks-multi-agent-observability)

### Host Platform Primitives

- [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)

### Security

- [Project CodeGuard](https://github.com/cosai-oasis/project-codeguard)
- [OWASP Top 10 for Agentic Applications (2026)](https://goteleport.com/blog/owasp-top-10-agentic-applications/)

### Community-Surfaced (Reddit / curated lists)

Reddit (`reddit.com`) is not directly crawlable by the research tooling, so these were found via curated community lists that track Reddit/GitHub approval and then verified on GitHub. They are close comparables worth watching; star counts are approximate as of the refresh date.

- [claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow) (~3.8k★) — Kiro-style spec workflow (`/spec-create` → `/spec-execute`) producing requirements/design/tasks artifacts plus steering docs and a dashboard. The closest direct comparable to `plan-feature`/`build-feature`.
- [ccpm](https://github.com/automazeio/ccpm) (~8.2k★) — spec-driven PM that uses GitHub Issues as the source of truth and git worktrees for parallel agents; PRD → epic → task → issue with full traceability ("every line of code must trace back to a specification"). Strong reference for spec-to-issues (Rec 3) and worktrees.
- [Citadel](https://github.com/SethGammon/Citadel) — orchestration harness with four-tier routing, campaign persistence across sessions, parallel agents in isolated worktrees, discovery relay between Phases, circuit breaker, and a self-improving pattern library. Reference for Phase coordination and the orchestration decision (Rec 8).
- [claude-squad](https://github.com/smtg-ai/claude-squad) — manages multiple terminal agents (Claude Code, Aider, Codex, OpenCode, Amp) working in parallel.
- [planning-with-files](https://github.com/OthmanAdi/planning-with-files) — Manus-style persistent markdown planning skill using file-based coordination; mirrors `plan-feature`'s file-per-task ethos.
- [claude-simone](https://github.com/Helmi/claude-simone) — a project-management framework for AI-assisted development with Claude Code.
- [trailofbits/skills](https://github.com/trailofbits/skills) (~5.5k★) — a reputable security firm's Claude Code skill marketplace (vulnerability detection, audit workflows, smart-contract and malware analysis). Strong reference for the security checklist (Rec 6).

## Recommended Enhancements

### 1. Add CI and Release Trust

Add `.github/workflows/ci.yml` that runs `npm test` on pull requests and pushes. Then surface CI, version, license, and release badges in `README.md`.

Why this matters:

- Comparable projects make verification status visible immediately.
- `s-kit` already has a good local verification command; CI should run the same gate.
- It reduces the chance of broken plugin manifests or stale renamed paths being published.
- There is currently **no CI**, and the `tests/opencode/` bash suite is not run by `npm test`, so regressions there can go unnoticed. CI is the natural place to run both the PowerShell gates and the bash suite (on Linux, where `ln -s` registration behaves as designed).

Suggested first implementation:

- GitHub Actions workflow for Node plus PowerShell.
- Run `npm test`, and add a Linux job that runs `bash tests/opencode/run-tests.sh`.
- Add a badge to `README.md`.
- Add a release checklist that requires `scripts/bump-version.sh --check` or equivalent.

### 2. Add an `s-kit doctor` Check

Create a diagnostic command/script that validates the local repo and install surfaces.

Candidate checks:

- All declared versions match across `package.json`, plugin manifests, marketplace files, and Gemini extension.
- Required assets exist.
- Required skills and agents exist.
- Old paths such as `skills/create-spec/` and `skills/implement-feature/` are absent.
- `.codex-plugin`, `.claude-plugin`, `.cursor-plugin`, `.opencode`, hooks, and Gemini manifest expose the expected paths.
- `npm test` can be run from a clean checkout.

This can start as `scripts/doctor.ps1` and later be exposed per runtime if useful. BMAD V6 and SuperClaude both ship a doctor path; it is now table stakes for installable agent kits.

### 3. Add Spec-to-Issues Export

Use `docs/specs/YYYY-MM-DD-{feature-name}/spec.json` as the machine-readable source for GitHub issue creation.

Useful behavior:

- Convert each task into an issue with links back to the spec, requirements, and design.
- Preserve Phase, dependencies, verification commands, and owned files in the issue body.
- Add labels such as `s-kit`, `Phase-1`, `needs-verification`, or `security-review` when relevant.
- Support dry-run output before writing to GitHub.
- Borrow Taskmaster's pattern: add an optional `metadata` object per task in `spec.json` to round-trip external issue IDs and integration data, so re-export stays idempotent.

This matches `s-kit` well because the spec already has task identity, dependencies, statuses, and verification plans. Spec Kit's task-to-issue flow is the closest reference implementation, and [ccpm](https://github.com/automazeio/ccpm) is a strong proof point — it treats GitHub Issues as the source of truth with PRD → epic → task → issue traceability and git-worktree parallelism.

### 4. Add Lightweight Playbooks

Add markdown playbooks for repeatable maintenance and workflow tasks.

Good first playbooks:

- `release-s-kit.md`
- `add-skill.md`
- `add-agent.md`
- `compare-upstream.md`
- `security-audit.md`
- `spec-to-issues.md`

Each playbook should list inputs, steps, verification, expected file changes, and rollback notes. Keep these as text-first operational recipes, not a new orchestration framework.

### 5. Add Build-Feature Run Reports

Have `build-feature` produce an optional run report after execution.

Possible artifact:

```text
docs/specs/YYYY-MM-DD-{feature-name}/run-report.md
```

Recommended contents:

- Tasks attempted.
- Agents dispatched.
- Files changed.
- Verification commands and outcomes.
- Review findings.
- Fix loops.
- Final unresolved risks.

This gives useful observability without requiring a dashboard or event database. Prefer emitting machine-readable events (JSONL) that the host's native **Monitors** can consume, rather than building a bespoke dashboard like the multi-agent observability projects do.

### 6. Strengthen Security Audit Coverage

Make `s-kit-security-auditor` more explicit and checklist-driven, and align the checklist with the **OWASP Top 10 for Agentic Applications (2026, ASI01–ASI10)**.

Recommended checklist areas:

- Secrets and credentials.
- Shell command construction.
- File-system writes and deletes.
- Auth and authorization.
- Dependency and supply-chain risk — including MCP servers, plugins, and registries (OWASP ASI04).
- User input validation.
- Network calls and external services.
- Data privacy and logs.
- **Packaging and artifact hygiene** — no source maps, secrets, or stray build output in published plugin/marketplace packages. `s-kit` publishes across six packaging surfaces, so a packaging-config drift (cf. the Mar 2026 Claude Code source-map leak) is a realistic risk worth a dedicated check, possibly in `s-kit doctor`.

The best time to run this is both during spec review for risky features and after implementation for code touching risky surfaces. [trailofbits/skills](https://github.com/trailofbits/skills) is a credible reference for what audit-grade security skills look like in the Claude Code format.

### 7. Add Template Overrides and Scale-Adaptive Ceremony Later

Borrow the useful part of Spec Kit presets and BMAD's scale-adaptive idea, but keep it small.

Potential override areas:

- `docs/design` template.
- `docs/specs` task template.
- Security-heavy task template.
- Domain terminology template for repos with `CONTEXT.md` and ADRs.

Consider letting the workflow scale ceremony to task size (a one-file change should not need a full Phase/manifest), similar to BMAD V6's scale-adaptive intelligence — without adding a large extension marketplace until the core workflow has proven extension points.

### 8. Decide Where to Lean on Host Primitives vs. Custom Orchestration

This is now the highest-leverage strategic question. Claude Code ships native **Agent Teams** (team lead + peer teammates with a shared task list and mailbox) and **Monitors**, which overlap with what `build-feature` orchestrates and what Recommendation 5 proposes.

Open questions to resolve before building more orchestration:

- Should `build-feature` map Phases onto native Agent Teams where available, falling back to the current host-adapter dispatch elsewhere? `spec.json` is already a shared task contract, which fits the Agent Teams model.
- Meanwhile, Superpowers moved the other way — replacing subagent review loops with inline self-review for speed. `s-kit` recently went heavier (added a simplification pass and two-stage review). Worth a deliberate decision on the cost/quality trade-off, perhaps gated by task size (see Recommendation 7).

[Citadel](https://github.com/SethGammon/Citadel) is a useful reference here: it adds routing, campaign persistence, isolated-worktree parallelism, and cross-Phase discovery relay on top of an existing agent rather than reimplementing the agent — a model `s-kit` could follow on top of native Agent Teams.

Resolve this as a brainstorming/design exercise rather than jumping to implementation, since it touches the core orchestration contract.

## Recommended First Slice

Start with:

1. CI running `npm test` (plus the `tests/opencode/` bash suite on Linux).
2. `scripts/doctor.ps1`, including a packaging/artifact-hygiene check across the six install surfaces.
3. Spec-to-GitHub-issues dry-run export, with a `metadata` field in `spec.json` for external IDs.

This gives immediate trust and practical workflow value without expanding the agent surface or adding heavy infrastructure. The Agent Teams vs. custom-orchestration decision (Recommendation 8) should be brainstormed in parallel but not built until it has a design.

## Explicit Non-Goals

- Do not add dozens of generic language/framework agents.
- Do not copy broad slash-command frameworks.
- Do not build a UI before local text reports and playbooks prove useful.
- Do not replace the dated `docs/design` and `docs/specs` workflow.
- Do not add legacy aliases for old workflow names.

## Sources

Web research refreshed 2026-05-31:

- GitHub Spec Kit — [repo](https://github.com/github/spec-kit), [docs](https://github.github.com/spec-kit/)
- BMAD Method V6 — [repo](https://github.com/bmad-code-org/BMAD-METHOD)
- Superpowers — [repo](https://github.com/obra/superpowers)
- Taskmaster — [repo](https://github.com/eyaltoledano/claude-task-master)
- Claude Code primitives — [plugins](https://code.claude.com/docs/en/plugins), [agent teams](https://code.claude.com/docs/en/agent-teams), [skills/subagents/plugins mental model](https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05)
- Security — [OWASP Top 10 for Agentic Applications (2026)](https://goteleport.com/blog/owasp-top-10-agentic-applications/), [Project CodeGuard / Cisco](https://blogs.cisco.com/ai/announcing-new-framework-securing-ai-generated-code), [VibeGuard](https://arxiv.org/pdf/2604.01052)
- Community discovery — Reddit (`reddit.com`) is not crawlable by the research tooling; community-surfaced repos were found via the curated [Claude Code Resource List (2026 Edition)](https://www.scriptbyai.com/claude-code-resource-list/) and verified on GitHub: [claude-code-spec-workflow](https://github.com/Pimzino/claude-code-spec-workflow), [ccpm](https://github.com/automazeio/ccpm), [Citadel](https://github.com/SethGammon/Citadel), [claude-squad](https://github.com/smtg-ai/claude-squad), [planning-with-files](https://github.com/OthmanAdi/planning-with-files), [claude-simone](https://github.com/Helmi/claude-simone), [trailofbits/skills](https://github.com/trailofbits/skills)
