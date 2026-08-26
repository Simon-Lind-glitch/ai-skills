---
name: setup-ai-skills
description: Configure a repo to use the ai-skills plugin by writing the marketplace and plugin declaration into .claude/settings.json. Run once per repo.
argument-hint: "[project|user]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(claude plugin *)
  - Bash(git check-ignore *)
---

# Setup ai-skills

Wire this repo up to the `ai-skills` plugin, so a session opened here starts with the
conventions already loaded instead of a fresh agent with none.

This writes one file. It does not install a devcontainer, touch CI, or change any code.

## Scope

`$ARGUMENTS` selects where the declaration lands. Default is `project`.

- **`project`** writes `.claude/settings.json` at the repo root. Committed, travels with
  the repo, reads the same for everyone who clones it. This is the one you want.
- **`user`** writes `~/.claude/settings.json`. Use it only when the repo is not yours to
  add files to, since nobody else gets the config.

## What to write

```json
{
  "extraKnownMarketplaces": {
    "ai-skills": {
      "source": { "source": "github", "repo": "Simon-Lind-glitch/ai-skills" }
    }
  },
  "enabledPlugins": { "ai-skills@ai-skills": true }
}
```

**Merge, never overwrite.** A repo that already has `.claude/settings.json` has settings
someone chose. Read it first, add only the two keys above, and leave everything else
exactly as it was. If `extraKnownMarketplaces` or `enabledPlugins` already exist, add to
them rather than replacing them.

**Already declared is success, not failure.** Re-running this must be a no-op. Say the
repo is already wired up and stop.

## Exception: this repo itself

If the target repo _is_ `ai-skills`, do not write the `github` source above. This repo is
the plugin, so a session here must load the skills from the working tree rather than from
the last published release, and that registration is a container-local absolute path which
belongs in user scope. `.devcontainer/post-create.sh` already does it. Say so and stop.

## After writing

1. Verify the declaration parses and the plugin resolves:

   ```bash
   claude plugin list
   ```

2. If the repo ignores `.claude/`, the file will not travel with it, which defeats the
   point of project scope. Check, and say so if it does:

   ```bash
   git check-ignore -v .claude/settings.json
   ```

3. Tell the user the skills activate on the next session in this repo, and that
   `.claude/settings.local.json` is the place for personal overrides they do not want
   committed.
