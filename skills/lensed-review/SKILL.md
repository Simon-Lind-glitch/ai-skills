---
name: lensed-review
description: Multi-angle code audit. Fans out parallel read-only lens agents (correctness, security, test-health, code-standards, reuse, performance), then synthesizes one scored report. Reviews local branch changes by default, or a GitHub PR / GitLab MR with the forge detected from the remote. Prints the report; posts only with --post.
argument-hint: "[branch|codebase|<pr-or-mr>] [low|medium|high|max] [--only a,b] [--skip a,b] [--verify] [--post] [--autofix]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - Task
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git remote *)
  - Bash(git merge-base *)
  - Bash(git symbolic-ref *)
  - Bash(git fetch *)
  - Bash(git worktree *)
  - Bash(gh pr view *)
  - Bash(gh pr diff *)
  - Bash(gh pr list *)
  - Bash(gh repo view *)
  - Bash(gh auth status *)
  - Bash(glab mr view *)
  - Bash(glab mr diff *)
  - Bash(glab mr list *)
  - Bash(glab repo view *)
  - Bash(glab auth status *)
---

# Lensed Review

**Role:** Orchestrator of a multi-angle code audit. You spawn one specialist agent per
selected lens, run them in parallel, then synthesize their findings into a single scored
report.

**Load the shared protocol first:** `Read ${CLAUDE_SKILL_DIR}/LENSES.md`. It defines the
fan-out contract, the lens catalog, the synthesis rules, and the finding format. This file
supplies only the target, the lens selection, the output shape, and the write policy.
Where the two conflict, this file wins.

**Read-only by default.** The report prints to the terminal and nothing reaches the forge.
Posting happens only under `--post`, and even then this skill **never approves and never
merges** — not `gh pr review --approve`, not `glab mr approve`, not `merge` on either.

## Arguments

Parse `$ARGUMENTS` (all optional, any order):

- **target**: `branch` (default), `codebase`, or a review target on the forge — a bare
  number, or a PR/MR URL.
  - `branch`: changes in the current branch against its merge base with the default branch.
  - `codebase`: all files.
  - a number or URL: that PR or MR's diff, reviewed against a detached worktree at its head.
- **depth**: `low` | `medium` (default) | `high` | `max`.
  - `low` / `medium`: fewer, high-confidence findings only, threshold 5.
  - `high` / `max`: broader coverage, may include lower-confidence findings, threshold 4.
  - Under `--post` the threshold floor is **7** regardless of depth, because a false
    positive on someone else's changes costs more than a missed nit.
- **`--only a,b,...`**: run only the listed lenses.
- **`--skip a,b,...`**: run all default lenses except the listed ones.
- **`--verify`**: add the `verify` lens from the catalog. Heavier, and it runs the code
  rather than reading it.
- **`--post`**: publish surviving findings as inline comments. Forge targets only.
- **`--autofix`**: after synthesis, apply every surviving finding and commit. Local
  targets only, and never combined with `--post`.

Default lens set: `correctness`, `test-health`, `code-standards`, `reuse`, `security`,
`performance`. `cross-repo-impact` and `ticket-alignment` are not in the default set;
`--only cross-repo-impact` gives a blast-radius check on its own.

## Phase 0: Detect the forge

Do this before resolving any non-local target. Do not assume GitHub.

```bash
REMOTE=$(git remote get-url origin)
```

Decide in this order, and stop at the first that answers:

1. **Host in the remote URL.** `github.com` → GitHub. `gitlab.com` → GitLab.
2. **Self-hosted, named by the CLI.** A custom domain is not a guess to make from the
   hostname. Ask the CLIs which hosts they are authenticated against — `gh auth status`
   and `glab auth status` both list them — and match the remote's host.
3. **Repo-local evidence.** A `.gitlab-ci.yml` at the root points at GitLab; a
   `.github/workflows/` directory points at GitHub. Weakest signal, since a repo can carry
   both, so use it only when 1 and 2 are silent.

Then confirm the CLI is actually installed (`command -v gh`, `command -v glab`). If the
forge resolves but its CLI is missing or unauthenticated, **say so and review locally
instead** — `branch` scope still works without any forge access. Never fall back to the
other forge's CLI.

If the signals disagree, or both forges look plausible, **stop and ask.** Do not guess:
under `--post` a wrong guess means writing to the wrong place.

Bind these for the rest of the run:

| Operation | GitHub | GitLab |
| --- | --- | --- |
| Metadata | `gh pr view <n> --json number,title,body,url,headRefOid,baseRefName` | `glab mr view <iid> --output json` |
| Diff | `gh pr diff <n>` | `glab mr diff <iid>` |
| Head sha | `.headRefOid` | `.diff_refs.head_sha` |
| Fetch ref | `pull/<n>/head` | `merge-requests/<iid>/head` |
| Project ref | `gh repo view --json nameWithOwner -q .nameWithOwner` | `glab repo view --output json -q .path_with_namespace` |
| Post | one `COMMENT` review, all comments batched | one discussion per finding |

## Phase 1: Resolve the target

### Local (`branch` or `codebase`)

```bash
BASE=$(git merge-base HEAD "$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')")
git diff --name-only "$BASE"...
```

If `branch` scope has no diff, say so and stop. For `codebase` scope the lenses read files
directly, so skip the anchor map below.

### Forge target

Give the lenses a checkout of the head, so they read surrounding context rather than
guessing from the diff alone. Never `gh pr checkout` or `glab mr checkout` — both move the
user's working tree.

```bash
git fetch origin "<fetch-ref>:lensed-review-<id>"
git worktree add "$OUT/head" "lensed-review-<id>"
```

Remove the worktree and the branch when the run ends, including when it ends early.

Record the head sha from the table above. It anchors both the posted comments and the
idempotency marker. On GitLab, also record `base_sha` and `start_sha` from `diff_refs` —
posting an inline comment there needs all three.

### Anchor map

Build this for any diff-based target, so findings cite real line numbers rather than
counted ones. Both forges reject an inline comment on a line outside the diff, so under
`--post` this map is also what keeps every anchor postable.

```bash
<diff-command> | awk '
  /^\+\+\+ /{p=substr($0,7); next}
  /^@@ /{match($0,/\+[0-9]+/); n=substr($0,RSTART+1,RLENGTH-1)+0; next}
  /^\+/{ if (p != "dev/null") print p":"n"\t"substr($0,2); n++ }
'
```

Where `<diff-command>` is `git diff --unified=0 "$BASE"...` locally, or the forge's diff
command from the table.

## Phase 2: Fan out

Spawn the selected lenses per the shared fan-out contract: single message, read-only
(except `verify`), strict boundaries, self-refute, model tiering, sharding caps. Give each
agent its mandate and NOT list from the catalog, the scope, the depth, the target file
list, and the finding format. Each lens gathers its own remaining context.

A higher threshold does not change what the lenses look at, only which findings clear the
bar. Do not let a high bar become an excuse to gather less context.

## Phase 3: Synthesize

Per the shared rules: dedupe by lens ownership, score, anchor, and keep findings at or
above the threshold for the chosen depth. At `low` and `medium`, additionally drop
anything below high confidence. **Default to dropping when uncertain.**

## Phase 4: Report

Always. Group survivors by lens, most impactful first. Zero findings for a lens is a valid
result, and reporting it as such is the point.

```text
## lensed-review - <target>, depth <depth>

| # | Score | Lens | Location | Issue |
|---|-------|------|----------|-------|
| 1 | 8/10  | correctness | src/loop.ts:42 | Off-by-one skips the last element |
| 2 | 6/10  | test-health | user.test.ts | Mocks the DB it exists to exercise |

### 1. Off-by-one skips the last element (correctness, 8/10)
`src/loop.ts:42`
The bound is `< len - 1`, so the final item never runs. Use `< len`.

### 2. Mocks the DB it exists to exercise (test-health, 6/10)
`user.test.ts`
Every query is stubbed, so the test passes even when the SQL is wrong. Convert it to an
integration test against a real DB.

### summary
<total findings by lens; what the self-refutation dropped; whether anything was posted>
```

Descriptions are two sentences maximum: what is wrong, then what to do instead. No pasted
code, no emoji.

## Phase 5: Post

Only under `--post`, and only for a forge target. Skip this phase entirely otherwise.

### Common rules

1. **Idempotency guard.** Before posting anything, list the existing comments carrying this
   skill's marker and drop any finding whose anchor is already taken. Re-running must not
   duplicate what it said last time.
2. **Every body ends with the marker**, an HTML comment that renders invisibly:

   ```text
   <!-- lensed-review: sha=<HEAD_SHA> threshold=<N> -->
   ```

   It is load-bearing. The guard reads it to know what was already said, so omitting it
   makes the next run duplicate this one.
3. **Inline findings are the only notes.** No root summary comment. Findings below the
   threshold do not appear on the forge at all — not as a summary, not as context. The
   threshold is the publication bar.
4. **Report what you posted** in the Phase 4 summary: how many comments landed, how many
   the guard skipped, and what stayed below the bar.

### GitHub

Post once, as a single review carrying every inline comment — not one API call per
finding. `event` is `COMMENT` and nothing else, which is what structurally prevents this
skill from approving.

```bash
gh api "repos/$REPO/pulls/<n>/comments" --paginate \
  --jq '.[] | select(.body | contains("<!-- lensed-review:")) | "\(.path):\(.line)"'

gh api "repos/$REPO/pulls/<n>/reviews" -X POST --input payload.json
```

```json
{
  "commit_id": "<HEAD_SHA>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/loop.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "**correctness, impact 8/10**\n\nThe bound is `< len - 1`, so the final item never runs. Use `< len`.\n\n<!-- lensed-review: sha=<HEAD_SHA> threshold=<N> -->"
    }
  ]
}
```

### GitLab

There is no batched-review equivalent, so post **one discussion per finding**. Each needs
the full `position` object — all three shas from `diff_refs`, not just the head.

```bash
glab api "projects/$PROJECT/merge_requests/<iid>/discussions" --paginate \
  --jq '.[].notes[] | select(.body | contains("<!-- lensed-review:")) | "\(.position.new_path):\(.position.new_line)"'

glab api "projects/$PROJECT/merge_requests/<iid>/discussions" -X POST \
  -f body="$BODY" \
  -f position[position_type]=text \
  -f position[base_sha]="$BASE_SHA" \
  -f position[start_sha]="$START_SHA" \
  -f position[head_sha]="$HEAD_SHA" \
  -f position[new_path]="src/loop.ts" \
  -f position[new_line]=42
```

`$PROJECT` is the URL-encoded path with namespace. These post as **resolvable threads**,
which can gate merge where `blocking_discussions_resolved` is required. That is intended:
if the author disagrees with a finding, they resolve the thread.

Because each finding is its own request, a failure part-way leaves some posted. Report
exactly which ones landed rather than implying all-or-nothing.

## Fix mode

Only under `--autofix`, and only for a local target. Apply every surviving finding
**sequentially**, never in parallel, to avoid edit conflicts. If on the default branch,
create a branch first, named per the [`git-conventions`](../git-conventions/SKILL.md)
skill. Commit with a Conventional Commit subject summarizing what was fixed by lens. Print
the full report afterwards regardless, so the user sees what changed.
