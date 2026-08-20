# ai-skills

Simon's curated collection of [Agent Skills](https://www.skills.sh) for Claude Code, packaged as a single installable plugin.

Each skill is a folder under [`skills/`](skills/) containing a `SKILL.md` (plus any supporting files). The repo doubles as a **Claude Code plugin marketplace** so the whole set installs with one command.

## Included skills

| Skill | What it does | Source |
| --- | --- | --- |
| [`clean-code`](skills/clean-code/) | Apply Robert C. Martin's *Clean Code* principles — naming, small functions, error handling, code smells. | [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills) |
| [`tdd`](skills/tdd/) | Test-driven development: red → green → refactor, behavior-focused tests, vertical slices. | [mattpocock/skills](https://github.com/mattpocock/skills) |

## Install

### Option A — Claude Code plugin (recommended)

Add this repo as a marketplace, then install the plugin. All skills come with it.

```
/plugin marketplace add Simon-Lind-glitch/ai-skills
/plugin install ai-skills@ai-skills
```

Verify with `/plugin` (it should show `ai-skills` as enabled). The skills then activate automatically when a task matches their description.

### Option B — skills.sh CLI (per skill)

Works with Claude Code and other agents (Cursor, Copilot, etc.). Pull individual skills straight from this repo:

```bash
npx skills add https://github.com/Simon-Lind-glitch/ai-skills --skill clean-code
npx skills add https://github.com/Simon-Lind-glitch/ai-skills --skill tdd
```

## Adding more skills

This is a vendored collection — the skill files live in this repo, so nothing breaks if an upstream repo disappears. To add a skill:

1. Copy its folder into `skills/<skill-name>/` (must contain a `SKILL.md` with `name` and `description` frontmatter). The quickest way to grab one from skills.sh into a scratch dir:
   ```bash
   npx skills add https://github.com/<owner>/<repo> --skill <name>
   ```
   then copy the resulting folder here.
2. Add a row to the table above and note the source, for attribution.
3. Commit and push. A new install (or `/plugin marketplace update ai-skills`) picks it up.

No change to `plugin.json` or `marketplace.json` is needed — every folder under `skills/` is discovered automatically.

## Credits

The skills here are authored by their upstream maintainers (linked in the table above) and vendored for convenience. All credit for the skill content goes to them.
