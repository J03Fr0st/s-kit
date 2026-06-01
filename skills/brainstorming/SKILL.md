---
name: brainstorming
description: "Use before creative or behavior-changing work. Clarifies intent, explores options, writes a design file for approval, then stops before plan-feature."
---

# Brainstorming Ideas Into Designs

Use this skill to turn a rough idea into an approved design before implementation starts.

<HARD-GATE>
Do not invoke implementation skills, write code, scaffold projects, or make behavior changes until you have presented a design and the user has approved it.
</HARD-GATE>

## Checklist

Complete these in order:

1. Explore project context: files, docs, recent commits, and relevant specs.
2. Offer the visual companion if upcoming questions would be easier with mockups or diagrams.
3. Ask clarifying questions one at a time.
4. Propose 2-3 approaches with trade-offs and a recommendation.
5. Present the proposed design in sections and confirm it is ready to be written for review.
6. Choose the dated feature folder name and write the draft design to `docs/design/YYYY-MM-DD-{feature-name}/design.md` using the structure in `references/design-template.md`.
7. Write `design.md` as the review artifact before final approval, then stop. Do not invoke `plan-feature` in the same turn. Report the design path, ask the user to review and approve the file, and offer `grill-me` as an optional review step after writing the design file.
8. If the user wants `grill-me`, run it against the written design file before approval. This is optional; do not block normal approval if the user declines.
9. Only after the user approves the written design file and separately asks to continue, hand off to `plan-feature` with that exact design path so it can expand the design into requirements, manifest, execution log, orchestration, and task files under the matching `docs/specs/YYYY-MM-DD-{feature-name}/` folder.
10. Ask the user to review the written spec before implementation with `build-feature`.

## Process

Start with the current project state. If the request is too broad for one spec, decompose it and brainstorm the first independently shippable piece.

Ask one question per message. Prefer multiple choice when it makes the decision easier. Focus on purpose, constraints, success criteria, dependencies, and what should be explicitly out of scope.

When you understand the work, propose approaches. Lead with the recommended approach and explain why. Keep the trade-offs practical: implementation effort, risk, future flexibility, and how well the approach fits the repo.

Present the proposed design after the approach is selected. Scale the depth to the work. Cover architecture, components, data flow, error handling, verification, and rollout where relevant.

When the proposed design is ready for review, write `design.md` first, then stop. Write `design.md` as the review artifact before final approval, then stop. Do not invoke `plan-feature` in the same turn. Offer `grill-me` as an optional review step after writing the design file. `brainstorming` owns the dated folder name. `plan-feature` must reuse that same folder name for the spec only after the user approves the written design file and explicitly asks to continue.

```text
docs/design/YYYY-MM-DD-{feature-name}/
└── design.md

docs/specs/YYYY-MM-DD-{feature-name}/
├── README.md
├── spec.json
├── requirements.md
├── action-required.md
├── implementation-log.md
└── tasks/
    ├── task-01-{name}.md
    └── task-02-{name}.md
```

`design.md` is the direct output of brainstorming. Follow `references/design-template.md`. It should capture the proposed solution shape for review: context, selected approach, alternatives considered, architecture, major decisions, open risks, and verification strategy. It becomes the approved design only after the user reviews the file and approves it. `grill-me` can be offered after the file exists to stress-test the written design, but it is optional. `plan-feature` uses it as the source material for `requirements.md`, `README.md`, `spec.json`, `implementation-log.md`, and task files only after the user explicitly requests spec creation in a follow-up. After the spec is reviewed, `build-feature` executes it wave by wave.

## Visual Companion

If visual questions are likely, offer this exact message by itself:

> Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)

Wait for the user's response. If accepted, use visuals only for questions that are genuinely clearer when seen rather than read.
