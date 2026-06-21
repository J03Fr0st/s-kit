# Context: s-kit

## Purpose

s-kit is an agent workflow kit for turning ambiguous work into durable design, spec, implementation, review, and delivery artifacts.

## Glossary

### Skill

A reusable agent instruction package that defines when and how to apply a focused workflow or technique.

_Avoid_: command, prompt, script

### Lane

A scale-aware workflow route that chooses the right amount of ceremony for a request.

_Avoid_: mode, path, process

### Design

An approved solution shape captured under `docs/design/YYYY-MM-DD-{feature-name}/design.md`.

_Avoid_: plan, spec

### Spec

A task orchestration bundle under `docs/specs/YYYY-MM-DD-{feature-name}/` derived from an approved design.

_Avoid_: implementation plan, ticket list

### Task

A self-contained implementation unit inside a spec that one agent can execute from its task file.

_Avoid_: step, subtask

### Phase

A dependency level of tasks that can run in parallel when they do not overlap file ownership.

_Avoid_: batch, round

### Phase Risk Preflight

A read-only contract scan before a build phase that identifies shared contracts, integration risks, security-sensitive surfaces, and glossary or ADR constraints.

_Avoid_: review, audit

### Context

A glossary scope for project or bounded-context language, captured in `CONTEXT.md` or mapped from `CONTEXT-MAP.md`.

_Avoid_: notes, spec, requirements

### ADR

A durable decision record for hard-to-reverse, surprising trade-offs that future agents should not silently relitigate.

_Avoid_: meeting note, preference
