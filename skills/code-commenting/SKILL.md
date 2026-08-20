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
