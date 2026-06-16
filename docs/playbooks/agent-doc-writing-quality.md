# Agent Doc Writing Quality

Use this checklist when creating or editing skills, prompts, agents, and playbooks. It is a review aid, not a hard natural-language linter.

## Checklist

- State the trigger, input, action, and expected output concretely.
- Prefer direct instructions over motivational framing.
- Use stable project terms from the relevant docs or code.
- Name the exact files, commands, statuses, or artifacts an agent must use.
- Keep examples tied to real workflow behavior.
- Remove inflated claims such as "comprehensive", "seamless", or "best-in-class" unless the text proves them.
- Remove filler openers and closers such as "great question", "let's dive in", and "hope this helps".
- Avoid fake certainty. If something is an assumption, label it as an assumption.
- Avoid diff narration when durable behavior is clearer. Say what the workflow does now, not just what was added.
- Keep guardrails actionable. A reviewer should be able to point to a line and say what to change.

## Review Questions

1. Could an agent follow this without reading the conversation that produced it?
2. Does every required action have a concrete verification path?
3. Are judgment calls separated from mechanical checks?
4. Is any sentence trying to sound impressive instead of making the workflow clearer?

## Non-Goals

- Do not rewrite established project terminology just to sound more casual.
- Do not reject clear technical prose because it is concise.
- Do not add an automated prose linter until repeated review failures justify one.
