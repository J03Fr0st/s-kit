# s-kit

`s-kit` is a personal agent workflow kit for turning ideas into dated, reviewable specs and then executing those specs through focused implementation waves.

The core workflow is:

```text
brainstorming -> plan-feature -> build-feature -> verification/review -> ship
```

`brainstorming` is the front door. It clarifies the idea, explores options, gets design approval before any implementation starts, and writes that approved solution to `docs/design/YYYY-MM-DD-{feature-name}/design.md`. `plan-feature` expands the approved design into a matching dated spec folder under `docs/specs/YYYY-MM-DD-{feature-name}/`, including a manifest and execution log. `build-feature` reads the spec and matching design, works through task waves, runs a behavior-preserving simplification pass before spec-compliance and code-quality review gates, and tracks progress in the spec files.

## Install Targets

The repo keeps packaging surfaces for:

- Codex App and Codex CLI via `.codex-plugin/`
- Claude Code via `.claude-plugin/`
- GitHub Copilot CLI via `hooks/session-start`
- OpenCode via `.opencode/`
- Cursor via `.cursor-plugin/`
- Gemini via `gemini-extension.json`

## Workflow

1. Use `brainstorming` for any creative or behavior-changing work.
2. After the design is approved and written to `docs/design/YYYY-MM-DD-{feature-name}/design.md`, use `plan-feature`.
3. Designs and specs are created as:

   ```text
   docs/design/YYYY-MM-DD-{feature-name}/
   └── design.md

   docs/specs/YYYY-MM-DD-{feature-name}/
   ├── README.md
   ├── spec.json
   ├── requirements.md
   ├── action-required.md
   ├── implementation-log.md
   └── tasks/
       ├── task-01-{name}.md
       └── task-02-{name}.md
   ```

4. Use `build-feature` to execute a spec wave by wave.
5. Use the supporting skills for TDD, debugging, review, verification, worktrees, branch finishing, and skill authoring when they apply.

## Skills

Primary workflow:

- `brainstorming` - collaborative design and approval gate
- `plan-feature` - expands an approved `docs/design/.../design.md` into a matching dated, self-contained feature spec
- `build-feature` - executes feature specs by dependency wave

Supporting workflow:

- `test-driven-development` - test-first implementation discipline
- `systematic-debugging` - root-cause debugging process
- `verification-before-completion` - proof before completion claims
- `requesting-code-review` - review gate for completed work
- `receiving-code-review` - handles review feedback rigorously
- `using-git-worktrees` - isolated workspace setup when needed
- `finishing-a-development-branch` - delivery and cleanup decisions
- `dispatching-parallel-agents` - general parallel-agent coordination
- `writing-skills` - skill creation and maintenance
- `using-s-kit` - bootstrap/router instructions for skill use

Workflow redirects:

- `writing-plans`
- `executing-plans`
- `subagent-driven-development`

These skills redirect to `plan-feature` or `build-feature`; they are not a separate planning or execution path.

## Agents

The repo also includes a compact first-class agent catalog for runtimes that support reusable agent prompts. These agents are intentionally scoped to the dated design/spec workflow instead of mirroring a larger upstream orchestration system.

- [`s-kit-codebase-mapper`](agents/s-kit-codebase-mapper.md) - maps repository structure, conventions, verification commands, and risks before planning.
- [`s-kit-pattern-mapper`](agents/s-kit-pattern-mapper.md) - finds local implementation patterns that specs and coders should follow.
- [`s-kit-spec-reviewer`](agents/s-kit-spec-reviewer.md) - checks dated specs for coverage, wave safety, verification quality, and manifest consistency.
- [`s-kit-coder`](agents/s-kit-coder.md) - implements one spec task with scoped file ownership and verification evidence.
- [`s-kit-code-simplifier`](agents/s-kit-code-simplifier.md) - refines recently changed code for clarity while preserving behavior, scope, and verification evidence.
- [`s-kit-code-reviewer`](agents/s-kit-code-reviewer.md) - reviews completed work for spec compliance, correctness, security, maintainability, and tests.
- [`s-kit-fixer`](agents/s-kit-fixer.md) - applies scoped fixes for review findings without widening the task.
- [`s-kit-security-auditor`](agents/s-kit-security-auditor.md) - audits specs or implementation touching secrets, shell commands, packages, files, auth, permissions, or user input.

## Verification

Run `npm test` before publishing changes. It checks the OpenCode plugin syntax, branding/path cleanup, agent catalog integrity, and workflow invariants such as matching `docs/design/` and `docs/specs/` folders, required manifests/logs, task verification plans, task statuses, and same-wave file ownership.

## Attribution

See [NOTICE.md](NOTICE.md) for upstream attribution.

## License

MIT License - see [LICENSE](LICENSE).
