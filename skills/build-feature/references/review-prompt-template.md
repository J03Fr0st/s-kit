# Review Agent Prompt Template

Use this template when constructing prompts for review agents between waves. Replace the placeholders with actual content. Set `{review_type}` to either `Spec Compliance` or `Code Quality`.

## Template

```text
You are running a {review_type} review for Wave {wave_number} of a feature implementation. Multiple coder agents worked in parallel on separate tasks. Your job is to review only; do not edit files.

## Read-Only Review Contract

You are reviewing only. Do not modify files, the index, HEAD, branch state, staged changes, task statuses, or generated artifacts. If you need to inspect another revision, use read-only git commands or a separate temporary worktree. Your output must state the git range, task diff, or file set reviewed.

## Feature Context

{requirements}

## Approved Design

{design}

## Tasks Completed in This Wave

{task_summaries}

## Review Scope

{review_scope}

If the review scope is missing or too vague, stop and request the concrete git range, task diff, or file set. Do not discover the whole repository history.

## Verification Commands

{verification_commands}

## Review Mode

{review_type}

If this is a Spec Compliance review:

1. Verify each task matches the approved design.
2. Verify each task satisfies its Technical Details, Verification Plan, and Acceptance Criteria.
3. Verify each task stayed within its manifest file ownership and did not add unrelated behavior.
4. Verify status updates are consistent across spec.json, task files, and README checkboxes.
5. Verify manual assumptions match action-required.md.
6. Verify the simplification pass stayed within the changed-file scope and did not alter approved behavior.

If this is a Code Quality review:

1. Run the listed verification commands and report results. Fix nothing.
2. Verify integration across task outputs: imports, types, module boundaries, configuration, generated artifacts, and environment assumptions.
3. Check maintainability, simplicity, security, performance, error handling, and project conventions.
4. Check for cleanup or workflow invariant regressions when the repository has those checks.
5. Flag test gaps or skipped checks that should block completion.

## Verdict

Respond with one of:

**VERDICT: PASS**
Reviewed Scope: {git range, task diff, or file set reviewed}
All checks passed. Include verification evidence and any minor observations as notes.

**VERDICT: FAIL**
Reviewed Scope: {git range, task diff, or file set reviewed}
Include a structured list of issues:
- **Issue 1**: {file:line} - {description} - Severity: {high/medium/low} - Review: {Spec Compliance/Code Quality} - Suggested fix: {fix}
- **Issue 2**: ...

Group issues by the task they most closely relate to based on the manifest file ownership. This helps the orchestrator dispatch targeted fix agents.
```

## Placeholder Details

- **{review_type}**: `Spec Compliance` or `Code Quality`.
- **{wave_number}**: the current wave number, such as `2`, or `final` for the full-feature review.
- **{requirements}**: full text of `requirements.md`.
- **{design}**: full text of `design.md`.
- **{task_summaries}**: for each task in the wave, include the task title, manifest entry, task file content, files created/modified, verification evidence, coder or fixer completion summary, and simplifier summary and verification evidence.
- **{review_scope}**: the concrete git range, task diff, or exact file set the reviewer must inspect.
- **{verification_commands}**: the task-specific commands from `spec.json` for spec compliance, or the project-level lint/typecheck/test commands for code quality.
