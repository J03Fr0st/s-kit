# Porting `s-kit` to a New Harness

Use this playbook when adding support for a new IDE, CLI, editor extension, or
agent runner. A harness port is complete only when `s-kit` can be installed,
discovered, invoked, verified, and released through the harness without
weakening the canonical workflow:

```text
brainstorming -> plan-feature -> build-feature -> verification/review -> ship
```

Treat the harness as an adapter around `s-kit`. Do not reshape shared skills to
fit one host.

## Non-Negotiables

- Do not edit shared skill bodies for one harness. Put runtime-specific behavior
  in harness manifests, install scripts, references, adapters, or tests.
- Do not require manual user config edits when the harness has a plugin,
  extension, package, or declared install path.
- Keep runtime-specific tool mapping in `skills/using-s-kit/references/` or in a
  harness-specific surface. Shared skill prose should use action-language.
- Preserve canonical `s-kit` names and paths. Do not reintroduce retired
  upstream names or legacy workflow aliases.
- Make the port verifiable from a clean local install. A maintainer should not
  need private shell history or chat context to validate it.

## 1. Harness Discovery

Start by identifying how the harness models reusable agent behavior.

Record:

- The harness name, version, and documentation source used for the port.
- Whether it supports bundled skills, agents, prompts, hooks, commands,
  extensions, or only plain files.
- The expected package layout and any reserved manifest filenames.
- Whether the harness loads content from a repo checkout, installed plugin
  cache, user config directory, marketplace package, or generated bundle.
- How the harness reports load failures.

Prefer current local harness behavior over assumptions from another runtime. If
support is version-dependent, document the minimum known-working version and add
a doctor check when practical.

## 2. Install Mechanism

Define the install path before writing integration files.

Answer these questions:

- Is the install mechanism a plugin manifest, extension manifest, package
  archive, copy script, symlink, marketplace entry, or generated cache?
- Which files are included by default, and which must be explicitly listed?
- Can the harness install hooks, agents, skills, and references through the same
  path?
- Does install overwrite user-managed files, or does it install into a managed
  package location?
- How can a local checkout be installed for verification before release?

If a plugin or extension install path exists, use it. Do not ask users to paste
snippets into personal config as the primary install flow.

## 3. Skill Discovery and Invocation

Verify how the harness discovers and invokes `s-kit` skills.

Check:

- Where skill metadata is read from.
- Which fields trigger skill discovery, such as `name`, `description`, or
  manifest entries.
- Whether the harness supports namespaced plugin skills.
- Whether skill bodies are loaded lazily or at session start.
- How explicit user requests, natural-language triggers, and subagent prompts
  invoke a skill.
- Whether the harness exposes a dedicated skill invocation tool or expects the
  model to read local files.

The port should preserve the shared `s-kit` skill contract. If a harness needs
different invocation wording, place that wording in the harness adapter or
reference mapping, not in every skill body.

## 4. Bootstrap and Session Start

Identify what the harness loads at session start and what must be declared in
the plugin package.

Verify:

- Whether there is a session-start hook, bootstrap prompt, system extension,
  project instruction file, or startup command.
- Whether bootstrap content can be bundled with the plugin.
- Whether startup failures are visible to the user or only logged.
- Whether the bootstrap path works from both a source checkout and an installed
  package.
- Whether startup content points users to `skills/using-s-kit/SKILL.md` and the
  canonical workflow.

Bootstrap should orient the harness to `s-kit`; it should not duplicate long
skill bodies or create a second source of truth.

## 5. Tool Mapping

Map shared action-language operations to harness-native tools.

At minimum, document mappings for:

- Read a file.
- Edit a file.
- Run a shell command.
- Search files or text.
- Create or update a todo/checklist.
- Dispatch a subagent or explain that no subagent tool exists.
- Open or automate a browser, if supported.
- Inspect git status, diff, and logs.
- Ask the user for a decision.

Keep the mapping in `skills/using-s-kit/references/` or the harness-specific
package surface. Shared skill bodies should say what action is needed, while
the mapping says how that harness performs it.

## 6. Acceptance Tests

Add tests that prove the harness can load and use the port. Favor small,
behavior-focused checks over brittle snapshots.

Useful acceptance checks include:

- The harness manifest parses.
- All declared files exist.
- Packaged paths resolve from the install location, not only the repo root.
- Core skills are discoverable by name and description.
- Explicit invocation of `brainstorming`, `plan-feature`, and `build-feature`
  routes to the expected skill metadata.
- Bootstrap/session-start files are included and point to the canonical workflow.
- Tool mapping references exist and mention the harness-native operations.
- No test requires manual edits to user config.

For a harness with executable hooks, include at least one smoke test proving the
hook file is packaged and can be invoked or parsed in the expected environment.

## 7. Local Install Verification

Before opening a PR, verify the integration from a local install path rather
than only from source files.

Run the harness-specific install command or packaging script, then confirm:

- The installed package contains the manifest, skills, references, hooks, and
  assets expected by the harness.
- The harness can start a new session with the installed package.
- The startup path does not depend on absolute paths from your machine.
- A simple skill discovery request finds `s-kit`.
- A no-op or dry-run workflow request does not mutate unrelated files.
- Uninstall or reinstall behavior does not leave stale generated files that
  change the result.

Record any host limitation in the PR if the harness cannot be fully exercised
locally.

## 8. Distribution and Release Checks

Update release surfaces only after local install verification works.

Check:

- Plugin or extension manifests include the new harness files.
- Package ignore/include rules do not drop required references or hooks.
- `scripts/doctor.ps1` covers the new manifest or install files when practical.
- Existing verification scripts still pass.
- Version checks and release packaging include the harness-specific files.
- Documentation names the supported harness without making it the default for
  every user.

Do not mark the port complete if the source checkout works but the packaged
artifact omits required files.

## Port Checklist

- [ ] Identify the harness install mechanism.
- [ ] Identify how the harness discovers skills.
- [ ] Identify how bootstrap/session-start context is loaded.
- [ ] Map action-language operations to native tools.
- [ ] Add or update plugin manifest files.
- [ ] Add local install verification.
- [ ] Add packaging/doctor checks.
- [ ] Run `npm test` and `npm run doctor`.

## PR Readiness

Before opening a PR, include:

- The harness and version tested.
- The local install command or packaging command used.
- The exact verification commands and results.
- Any unsupported harness behavior and the fallback path.
- Confirmation that shared skill bodies were not edited only to satisfy this
  harness.
- Confirmation that no manual user config edit is required when a plugin install
  path exists.
