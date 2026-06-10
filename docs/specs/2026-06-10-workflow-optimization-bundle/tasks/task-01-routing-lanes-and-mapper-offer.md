# Task 01: Routing Lanes and Codebase-Mapper Offer

## Status

complete

## Wave

1

## Description

Add an explicit small-change lane table to `using-s-kit` so bugfixes, refactors/doc changes, and hotfixes have a documented path that skips the dated spec folder, and update `brainstorming` to (a) reroute requests that match a small lane instead of starting a design, and (b) offer the `s-kit-codebase-mapper` agent as an optional preparation step for unfamiliar repos. Today every change routes through brainstorm → design → spec → waves, and the codebase-mapper agent is shipped but never invoked by any skill.

## Dependencies

**Depends on:** None (Wave 1)
**Blocks:** None

**Context from dependencies:** None. This task is self-contained: it edits two skill markdown files. The `s-kit-codebase-mapper` agent already exists at `agents/s-kit-codebase-mapper.md` (read-only mapper producing Scope/Architecture/Conventions/Relevant Files/Risks/Recommended Next Step reports) — this task only adds the invocation guidance, it does not change the agent.

## Files to Create

None.

## Files to Modify

- `skills/using-s-kit/SKILL.md` — add a "Lanes" section with the lane table and boundary rule after the "Canonical Workflow" section.
- `skills/brainstorming/SKILL.md` — add the lane-reroute note and the optional codebase-mapper offer.

## Technical Details

### Implementation Steps

1. In `skills/using-s-kit/SKILL.md`, directly after the existing `## Canonical Workflow` section (which ends with the `build-feature` bullet), add a new section:

   ```markdown
   ## Lanes

   Not every change needs the full dated design/spec ceremony. Pick the lane by the nature of the change:

   | Lane | Criteria | Path |
   |------|----------|------|
   | Full feature | New behavior, multi-file change, or any change needing design decisions | `brainstorming` -> `plan-feature` -> `build-feature` |
   | Bug fix | Defect with reproducible wrong behavior, roughly 3 files or fewer | `systematic-debugging` -> `test-driven-development` -> `verification-before-completion` |
   | Refactor / docs | No behavior change | refactor or direct edit -> `verification-before-completion` |
   | Hotfix | Urgent production defect | bug-fix lane with user-approved expedited review; log a follow-up for the skipped steps |

   Small-lane changes skip the dated spec folder. The audit trail is the commit plus the verification evidence those skills already require.

   **Boundary rule:** if a small-lane change starts sprouting design questions or exceeds the file budget, stop and route to `brainstorming`. When in doubt, use the full feature lane.
   ```

2. Keep the existing "Canonical Workflow" text intact — the lane table supplements it; the full pipeline remains the default for creative or behavior-changing work.

3. In `skills/brainstorming/SKILL.md`, in the `## Process` section (which currently begins "Start with the current project state."), add two short paragraphs:

   - After the sentence about decomposing broad requests, add the reroute note:

     ```markdown
     If the request matches a small lane in `using-s-kit` (bug fix, refactor/docs, or hotfix), say so and route to that lane instead of starting a design. Brainstorming is for work that needs design decisions.
     ```

   - In the project-exploration guidance (checklist item 1 territory — "Explore project context"), add the mapper offer:

     ```markdown
     For an unfamiliar or large repository, offer to dispatch the `s-kit-codebase-mapper` agent first. It returns an evidence-backed map (architecture, conventions, relevant files, risks) that grounds the clarifying questions and design. This is optional; skip it when the project is already well understood.
     ```

4. Match the surrounding tone and formatting of each file (both use plain imperative prose, `## ` sections, and fenced text blocks). Read both files fully before editing.

5. Do not rename, remove, or reorder existing sections — `hooks/session-start` reads `skills/using-s-kit/SKILL.md` and other tooling greps it; additions only.

## Verification Plan

### RED

- Command: `powershell -NoProfile -Command "if (Select-String -Path 'skills/using-s-kit/SKILL.md' -Pattern 'Boundary rule' -Quiet) { exit 1 } else { exit 0 }"`
- Expected: exits 0 before implementation (no Lanes section exists yet), proving the gap.

### GREEN

- Command: `powershell -NoProfile -Command "(Select-String -Path 'skills/using-s-kit/SKILL.md' -Pattern '## Lanes' -Quiet) -and (Select-String -Path 'skills/using-s-kit/SKILL.md' -Pattern 'Boundary rule' -Quiet) -and (Select-String -Path 'skills/brainstorming/SKILL.md' -Pattern 's-kit-codebase-mapper' -Quiet) -and (Select-String -Path 'skills/brainstorming/SKILL.md' -Pattern 'small lane' -Quiet)"`
- Expected: outputs `True` — lane table, boundary rule, mapper offer, and reroute note all present.

### Final Verification

- Command: `npm test`
- Expected: all verification gates pass (branding, assets, agents, naming, workflow).

## Acceptance Criteria

- [ ] `using-s-kit` has a Lanes section with exactly four lanes (full feature, bug fix, refactor/docs, hotfix), each with criteria and a path built from existing skills.
- [ ] The boundary rule (route to brainstorming when design questions appear or the file budget is exceeded) is stated.
- [ ] `brainstorming` reroutes lane-matching requests instead of starting a design.
- [ ] `brainstorming` offers `s-kit-codebase-mapper` as an optional preparation step for unfamiliar repos.
- [ ] No existing sections of either file were removed or reordered.
- [ ] `npm test` passes.

## Notes

The small-change lane is deliberately routing documentation only — no new skill, no mini-spec artifact. This was an explicit design decision ("Routing rules only") to keep the skill catalog compact.
