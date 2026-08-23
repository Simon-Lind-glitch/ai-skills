# ai-skills

Simon's curated collection of [Agent Skills](https://www.skills.sh) for Claude Code, packaged as a single installable plugin.

Each skill is a folder under [`skills/`](skills/) containing a `SKILL.md` (plus any supporting files). The repo doubles as a **Claude Code plugin marketplace** so the whole set installs with one command.

## Included skills

| Skill | What it does | Source |
| --- | --- | --- |
| [`clean-code`](skills/clean-code/) | Apply Robert C. Martin's *Clean Code* principles — naming, small functions, error handling, code smells. | [ClawForge](https://github.com/jackjin1997/ClawForge) |
| [`code-commenting`](skills/code-commenting/) | When and how to comment — the non-obvious "why", placement that survives refactors, comments readable in 10 months. Pairs with `clean-code`. | Team convention |
| [`tdd`](skills/tdd/) | Test-driven development: red → green → refactor, behavior-focused tests, vertical slices. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [`codebase-design`](skills/codebase-design/) | Shared vocabulary for deep modules — interface, depth, seam, adapter, leverage, locality — plus deepening strategy and the design-it-twice pattern. Referenced by `tdd` and `clean-code`. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| [`git-conventions`](skills/git-conventions/) | Branch names from Jira tickets, Conventional Commits, and conventional MR titles that drive semantic release. | Team convention |
| [`devcontainer-setup`](skills/devcontainer-setup/) | Get a devcontainer in place before development, so the agent runs sandboxed away from host credentials. Asks first; not a hard gate. | Team convention |

## Install

Add this repo as a marketplace, then install the plugin. All skills come with it.

```text
/plugin marketplace add Simon-Lind-glitch/ai-skills
/plugin install ai-skills@ai-skills
```

Verify with `/plugin` (it should show `ai-skills` as enabled). The skills then activate automatically when a task matches their description.

## Adding more skills

This is a vendored collection — the skill files live in this repo, so nothing breaks if an upstream repo disappears. To add a skill:

1. Copy its folder into `skills/<skill-name>/` (must contain a `SKILL.md` with `name` and `description` frontmatter).
2. Add a row to the table above and note the source, for attribution.
3. Commit and push. Then run `/plugin marketplace update ai-skills` to pick it up (a fresh install gets it automatically).

No change to `plugin.json` or `marketplace.json` is needed — every folder under `skills/` is discovered automatically.

## Credits

The skills here are authored by their upstream maintainers (linked in the table above) and vendored for convenience. All credit for the skill content goes to them.
