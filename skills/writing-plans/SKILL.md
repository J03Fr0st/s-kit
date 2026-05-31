---
name: writing-plans
description: "Workflow redirect. Use plan-feature instead for new work."
---

# Workflow Redirect

`writing-plans` is not a separate `s-kit` workflow.

For new work, start with `brainstorming` unless an approved design already exists. `plan-feature` only runs after there is an approved `docs/design/YYYY-MM-DD-{feature-name}/design.md`, and writes dated, self-contained task specs with a manifest and implementation log under:

```text
docs/specs/YYYY-MM-DD-{feature-name}/
```

If a user explicitly asks for `writing-plans`, explain that `s-kit` has replaced standalone plan files with `plan-feature`, followed by `build-feature` for execution. If no approved design exists, invoke `brainstorming`; otherwise invoke `plan-feature` unless the user asks to stop.
