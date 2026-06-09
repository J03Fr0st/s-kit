# Coder Agent Prompt Template

Use this template when constructing prompts for coder subagents. Replace the placeholders (`{requirements}`, `{design}`, `{spec_manifest}`, `{completed_tasks_summary}`, `{task_content}`) with actual content from the spec files.

## Template

```
You are implementing a single task from a feature specification. Your job is to write the code described below — nothing more, nothing less.

## Feature Context

{requirements}

## Approved Design

{design}

## Wave Risk Preflight

{wave_risk_preflight}

## Spec Manifest Entry

{spec_manifest}

## What's Already Been Built

{completed_tasks_summary}

## Your Task

{task_content}

## Instructions

1. Read the relevant parts of the codebase to understand existing patterns, imports, and conventions
2. Implement everything described in the task's Technical Details and Implementation Steps
3. Account for the Wave Risk Preflight contracts while staying within this task's scope
4. Follow the project's existing code patterns and conventions
5. Run the RED, GREEN, and Final Verification commands from the task's Verification Plan and manifest entry where they apply. Fix any errors before finishing.
6. Do NOT commit your changes
7. When done, report:
   - Files created (with paths)
   - Files modified (with paths)
   - Verification commands run, with pass/fail results
   - Final task status recommendation: `complete`, `blocked`, `needs-context`, or `done-with-concerns`
   - Any concerns, skipped checks, or follow-up needed
   - A one-paragraph summary of what you implemented
```

## Placeholder Details

- **{requirements}**: paste the full text of `requirements.md`. This gives the agent overall feature context — the "what" and "why" — so it can make good judgment calls during implementation.

- **{design}**: paste the full text of `design.md`. This gives the agent the approved solution shape and architectural decisions.

- **{wave_risk_preflight}**: paste the Wave Risk Preflight for the current wave. This is a short list of shared contracts and integration risks the agent must account for without widening scope.

- **{spec_manifest}**: paste the relevant task entry from `spec.json` plus the global path and status rules. This keeps task ID, wave, file ownership, and verification commands explicit.

- **{completed_tasks_summary}**: for each previously completed task, include a brief summary like:
  ```
  - task-01-setup-database: Created PostgreSQL schema with users and sessions tables. Files: src/db/schema.ts, src/db/migrations/001_initial.sql
  - task-02-auth-config: Set up Better Auth with email/password provider. Files: src/lib/auth.ts, src/lib/auth-client.ts
  ```
  Keep each entry to 1-2 lines. The purpose is to give the agent awareness of what exists, not full implementation details.

- **{task_content}**: paste the full text of the task file (task-{nn}-{name}.md). This is the agent's primary instruction set — it contains the description, technical details, files to create/modify, and acceptance criteria.
