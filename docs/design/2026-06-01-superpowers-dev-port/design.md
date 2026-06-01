# Design: Superpowers Dev Port Review

Approval status: Approved on 2026-06-01 in the current conversation.

## Context

`obra/superpowers` has a live `dev` branch that differs materially from `main`. As of the comparison, `dev` points at commit [`deceaec78df64a1cabae01fb85e39140b6d833fb`](https://github.com/obra/superpowers/commit/deceaec78df64a1cabae01fb85e39140b6d833fb), is 53 commits ahead of `main`, and is 1 commit behind `main`. The branch is not a single feature; it is a bundle of methodology, harness, test, documentation, and cross-runtime changes.

`s-kit` should not blindly merge or mirror this branch. The local repo has already diverged from Superpowers through canonical naming (`brainstorming -> plan-feature -> build-feature -> verification/review -> ship`), Codex-focused packaging, `grill-me`, `grill-with-docs`, CI, version checks, and a doctor script. The goal is to identify which `dev` ideas strengthen `s-kit` while preserving its compact workflow and dated design/spec contract.

This design covers five port candidates from Superpowers `dev`:

1. Reviewer read-only safety and scoped git ranges.
2. Codex native hook support.
3. Cross-runtime action-language cleanup.
4. A porting-to-new-harness playbook.
5. Evaluation harness strategy.

## Approved Approach

Port the Superpowers `dev` changes selectively in small, reviewable slices. Treat the branch as a source of proven patterns, not as an upstream to merge.

The recommended shape is:

1. First, harden review prompts so review agents operate read-only and inspect only the relevant task diff/range.
2. Then add a Codex native hook design only if the current Codex app/plugin surface can consume it without manual user config edits.
3. Then clean skill prose toward action-language while keeping runtime-specific tool mappings in `skills/using-s-kit/references/`.
4. Then add a `docs/playbooks/port-new-harness.md` playbook based on Superpowers' new harness-porting guide.
5. Finally, evaluate whether `s-kit` needs a full eval harness or only a smaller set of behavior smoke tests.

This sequence prioritizes low-risk correctness and supportability before larger methodology changes. The eval harness is intentionally last because it may change the testing architecture and could replace or restructure existing bash test suites.

## Alternatives Considered

- Merge or cherry-pick the entire Superpowers `dev` branch — rejected because `s-kit` has different naming, plugin packaging, workflow contracts, and repo goals. A wholesale port would likely reintroduce old Superpowers terms and incompatible paths.
- Ignore the branch and continue only with local improvements — rejected because several `dev` changes address real issues that also apply to `s-kit`, especially read-only reviewers, cross-runtime wording, harness porting, and behavior-level test strategy.
- Port the eval harness first — rejected for now because it has the largest blast radius. `s-kit` should first improve its current CI/doctor/test foundation, then decide whether an eval harness replaces or supplements existing tests.

## Architecture

The design affects these local surfaces:

- `skills/build-feature/` and its prompt templates: add reviewer safety, scoped review inputs, and explicit read-only rules.
- `agents/s-kit-spec-reviewer.md` and `agents/s-kit-code-reviewer.md`: ensure review agents do not mutate the working tree, index, HEAD, or branch state.
- `skills/using-s-kit/references/`: keep runtime-specific tool mappings here rather than scattering raw tool names through skill bodies.
- `skills/*/SKILL.md`: progressively replace runtime-specific tool vocabulary with action-language where it does not reduce clarity.
- `hooks/`, `.codex-plugin/plugin.json`, and plugin manifests: possible Codex native hook support, subject to Codex app compatibility.
- `docs/playbooks/`: new operational playbook for porting `s-kit` to a new harness.
- `tests/`: possible future behavior-eval strategy, but not in the first implementation slice.

### Candidate 1: Reviewer Read-Only Safety and Scoped Git Ranges

Superpowers `dev` added reviewer prompt changes after review agents crawled too much history and, in one case, detached HEAD while reviewing. `s-kit` has a similar risk because `build-feature` dispatches spec-compliance and code-quality review agents.

The local design should:

- Pass the relevant task diff or git range into spec and code review prompts.
- State that reviewers are read-only.
- Forbid mutation of the working tree, index, HEAD, branch state, or staged files.
- Permit historical inspection only through a separate temporary worktree or read-only commands.
- Require review output to identify the reviewed range.

This is the highest-priority port because it directly protects user work.

### Candidate 2: Codex Native Hook Support

Superpowers `dev` added Codex native hook files and plugin manifest support. `s-kit` already has hook surfaces and Codex plugin packaging, but support should be verified against the current Codex app behavior before copying file shapes.

The local design should:

- Inspect Codex plugin hook support from current app/plugin docs or local installed plugin behavior.
- Add hook files only through the plugin's declared install mechanism.
- Avoid manual edits to user config.
- Add tests that verify hook files are included and paths resolve.
- Extend `scripts/doctor.ps1` once the hook contract is known.

This should be a separate design/spec slice if compatibility is uncertain.

### Candidate 3: Action-Language Skill Prose

Superpowers `dev` moved skill prose away from raw runtime tool names toward action-language, with runtime tool mappings isolated in reference files. `s-kit` already has `skills/using-s-kit/references/codex-tools.md`, `gemini-tools.md`, and `copilot-tools.md`, but skill bodies may still mix generic workflow instructions with host-specific tool names.

The local design should:

- Keep direct tool names only where a section is explicitly runtime-specific.
- Use action-language in shared skill prose: create a todo, dispatch a subagent, read a file, edit a file, run a shell command, open a browser, inspect a diff.
- Keep runtime mapping in `skills/using-s-kit/references/`.
- Update tests only where assertions depend on the old wording.
- Preserve terms that are canonical to `s-kit`, such as `brainstorming`, `plan-feature`, and `build-feature`.

This can be done incrementally and should be guarded by the naming verifier to avoid reintroducing old Superpowers names.

### Candidate 4: Porting-to-New-Harness Playbook

Superpowers `dev` added `docs/porting-to-a-new-harness.md`, an evergreen guide for adding support for a new IDE, CLI, or agent runner. `s-kit` should adopt the concept as an operational playbook rather than a direct copy.

The local design should create:

```text
docs/playbooks/port-new-harness.md
```

The playbook should cover:

- Harness discovery.
- Install mechanism.
- Skill discovery and invocation.
- Bootstrap/session-start behavior.
- Tool mapping.
- Acceptance tests.
- Local install verification.
- Distribution and release checks.
- Non-negotiables: do not edit skill bodies for one harness, and do not require manual user config edits when a plugin install path exists.

This fits the structure review recommendation to add `docs/playbooks/` as the durable home for operational procedures.

### Candidate 5: Evaluation Harness Strategy

Superpowers `dev` lifts many bash tests into a behavior-level eval harness. `s-kit` currently has conventional shell tests and CI/doctor checks. A full eval harness could improve cross-agent confidence, but it is a larger architectural decision.

The local design should not import the Superpowers eval harness directly. Instead, start with an eval strategy decision:

- Which behaviors are worth model/harness-level evals?
- Which current bash tests are structural and should stay?
- Which current tests are behavior assertions that might move to evals later?
- Whether evals should be a submodule, vendored folder, or separate repo.
- Whether CI should run evals by default or only on demand.

The first implementation should be a research/design spike, not a full harness migration.

## Configuration and Inputs

Stored configuration:

- `.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, and `gemini-extension.json` continue to define package/runtime surfaces.
- `scripts/doctor.ps1` and existing verify scripts define health-check expectations.
- `skills/using-s-kit/references/` remains the home for runtime tool mappings.

Command arguments:

- Existing verification commands remain `npm test`, `npm run doctor`, `bash scripts/bump-version.sh --check`, and `bash tests/opencode/run-tests.sh`.
- Future eval commands, if any, must be explicit and separate from `npm test` until stable.

Defaults:

- Default port strategy is selective adaptation, not upstream merge.
- Default documentation location for operational guides is `docs/playbooks/`.
- Default review-agent posture is read-only.

Per-command overrides:

- Implementation specs may choose to run broader or narrower verification based on the slice.
- Codex hook implementation may be skipped if current Codex plugin support is not confirmed.
- Eval harness work may remain design-only until the trade-off is approved.

## Decisions

- Selective porting is the approved direction for review, not a merge of `obra/superpowers@dev`.
- Reviewer read-only safety and scoped git ranges are the first candidate to implement after approval.
- Codex native hooks need compatibility verification before implementation.
- Action-language cleanup should preserve `s-kit` canonical names and avoid broad churn.
- Harness-porting guidance belongs in `docs/playbooks/`, not in README-only prose.
- Eval harness adoption requires a separate design decision before migration.

## Risks and Constraints

- Superpowers `dev` is diverged from `main`; one `main` commit is not in `dev`, so `dev` is not a clean future-main snapshot.
- Direct cherry-picks may reintroduce Superpowers naming, old workflow paths, or incompatible packaging assumptions.
- Codex hook support may have changed or may differ between Codex app versions.
- Action-language cleanup can become noisy if it touches every skill at once.
- Eval harness migration could delete useful local tests unless coverage mapping is rigorous.
- Existing CI and doctor changes should remain compatible with any new hook/playbook/eval surfaces.

## Verification Strategy

Each implementation slice should include targeted verification:

- Reviewer safety:
  - `npm test`
  - prompt-template checks that review prompts include read-only constraints and git range context
  - a fixture or textual verifier that rejects prompts allowing branch/index/HEAD mutation
- Codex hooks:
  - `npm run doctor`
  - manifest/path checks
  - hook fixture tests proving install files resolve without user config edits
- Action-language cleanup:
  - `npm test`
  - naming verifier scan for retired names and runtime-specific wording in shared prose
  - spot-check affected skill trigger tests
- Porting playbook:
  - `git diff --check -- docs/playbooks/port-new-harness.md`
  - link/path sanity checks where practical
- Eval strategy:
  - no test deletion without a coverage map
  - any eval migration must prove old assertions are represented by new eval criteria before deleting old tests

Before any spec generation, this design should be reviewed and explicitly approved. Optional `grill-me` review can stress-test the order, scope, and trade-offs.
