# Smoke Checks

This playbook names the local checks that prove each `s-kit` workflow or packaging surface. A smoke check is a contract: it should be deterministic, local, and clear about what it proves.

## Commands

| Surface | Command | Proves |
|---------|---------|--------|
| OpenCode plugin syntax | `node --check .opencode/plugins/s-kit.js` | The OpenCode plugin JavaScript parses. |
| Branding and retired paths | `npm run verify:branding` | Old project names and retired branding paths have not leaked back in. |
| Assets | `npm run verify:assets` | Required icons and declared asset paths exist. |
| Agents | `npm run verify:agents` | Agent catalog files are present and structurally valid. |
| Skill names | `npm run verify:naming` | Skill names and folder names match the expected naming rules. |
| Workflow artifacts | `npm run verify:workflow` | Design/spec artifacts, task manifests, review contracts, and workflow invariants are consistent. |
| Hooks | `npm run verify:hooks` | Hook definitions and session-start wiring match the supported harness contracts. |
| Packaging doctor | `npm run doctor` | Cross-harness manifests, package scripts, required surfaces, and packaging hygiene are valid. |
| Full smoke suite | `npm run smoke` | Runs the repository smoke contract. Currently aliases `npm test`. |
| Full test suite | `npm test` | Runs every committed local verification gate. |

## Rules

- Prefer adding a named smoke check to this file before adding a new release or packaging surface.
- Keep smoke checks local. Do not require network access or installed third-party harnesses.
- If a check cannot run in every environment, document the precondition and keep it out of `npm test`.
- When `npm test` is blocked by an unrelated pre-existing artifact, record the blocker and run the narrow check that proves the changed surface.

## Related Playbooks

- [Agent Doc Writing Quality](./agent-doc-writing-quality.md)
