---
name: waitwhat
description: "Stop. That last message did not land: re-pitch it."
argument-hint: "[what did not land]"
disable-model-invocation: true
---

# Wait, What

Wait. I do not understand where you have got to here. Re-pitch it.

`$ARGUMENTS` names the part that did not land. With no argument, re-pitch the whole last
message.

- Give the context that is missing, including the premise you assumed the reader already
  had.
- Write in ASD-STE100 Simplified Technical English.
- Use the ubiquitous language the project already has: `CONTEXT.md`, `CLAUDE.md`, the
  README, the ADRs, the code. Do not coin a term where the repo has one.
- Lead with the point. One idea per sentence.

Change nothing and re-run nothing. This is a report that the explanation did not land, not
that the work was wrong, so a fresh attempt at the task is the wrong response.
