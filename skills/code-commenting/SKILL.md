---
name: code-commenting
description: When and how to write code comments — comment the non-obvious "why", not the "what"; place comments where a refactor could break something; keep them readable in 10 months. Use whenever writing, reviewing, or editing comments and doc comments. Pairs with the clean-code skill.
---

# Code Commenting

How to decide whether a comment should exist, and how to write it so it still helps someone reading the code much later. Use this alongside the [`clean-code`](../clean-code/SKILL.md) skill — clean-code covers naming, functions, and structure that often remove the need for a comment in the first place; this skill covers the comments that remain.

## Comments

- Only comment the non-obvious "why" or missing context. Never restate what the code does.
- A test or a better name beats a comment when either will do.
- Put the comment on the line that is easy to get wrong, not at the top of the function. Its job is to stop a plausible refactor from breaking something.
- Doc comments only on public/exported API, so a caller can skip reading the implementation.
- Write for someone reading in 10 months. Describe the constraint, not today's task. No "new", "for now", "temporary", "recently changed", no sprint or migration status, no dates.
- Do not name Jira tickets or MRs by default. Only when the ticket holds context that does not fit in one line and will still matter later.
- Reading rule: do not open a Jira ticket just because a comment names one. Only if the current task actually needs it.
- Plain english. One or two lines. If it needs a paragraph, the code or the test is the wrong shape.
- While editing code, delete or fix any nearby comment you cannot verify.

## Describe what is, not what changed

When you change code, the comment (or doc) must describe the state that now exists — not narrate the edit. A reader ten months from now has no memory of the old version, so any reference to it is noise at best and misleading at worst.

- Never write what the code *no longer* does: no "we used to X", "this replaces the old Y", "changed from Z". The diff and git history already record the change; the comment should not.
- Do not mention the absence of something that does not exist. Explaining why a removed flow "is no longer modelled here" only raises a question — what flow? — about something the reader was never going to look for. If it does not exist, it does not belong in the doc.
- Describe the mechanism as it stands, as if it had always been this way. Rewrite "now uses a queue instead of polling" as "uses a queue".
- Same rule for design docs and READMEs: document the system that exists, not a changelog of what it used to be. Removals leave no trace in the doc; they live in version control.
- Exception: keep a note only when the *reason* for a removal is a live constraint that will bite someone who tries to add it back — e.g. "no retry here: the endpoint is not idempotent". That documents a present constraint, not a past state.
