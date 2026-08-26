# ai-skills

A Claude Code plugin: ten skills as Markdown under `skills/`, described by
`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. The
artifacts are the Markdown files and the two manifests; the only executable
code is the release logic under `.github/`, which is the only thing with tests.

[`CONTEXT.md`](CONTEXT.md) holds this repo's vocabulary. Use its terms rather
than coining new ones, and the design terms it defers to
[`codebase-design`](skills/codebase-design/SKILL.md) rather than redefining
them.

## Adding or changing a skill

`plugin.json`'s `skills` array is the shipping list. The plugin installs exactly
what it names, so a folder under `skills/` that is not in the array does not
exist as far as users are concerned. Adding a skill means touching the array,
the README, and the source table in the same commit.

Every `SKILL.md` is either **user-invoked** (`disable-model-invocation: true`,
reachable only when a human types it) or **model-invoked** (loaded when its
description matches). Pick deliberately: a skill that fans out subagents or
writes to a forge should be user-invoked, so it cannot fire on a description
match. The README groups skills under those two headings, so a change in
invocation is also a README change.

Run `claude plugin validate . --strict` after touching either manifest.

Skills are vendored, not referenced. `README.md` records each one's upstream and
licence status, and two upstreams declare no licence, so keep attribution
accurate when editing their content.

## Releases

`.github/workflows/version-bump.yml` owns the version. On every push to `main`
it reads Conventional Commit types since the last `v*` tag, rewrites
`.claude-plugin/plugin.json` with `jq`, tags, and cuts a GitHub release. Never
hand-edit `version` — the workflow's bump commit is the only thing that should
touch it, and a manual edit races the next run.

`feat` bumps minor, `fix` bumps patch, `!`/`BREAKING CHANGE` bumps major, and
anything else releases nothing. So a skill rewrite committed as `docs:` ships
to nobody.

The decision itself is not in the YAML. It lives in two scripts so it can be
run and tested without pushing to `main` to find out what happens:

    .github/scripts/decide-bump.sh          # commit log in, bump level out
    .github/scripts/decide-bump.sh -        # read the log on stdin (the test seam)
    .github/scripts/next-version.sh 0.6.0 minor
    .github/scripts/test-version-bump.sh    # run before changing either

The workflow runs the tests before it decides, so a broken bump rule fails the
release rather than cutting a wrong one.

## Development

Work happens in the devcontainer (`.devcontainer/`) — reopen in it rather than
running on the host, so a shell here reaches the repo and its toolchain instead
of the host's credentials. It carries the CI toolchain (`jq`, `gh`) plus
`shellcheck` and `markdownlint-cli2`:

    markdownlint-cli2                       # globs and rules come from .markdownlint-cli2.jsonc
    shellcheck .devcontainer/post-create.sh .github/scripts/*.sh
    .github/scripts/test-version-bump.sh
    claude plugin validate . --strict

## Skills inside the container

The container installs this repo's own plugin from the working tree, so the
skills the agent loads are the ones being edited rather than the last published
release. That comes from the committed `.claude/settings.json` enabling the
plugin plus the `postCreateCommand` warmup that registers the workspace as a
marketplace. If the skills seem missing, run `claude plugin list`, then re-run
`bash .devcontainer/post-create.sh` to re-warm them.

Edits to `skills/**` reach a running session through
`claude plugin marketplace update ai-skills`, which is what the warmup script
re-runs.

This is also why `setup-ai-skills` refuses to run against this repo: it writes a
`github` marketplace source, which would load the published release instead of
the working tree.
