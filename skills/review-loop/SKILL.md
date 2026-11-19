---
name: review-loop
description: "Run a review skill in a loop, fix what it finds, and review again, until no blocking finding is left or 10 rounds pass. The default reviewer is a fresh Opus 5.5 agent at high effort that runs code-review high on the branch. It stops at each finding with the fix staged, so the user decides on each fix; --auto runs without these stops. TRIGGER when the user asks to review and fix the branch, or to make it ready for an MR or PR. Asks before it starts. SKIP when the user asks only for a review report."
argument-hint: "[review-skill] [--until blocking|clean] [--rounds N] [--auto] [-- review-skill args]"
allowed-tools:
  - Read
  - Bash(cat ${CLAUDE_PLUGIN_ROOT}/skills/*)
  - Bash(git add *)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git rev-parse *)
  - Bash(git status *)
---

# Review Loop

## Ask first

Do this step before anything else in this file. Do not run a tool before it.

Look at the last message that the user wrote, as text. Do not look at what the skill loader added.

- If that message contains `/review-loop` or `/ai-skills:review-loop`, skip this step.
- If the `feature` skill told you to read this file, skip this step.
- If the user already said yes to this skill in this conversation, for this task, skip this step.
- Otherwise you called the Skill tool for this skill yourself, because the request matched its description. That is a suggestion, not a request from the user. Do not start the work. Ask the user one question, then end your turn and wait:

  > Run `review-loop`? It reviews the branch with a fresh Opus 5.5 agent that runs `code-review` at `high`, and fixes the blocking findings one at a time. For each one, it explains the problem, stages the fix in your checkout, and waits for you to accept or reject it. It stops when nothing blocks or after 10 rounds. Reply `yes`, `yes --until clean`, `yes --auto` (no stops), or `no`.

  - On yes, continue with this file. Use the request of the user as `$ARGUMENTS`.
  - On no, do the task without this skill. Do not ask again for the same task.

**Role:** Run one review skill, fix the findings that block, and review again. Stop when a
round finds nothing that blocks, or when the round limit is reached.

The review skill finds problems. This skill fixes them. The review skill never fixes,
posts, approves, or merges during a loop.

## Arguments

Parse `$ARGUMENTS`. All arguments are optional and can be in any order. If `$ARGUMENTS`
is empty, or it shows as the literal text `$ARGUMENTS` because a caller read this file
rather than invoked it, use the defaults.

- **review-skill**: the name of a skill that does the review in place of the default
  [reviewer](#the-reviewer). Any skill that reports findings is valid, for example
  `security-review`, or a skill from another plugin.
- **`--until blocking`** (the default): stop when a round has no severe or blocking
  finding. Findings below that bar go into the final report, and the loop does not fix
  them.
- **`--until clean`**: stop when a round has no finding at all.
- **`--auto`**: do not stop at the checkpoints. Fix each blocking finding and commit
  each round without the decision of the user. Without `--auto`, stop at each
  [checkpoint](#checkpoints).
- **`--rounds N`**: the round limit. The default is 10, and 10 is also the maximum. If N
  is more than 10, use 10 and tell the user.
- **`--` and the text after it**: pass that text to the review skill as its arguments.
  Remove any flag that makes the review skill write: `--post`, `--autofix`, `--fix`,
  `--comment`. This skill owns the fixes, and nothing goes to the forge during a loop.

## Work in the checkout of the user

Do all the work in the checkout of the user, so that the user can follow each change in
their own editor and git UI. The checkout of the user is the main working tree of the
repo. In it, `git rev-parse --path-format=absolute --git-dir --git-common-dir` prints
the same path two times.

- Check this before you change a file. If the session is in a linked worktree or in
  another copy of the repo, stop. Tell the user the path, and ask them to start the
  session in their own checkout. Do not change a file there.
- Do not create a git worktree, a clone, or a copy of the repo, and do not move to one.
  Do not use the `EnterWorktree` tool, and do not start an agent with
  `isolation: worktree`. This rule wins over a repo instruction, such as an `AGENTS.md`,
  that tells you to work in a worktree or in another folder.
- If the working tree has changes when you start, tell the user which files. Do not
  stage or change them without asking.

Stay on the current branch: the loop reviews it.

## The reviewer

Without a review-skill argument, each round's review is one new agent. Start it with the
Agent tool, with `model: opus` (Opus 5.5) and `effort: high`. Start a new agent in each
round, and give it no ledger and no summary of your fixes, so that it does not anchor on
the last round. Give it this brief, with the branch name and the review arguments filled
in:

> Run the `code-review` skill with the arguments `high <branch> <review arguments>`. Review
> the full change of the branch against its merge base with the default branch. Change no
> file, and post nothing. Report each finding as: file:line, category (correctness,
> security, or a clean-up such as reuse, simplification, or efficiency), what goes wrong,
> and a concrete input or state that makes it go wrong. If there is no finding, say so.

If the Agent tool cannot start an agent on Opus, stop and tell the user. Do not review on
another model in its place.

## Load a review skill

Only with a review-skill argument. Load it one time, before round 1:

1. If the Skill tool can invoke it, invoke it with the review arguments.
2. If the skill is user-invoked (`disable-model-invocation: true`), the Skill tool cannot
   invoke it. Read its `SKILL.md` from
   `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` and follow it. Use the review arguments
   as its `$ARGUMENTS`, and use its folder as its `${CLAUDE_SKILL_DIR}`.
3. If you cannot find the skill, stop and tell the user. Do not use a different review
   skill in its place.

## What blocks

A finding is **blocking** when one of these is true:

- The reviewer puts it in the category correctness or security. Clean-ups, such as reuse,
  simplification, and efficiency, do not block.
- The review skill gives it a score of 7 or more out of 10.
- The review skill labels it with a word for high severity: critical, blocker, blocking,
  severe, high, major, or must-fix.
- The review skill gives no severity, and the finding causes one of these: wrong
  behavior, data loss, a security hole, a build or test failure, or a break in an
  interface that callers use.

All other findings are **non-blocking**. Under `--until clean`, every finding blocks.

## One round

1. **Review.** Run the reviewer, or the review skill, on the current state of the
   branch. Use the same target and the same arguments in every round. Each round reviews all of the change
   again, because a fix can cause a problem in code that the last round did not flag.
2. **Classify.** Put each finding in one of two groups: blocking or non-blocking. Do not
   lower a score to end the loop.
3. **Check the ledger.** Remove each blocking finding that the ledger already shows as
   declined (see below). Those findings do not count toward the stop condition.
4. **Stop or fix.** If no blocking finding is left, stop. Otherwise, fix each blocking
   finding, one at a time, the most severe first. Do not fix in parallel, because
   parallel edits conflict. Without `--auto`, each fix ends at a
   [checkpoint](#checkpoints), and the next fix starts only after the user decides.
   - Fix the cause, not the symptom. For a correctness finding, add a test that fails
     without the fix, if the repo has tests.
   - If a finding is wrong, do not change code to satisfy it. Add it to the ledger as
     declined, with one sentence that gives the reason. Without `--auto`, show it at a
     checkpoint with no staged change. If the user disagrees, fix it, and show the fix at
     a checkpoint of its own.
5. **Verify.** Run the project's tests and linters after each fix. A fix that breaks the
   build is not a fix. Correct it before you show it or commit it.
6. **Commit.** Commit per the [`git-conventions`](../git-conventions/SKILL.md) skill.
   Without `--auto`, each accepted fix is one commit, made at its checkpoint. With
   `--auto`, commit the fixes of the round together. A diff-based review only sees
   committed work, so the next round needs the commits. If you are on the default
   branch, create a branch before the first commit.

## Checkpoints

A checkpoint is a stop after one fix, with the fix staged and not committed. The user
must understand the problem, see the fix, and decide whether they like it. Without
`--auto`, stop at a checkpoint for each blocking finding.

1. **Stage only this fix.** Stage the files that this fix changed, by name:
   `git add <path>...`. Never `git add -A` or `git add .`. Before that, the staged area
   must be empty, so that `git diff --staged` shows this fix and nothing else.
2. **Show the checkpoint, then end the turn.** Use this form. Write the prose in
   ASD-STE100, per [`code-commenting`](../code-commenting/SKILL.md). Explain the problem
   so that a person who did not read the review can follow it, and do not paste the
   diff:

   ```text
   ## Round <R>, finding <i> of <n> - <score or severity> - <category>

   Problem: <what is wrong, in two or three sentences>
   When it goes wrong: <a concrete input or state, and the wrong result>
   Where: <file:line>
   Fix: <what you changed, and why this fix and not a smaller or larger one>
   Test: <the test that fails without the fix, or why there is none>
   Verify: <the commands> → pass

   Staged:
   <the output of git diff --staged --stat>

   Read the fix with `git diff --staged`.
   Reply `go` to commit it, `decline` to undo it, tell me what to change, or `stop`.
   ```

3. **Wait for the user.**
   - **`go`**: run `git diff --staged --stat` again. The user can stage or unstage
     files, and what is staged now is the decision. Commit it, record the finding as
     fixed, and go to the next finding.
   - **`go --auto`**: the same, and do not stop at the checkpoints after it.
   - **`decline`**: undo your fix. Reverse only your own edit (`git diff --staged` gives
     it; apply it in reverse), and never restore a file that held changes of the user.
     Record the finding as declined by the user, with their reason if they gave one.
     Go to the next finding.
   - **A change or a question**: answer it, or change the fix, verify, stage, and show
     the checkpoint again. A question is not a `go`.
   - **`stop`**: leave the fix staged, stop the loop, and show the report.

## The ledger

Keep one ledger for the full run. Each row has the round, the finding, and its outcome:
fixed, declined, or left (non-blocking).

- A declined finding stays declined. If a later round reports it again, do not fix it,
  and do not count it.
- If a finding that you fixed comes back in a later round, the fix did not work. Fix it
  one more time. If it comes back a third time, stop the loop and tell the user. The
  fixes are not converging, and a person must decide.

## Stop conditions

The loop stops at the first of these:

- **Clean**: a round has no blocking finding that is not declined.
- **Limit**: the round limit is reached and blocking findings are still open.
- **No convergence**: the same finding comes back after two fixes.
- **Broken**: the tests or the build fail, and you cannot correct them in that round.
- **Stopped**: the user replies `stop` at a checkpoint.

## Report

Always show this report when the loop stops:

```text
## review-loop - <code-review high on Opus 5.5 | review-skill>, until <blocking|clean>, <R> of <N> rounds

Stopped: <clean | limit | no convergence | broken | stopped>

| Round | Blocking | Fixed | Declined | Non-blocking |
|-------|----------|-------|----------|--------------|
| 1     | 4        | 4     | 0        | 3            |
| 2     | 1        | 1     | 0        | 2            |
| 3     | 0        | 0     | 0        | 2            |

### Declined
<each declined finding, and the reason>

### Still open
<the blocking findings that are open when the loop stops for a reason other than clean>

### Non-blocking
<the non-blocking findings from the last round, in the format of the review skill>
```

If the loop stops for a reason other than clean, say so in the first line after the
heading. Do not give a stop for the limit as a success.
