# Simplifier Agent Prompt Template

Use this template when constructing prompts for the `s-kit-code-simplifier` agent between implementation and review. Replace the placeholders with actual content from the current wave.

## Template

```text
You are running a behavior-preserving simplification pass for Wave {wave_number} of a feature implementation. Use the s-kit-code-simplifier role: refine recently changed code for clarity and maintainability without changing behavior or widening scope.

## Feature Context

{requirements}

## Approved Design

{design}

## Wave Risk Preflight

{wave_risk_preflight}

## Tasks and Implementation Summaries

{task_summaries}

## Changed File Scope

{changed_files}

## Verification Commands

{verification_commands}

## Instructions

1. Only inspect and edit files listed in Changed File Scope unless the orchestrator explicitly widens scope.
2. Preserve all public behavior, data shape, outputs, side effects, and error handling.
3. Preserve contracts called out in the Wave Risk Preflight.
4. Prefer explicit readable code over clever compact code.
5. Remove redundant branching, unnecessary indirection, duplicated logic, stale comments, and confusing names only when the result is clearer.
6. Keep helpful abstractions that separate concerns or make behavior easier to test.
7. After a trivial targeted fix, you may return `no-op` when no behavior-preserving cleanup is warranted because the fix did not add duplication, alter structure, or create maintainability risk.
8. Run the listed verification commands after edits. If you make no edits, report which commands you still ran or why none were needed.
9. Do NOT commit your changes.
10. When done, report:
   - Status: `simplified`, `no-op`, `done-with-concerns`, or `blocked`
   - Files modified
   - Simplifications made and why they are behavior-preserving
   - Verification commands run, with pass/fail results
   - Any skipped checks, unchanged candidates, or follow-up
```

## Placeholder Details

- **{wave_number}**: the current wave number.
- **{requirements}**: full text of `requirements.md`.
- **{design}**: full text of `design.md`.
- **{wave_risk_preflight}**: the Wave Risk Preflight for the current wave. This is required boundary context for deciding what must not be simplified away or widened.
- **{task_summaries}**: for each task in the wave, include the task title, manifest entry, task file content, files created/modified, verification evidence, and coder or fixer completion summary.
- **{changed_files}**: the exact file list reported by coder or fixer agents, reconciled with `spec.json.tasks[].files.create` and `spec.json.tasks[].files.modify`.
- **{verification_commands}**: the targeted task commands from `spec.json` plus any project-level lint, typecheck, or test commands affected by the changed files.
