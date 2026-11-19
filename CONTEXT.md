# ai-skills

A collection of agent skills packaged as a single Claude Code plugin, vendored in-tree so
nothing breaks when an upstream repo moves or disappears.

## Language

**Skill**:
A directory under `skills/` containing a `SKILL.md` and any supporting files. The unit this
repo ships. Since custom commands merged into skills, there is no separate "command" here:
what used to be one is a **User-invoked skill**.
_Avoid_: command, prompt, rule, instruction file

**Plugin**:
The whole shipped set, described by `.claude-plugin/plugin.json`. A **Skill** ships only if
`plugin.json`'s `skills` array lists it.
_Avoid_: package, extension, bundle

**Marketplace**:
The catalogue declared by `.claude-plugin/marketplace.json`. This repo is its own
single-plugin marketplace, which is what lets it be installed directly from a clone.

**User-invoked skill**:
A **Skill** reachable only when a human types `/name`, declared with
`disable-model-invocation: true`. Used where firing unbidden would be expensive or
presumptuous.
_Avoid_: manual skill, explicit skill

**Model-invoked skill**:
A **Skill** the agent may load on its own when its `description` matches the task. The
default, and the reason a description is written as trigger conditions rather than a
summary.

**Model-suggested skill**:
A **Model-invoked skill** that asks the user before it does anything, from an "Ask first"
section at the top of its `SKILL.md`. The question is skipped when the user typed the
skill, or when another skill loaded it. Used where firing unbidden would be expensive, but
forgetting to type the skill costs more.
_Avoid_: gated skill, confirm skill
_Avoid_: automatic skill, ambient skill

**Vendored skill**:
A **Skill** whose content originates in an upstream project and is copied in rather than
referenced. `README.md` records its source and licence status.

**Forge**:
The host of a repo's change-review workflow: GitHub or GitLab. Named as one thing because
the daily skills detect which is in play and bind their commands accordingly.
_Avoid_: provider, remote, platform

**Round**:
One pass of `review-loop`: one review, then the fixes for its **Blocking findings**, each
stopped at a **Checkpoint** and committed when the user accepts it. A run has 10 rounds at
most.

**Checkpoint**:
A stop of `feature` or `review-loop` with one change staged in the checkout of the user
and not committed, with an explanation of it. The skill commits the change only when the
user replies `go`. `--auto` turns the stops off.
_Avoid_: pause, gate, approval step

**Blocking finding**:
A finding that `review-loop` must fix before it stops: a score of 7 or more, a
high-severity label, or a defect with no severity given. Every finding blocks under
`--until clean`.
_Avoid_: severe finding, critical finding

## Relationships

- A **Plugin** ships many **Skills**, and exactly those its `skills` array lists
- A **Marketplace** offers a **Plugin**
- Every **Skill** is either **User-invoked** or **Model-invoked**, never both
- A **Model-suggested skill** is a **Model-invoked skill** with an "Ask first" section
- A **Vendored skill** is a **Skill** with an upstream source
- `review-loop` runs one review skill per **Round**, and stops when a **Round** has no **Blocking finding**

## Deferred vocabulary

Module, interface, depth, seam, adapter, leverage, and locality are defined once in
[`codebase-design`](skills/codebase-design/SKILL.md) and are not redefined here. Use that
skill's definitions everywhere in this repo.

## Flagged ambiguities

- "MR" vs "PR". `git-conventions` says **merge request** because the team's forge is
  GitLab; the daily skills cover both. Resolved: keep the forge's own word when describing
  that forge, and write "the PR or MR" only where a skill genuinely spans both. Do not
  coin a neutral third term.
- "command" vs "skill". Resolved: **Skill** always, qualified as **User-invoked** where
  the distinction matters. `commands/` is not a directory this repo uses.
- "review" alone was ambiguous between a review skill and the human act.
  Resolved: name the skill when you mean the skill.
