---
name: writing-plans
description: "Compatibility wrapper. Use create-spec instead for new work."
---

# Compatibility Wrapper

`writing-plans` is not a separate `s-kit` workflow.

For new work, start with `brainstorming` unless an approved design already exists. `create-spec` only runs after there is an approved `docs/design/YYYY-MM-DD-{feature-name}/design.md`, and writes dated, self-contained task specs with a manifest and implementation log under:

```text
docs/specs/YYYY-MM-DD-{feature-name}/
```

If a user explicitly asks for `writing-plans`, explain that `s-kit` has replaced standalone plan files with `create-spec`. If no approved design exists, invoke `brainstorming`; otherwise invoke `create-spec` unless the user asks to stop.
