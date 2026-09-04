---
name: docs-sync
description: Find and fix the documentation a code change makes stale — README, CLAUDE.md, AGENTS.md, docs/, samples — in the same commit as the change. Use when finishing any change that renames, removes, or alters something a doc could mention — commands, flags, config keys, env vars, endpoints, file paths, install or usage steps — or when adding behavior that needs documenting.
---

# Docs Sync

A change is not done while a doc it contradicts still ships. Documentation updates belong
in the same commit as the change that makes them necessary — a follow-up task called
"update the docs" is where stale docs come from.

This skill owns finding what a change made stale and deciding each hit's fate. The
[`code-commenting`](../code-commenting/SKILL.md) skill owns how the surviving prose is
written: describe what is, not what changed.

## Find the stale docs mechanically

A memory of which docs mention the thing you changed is exactly what goes stale. Search
instead:

1. List the names the change touched — renamed, removed, or changed in behavior:
   commands, subcommands, flags, config keys, env vars, endpoints and routes, file paths,
   exported functions and types that docs quote, error messages a doc tells the reader to
   look for.
2. Grep every one of them, old name and new, across the prose:

   ```bash
   git grep -nE "<name1>|<name2>" -- '*.md' docs '*.example*' '*.sample*'
   ```

3. Include the instruction files — `README.md`, the `CLAUDE.md` / `AGENTS.md` chain, and
   anything they link — and the runnable prose: code blocks inside docs, sample configs,
   and scripts a doc tells the reader to run. Those execute in the reader's head or shell,
   so a stale one fails louder than a stale sentence.

## Three fates per hit

- **Update** it to describe the system that now exists, per code-commenting's rules: no
  "now uses", no "no longer", no narration of the edit.
- **Delete** it when it documents something gone. Removals leave no trace in docs; they
  live in version control.
- **Leave** it only in genuinely historical documents: a changelog, an ADR, release notes.

## New behavior needs a home

- Put the doc where a reader would look for it, at the same altitude as its siblings — a
  new flag joins the flags list rather than opening a new section.
- One source of truth. If the fact is already written somewhere, link to it instead of
  restating it: a fact written twice is a doc that will be stale in one of the places.
- Self-documenting code does not exempt the prose. Clean code reaches the person already
  reading the code; the README reaches the person deciding whether to.
- **Sync is not expansion.** Match the depth the repo already documents at: if sibling
  features get one line, the new one gets one line, and if the repo documents nothing at
  this altitude, add nothing. A thin docs tradition is the repo's choice, not a gap this
  skill fills — the bar is "would a reader be misled or blocked", never completeness.

## Verify before committing

Re-run the grep for the old names and expect zero hits outside the historical documents.
If the repo lints or builds its docs, run that too. Then commit the doc changes with the
code change, not after it.
