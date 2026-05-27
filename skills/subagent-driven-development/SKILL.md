---
name: subagent-driven-development
description: "Compatibility wrapper. Parallel implementation now runs through implement-feature."
---

# Compatibility Wrapper

`subagent-driven-development` is not a separate `s-kit` workflow.

Parallel implementation is handled by `implement-feature`, which reads `docs/specs/YYYY-MM-DD-{feature-name}/` plus the matching `docs/design/YYYY-MM-DD-{feature-name}/design.md`, executes task waves, runs spec-compliance review before code-quality review, and tracks progress in `spec.json`, task files, README checkboxes, and `implementation-log.md`.

If a user explicitly asks for this skill, redirect to `implement-feature` unless they ask to stop. If the matching design or spec is missing, redirect to `brainstorming` or `create-spec` first.
