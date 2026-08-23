# ai-skills

A Claude Code plugin: five skills as Markdown under `skills/`, described by
`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. There is no
build and no test suite — the artifacts are the Markdown files and the two
manifests.

## Releases

`.github/workflows/version-bump.yml` owns the version. It reads Conventional
Commit types since the last `v*` tag on every push to `main`, rewrites
`.claude-plugin/plugin.json` with `jq`, tags, and cuts a GitHub release. Never
hand-edit `version` — the workflow's bump commit is the only thing that should
touch it, and a manual edit races the next run.

`feat` bumps minor, `fix` bumps patch, `!`/`BREAKING CHANGE` bumps major, and
anything else releases nothing. So a skill rewrite committed as `docs:` ships
to nobody.

## Development

Work happens in the devcontainer (`.devcontainer/`) — reopen in it rather than
running on the host, so a shell here reaches the repo and its toolchain instead
of the host's credentials. It carries the CI toolchain (`jq`, `gh`) plus
`shellcheck` and `markdownlint-cli2`:

    shellcheck .devcontainer/post-create.sh
    markdownlint-cli2            # globs and rules come from .markdownlint-cli2.jsonc
    jq . .claude-plugin/plugin.json .claude-plugin/marketplace.json

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
