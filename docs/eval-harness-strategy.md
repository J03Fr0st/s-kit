# Eval Harness Strategy

## Purpose

`s-kit` should treat behavior-level evals as a possible future complement to the
current test suite, not as an automatic replacement for it. The reviewed
upstream `dev` branch has moved toward a drill/evals harness for canonical
skill-behavior checks, but `s-kit` has different packaging, runtime surfaces,
and verification gates.

This document sets the strategy for deciding what may move to evals later. It
does not implement an eval harness.

## Upstream Dev Direction

The useful direction from the reviewed upstream `dev` branch is coverage-aware
migration:

- Evals become the canonical checks for skill behavior, especially whether an
  agent follows workflow instructions across realistic prompts.
- Existing bash tests are removed only after each covered assertion is mapped to
  an eval criterion.
- Bash tests that remain are annotated when no eval equivalent exists, so their
  continued value is explicit rather than accidental.

`s-kit` should adopt that discipline, not the full architecture by default.

## Current Test Categories

| Surface | Current Role | Strategy Classification |
| --- | --- | --- |
| `tests/opencode/` | Verifies OpenCode plugin loading, priority, tools, and bootstrap caching. | Structural tests that should stay as scripts. |
| `tests/codex-plugin-sync/` | Verifies packaged files sync into the Codex plugin surface. | Structural tests that should stay as scripts. |
| `tests/claude-code/` | Exercises behavior and integration flows through Claude-oriented shell harnesses. | Mixed behavior and integration tests; behavior assertions are eval candidates. |
| `tests/explicit-skill-requests/` | Checks direct skill invocation behavior from explicit user prompts. | Behavior tests that are candidates for future evals. |
| `tests/skill-triggering/` | Checks natural-language trigger behavior for skills. | Behavior tests that are candidates for future evals. |
| `tests/build-feature/` | Uses fixtures to verify build-feature execution behavior. | Integration tests that may stay optional or split into evals plus fixture tests. |
| `scripts/verify-*.ps1` | Enforces structural repository, naming, asset, workflow, and agent invariants. | Structural verification gates that should stay as scripts. |

## Classification Rules

### Structural Tests Stay as Scripts

Keep script-based checks when the assertion is about deterministic files,
packaging, paths, manifests, syntax, or repository invariants. Examples include:

- Plugin manifests and generated package surfaces include the expected files.
- Skills, agents, and assets satisfy naming and branding constraints.
- Workflow spec folders contain required files, statuses, and links.
- JavaScript, PowerShell, shell, and markdown files pass deterministic syntax or
  formatting checks.

These checks should remain fast, local, and suitable for `npm test`.

### Behavior Tests Are Eval Candidates

Consider evals when the assertion depends on how an agent interprets instructions
or responds to a realistic prompt. Examples include:

- A user explicitly asks for a skill and the agent invokes it before acting.
- A natural prompt triggers the intended skill without over-triggering unrelated
  skills.
- `build-feature` follows the wave/task/ownership model in an implementation
  scenario.
- A review or debugging workflow preserves required posture across multiple
  steps.

These checks may benefit from a behavior-level rubric because exact shell output
or brittle transcript matching is not the real contract.

### Integration Tests May Stay Optional

Keep integration tests when they prove multiple local surfaces work together and
the cost or external dependency is acceptable. If they become slow or flaky, they
can move behind an explicit command while `npm test` keeps deterministic gates.

`tests/build-feature/` is the main candidate for this split: fixture setup can
remain script-driven while agent-behavior expectations move to eval criteria.

## Coverage Map Requirement

No existing test may be deleted, disabled, or narrowed unless a coverage map
proves each assertion is represented by a replacement eval criterion or by
another retained test.

Use this template before changing any test:

| Existing Test | Assertion | Candidate Eval | Delete? | Evidence |
| --- | --- | --- | --- | --- |
| `tests/...` | ... | ... | No | No eval exists yet |

The `Delete?` column should remain `No` until the replacement eval exists, runs
successfully, and its rubric covers the old assertion. A strategy document or
future intent is not replacement coverage.

## First Eval Spike

The first eval spike should target the smallest behavior surface with clear value:
skill invocation behavior from `tests/explicit-skill-requests/` and
`tests/skill-triggering/`.

Recommended spike scope:

1. Pick two explicit-request prompts and two natural-trigger prompts.
2. Write eval criteria that check the behavior contract, not exact transcript
   wording.
3. Run the evals outside `npm test` until the harness is stable.
4. Produce a coverage map comparing each selected shell test assertion to the
   new eval criterion.
5. Keep every existing shell test in place until the coverage map and eval output
   justify a later deletion decision.

Do not start with packaging, plugin sync, or `scripts/verify-*.ps1`; those are
deterministic structural checks and are better served by scripts.

## Decision Posture

Adopt behavior-level evals only where they make the contract clearer than the
current scripts. Keep deterministic structure checks script-based. Any future
eval harness must prove coverage before removing tests, and it must remain
compatible with `s-kit`'s canonical workflow:

```text
brainstorming -> plan-feature -> build-feature -> verification/review -> ship
```
