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
_Avoid_: automatic skill, ambient skill

**Vendored skill**:
A **Skill** whose content originates in an upstream project and is copied in rather than
referenced. `README.md` records its source and licence status.

**Forge**:
The host of a repo's change-review workflow: GitHub or GitLab. Named as one thing because
`lensed-review` detects which is in play and binds its commands accordingly.
_Avoid_: provider, remote, platform

**Lens**:
One agent's single-perspective mandate inside `lensed-review`, carrying an explicit NOT
list. Nine exist; a run selects a subset.

## Relationships

- A **Plugin** ships many **Skills**, and exactly those its `skills` array lists
- A **Marketplace** offers a **Plugin**
- Every **Skill** is either **User-invoked** or **Model-invoked**, never both
- A **Vendored skill** is a **Skill** with an upstream source
- `lensed-review` runs many **Lenses** against one **Forge** target, or against a local diff

## Deferred vocabulary

Module, interface, depth, seam, adapter, leverage, and locality are defined once in
[`codebase-design`](skills/codebase-design/SKILL.md) and are not redefined here. Use that
skill's definitions everywhere in this repo.

## Flagged ambiguities

- "MR" vs "PR". `git-conventions` says **merge request** because the team's forge is
  GitLab; `lensed-review` covers both. Resolved: keep the forge's own word when describing
  that forge, and write "the PR or MR" only where a skill genuinely spans both. Do not
  coin a neutral third term.
- "command" vs "skill". Resolved: **Skill** always, qualified as **User-invoked** where
  the distinction matters. `commands/` is not a directory this repo uses.
- "review" alone was ambiguous between the `lensed-review` skill and the human act.
  Resolved: name the skill when you mean the skill.
