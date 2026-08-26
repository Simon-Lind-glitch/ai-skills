# ai-skills

Simon's curated collection of [Agent Skills](https://www.skills.sh) for Claude Code, packaged as a single installable plugin.

Each skill is a folder under [`skills/`](skills/) containing a `SKILL.md` (plus any supporting files). The repo doubles as a **Claude Code plugin marketplace** so the whole set installs with one command.

## Included skills

### User-invoked

Reachable only when you type them (`disable-model-invocation: true`), because firing unbidden would be expensive or presumptuous.

- **[`feature`](skills/feature/SKILL.md)**: Build a feature with the engineering standards already in context. Inlines `codebase-design`, `tdd`, `clean-code`, `code-commenting`, and `git-conventions` at load time, ordered by when each applies, and arbitrates where they contradict each other.
- **[`lensed-review`](skills/lensed-review/SKILL.md)**: Multi-angle code audit. Fans out parallel read-only lens agents, then synthesizes one scored report. Reviews the local branch by default, or a GitHub PR / GitLab MR with the forge detected from the remote. Posts only with `--post`; never approves, never merges.
- **[`setup-ai-skills`](skills/setup-ai-skills/SKILL.md)**: Wire a repo up to this plugin by writing the marketplace and plugin declaration into its `.claude/settings.json`. Run once per repo.
- **[`waitwhat`](skills/waitwhat/SKILL.md)**: Stop, that last message did not land: re-pitch it in Simplified Technical English using the project's own vocabulary. Changes nothing and re-runs nothing.

### Model-invoked

Loaded automatically when the task matches, and also reachable by typing them.

- **[`clean-code`](skills/clean-code/SKILL.md)**: Robert C. Martin's *Clean Code* principles — naming, small functions, error handling, code smells.
- **[`code-commenting`](skills/code-commenting/SKILL.md)**: When and how to comment — the non-obvious "why", placement that survives refactors, comments readable in 10 months. Pairs with `clean-code`.
- **[`codebase-design`](skills/codebase-design/SKILL.md)**: Shared vocabulary for deep modules — interface, depth, seam, adapter, leverage, locality — plus deepening strategy and the design-it-twice pattern.
- **[`devcontainer-setup`](skills/devcontainer-setup/SKILL.md)**: Get a devcontainer in place before development, so the agent runs sandboxed away from host credentials. Asks first; not a hard gate.
- **[`git-conventions`](skills/git-conventions/SKILL.md)**: Branch names from Jira tickets, Conventional Commits, and conventional MR titles that drive semantic release.
- **[`tdd`](skills/tdd/SKILL.md)**: Test-driven development: red → green → refactor, behavior-focused tests, vertical slices.

## Install

Add this repo as a marketplace, then install the plugin. All skills come with it.

```text
/plugin marketplace add Simon-Lind-glitch/ai-skills
/plugin install ai-skills@ai-skills
```

Verify with `/plugin` (it should show `ai-skills` as enabled). Model-invoked skills then activate automatically when a task matches their description; user-invoked ones wait until you type them.

To wire a specific repo up so the plugin loads for everyone who clones it, run `/ai-skills:setup-ai-skills` inside it.

## Adding more skills

This is a vendored collection — the skill files live in this repo, so nothing breaks if an upstream repo disappears. To add a skill:

1. Copy its folder into `skills/<skill-name>/` (must contain a `SKILL.md` with `name` and `description` frontmatter).
2. Add it to the `skills` array in `.claude-plugin/plugin.json`. The plugin ships exactly what that array lists, so a folder that is not in it is not installed.
3. Add a bullet to the matching section above, under **User-invoked** or **Model-invoked** depending on whether its frontmatter carries `disable-model-invocation: true`.
4. Record its source and licence in the table below.
5. Run `claude plugin validate . --strict`, then commit and push. Run `/plugin marketplace update ai-skills` to pick it up in a running session (a fresh install gets it automatically).

## Sources and licensing

The original work in this repo is MIT ([`LICENSE`](LICENSE)). Vendored skills remain under their upstream terms:

| Skill | Source | Upstream licence |
| --- | --- | --- |
| `clean-code` | [ClawForge](https://github.com/jackjin1997/ClawForge) | None declared |
| `codebase-design` | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT |
| `tdd` | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT |
| `waitwhat` | [mattpocock/skills](https://github.com/mattpocock/skills) (`wait-what`) | MIT |
| `lensed-review` | [cesdperez/llmfiles](https://github.com/cesdperez/llmfiles) | None declared |
| `code-commenting` | Team convention | — |
| `devcontainer-setup` | Team convention | — |
| `feature` | Team convention | — |
| `git-conventions` | Team convention | — |
| `setup-ai-skills` | Team convention | — |

Two upstreams declare no licence, so no licence is claimed over their content here; they are vendored with attribution, and removing them is the remedy if an author objects.

## Credits

The vendored skills are authored by their upstream maintainers (linked above) and copied in for convenience. All credit for that content goes to them.
