---
name: executing-plans
description: "Compatibility wrapper. Use implement-feature instead for executing specs."
---

# Compatibility Wrapper

`executing-plans` is not a separate `s-kit` workflow.

For implementation, use `implement-feature` against a dated spec folder and its matching approved design. The spec folder must include `spec.json`, `implementation-log.md`, requirements, action-required notes, and task files:

```text
docs/specs/YYYY-MM-DD-{feature-name}/
docs/design/YYYY-MM-DD-{feature-name}/design.md
```

If a user explicitly asks for `executing-plans`, explain that `s-kit` executes specs through `implement-feature`. If the matching design or spec is missing, redirect to `brainstorming` or `create-spec` first unless the user asks to stop.
