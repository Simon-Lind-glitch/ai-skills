# ai-skills

A Claude Code plugin: fourteen skills as Markdown under `skills/`, described by
`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. The
artifacts are the Markdown files and the two manifests; the only executable
code is the release logic under `.github/`, which has unit tests. The skills
have eval cases under `evals/` instead.

[`CONTEXT.md`](CONTEXT.md) holds this repo's vocabulary. Use its terms rather
than coining new ones, and the design terms it defers to
[`codebase-design`](skills/codebase-design/SKILL.md) rather than redefining
them.

## Adding or changing a skill

`plugin.json`'s `skills` array is the shipping list. The plugin installs exactly
what it names, so a folder under `skills/` that is not in the array does not
exist as far as users are concerned. Adding a skill means touching the array,
the README, and the source table in the same commit.

Every `SKILL.md` has one of three modes:

- **User-invoked**: `disable-model-invocation: true`. Only a human can start it, by typing it.
- **Model-invoked**: the agent loads it when its description matches.
- **Model-suggested**: model-invoked, but it asks the user before it does anything.

Pick deliberately. A skill that fans out
subagents or writes to a forge is user-invoked or model-suggested. Thus it never
starts on a description match alone. A model-suggested skill starts with an
"Ask first" section. That section skips the question when the user typed the
skill, or when another skill loaded it. The README groups skills under those
three headings, so a change in invocation is also a README change.

Comments and documentation are written in ASD-STE100 Simplified Technical
English, and [`code-commenting`](skills/code-commenting/SKILL.md) is where that
rule lives. A skill that writes comments or docs points at it in one line rather
than restating the rules.

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

The [`git-conventions`](skills/git-conventions/SKILL.md) skill applies here for
the Conventional Commit format the bump depends on, but this repo has no Jira
project behind it. Skip the ticket parts: branches are named
`<type>/<short-description>`, and commits and pull request titles carry no
ticket key or footer.

## Development

Work happens in the devcontainer (`.devcontainer/`) — reopen in it rather than
running on the host, so a shell here reaches the repo and its toolchain instead
of the host's credentials. It carries the CI toolchain (`jq`, `gh`) plus
`shellcheck` and `markdownlint-cli2`:

    markdownlint-cli2                       # globs and rules come from .markdownlint-cli2.jsonc
    shellcheck .devcontainer/post-create.sh .github/scripts/*.sh
    .github/scripts/test-version-bump.sh
    claude plugin validate . --strict

## Evals

`evals/` holds `claude plugin eval` cases. Each case gives Claude a prompt in a
small git repository that the case's `fixture.sh` makes. Its graders look at which
skill loaded and what Claude did, for example that a model-suggested skill asks
before it starts. The format is in the
[plugin evals docs](https://code.claude.com/docs/en/plugin-evals.md).

Each run is a real Claude session, so each run costs money. Use one run and no
baseline arm while you work on a skill:

    claude plugin eval . --scaffold --runs 1 --ablation none --tag no-shell

Cases tagged `needs-shell` load `feature`, which reads its inlined skills with
`cat`. An eval run removes Bash unless you grant it. Under WSL, the eval sandbox
refuses every run that has a shell, so run these cases only on Linux or macOS:

    claude plugin eval . --scaffold --runs 1 --ablation none --allow-tools "Bash(cat *)"

Add or change a case in the same commit as the skill change that it tests.

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
