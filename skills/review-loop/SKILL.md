---
name: review-loop
description: Run a review skill in a loop, fix what it finds, and review again — until no severe or blocking finding is left, or 10 rounds pass. The review skill is lensed-review by default, and any review skill can replace it.
argument-hint: "[review-skill] [--until blocking|clean] [--rounds N] [-- review-skill args]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Bash(cat ${CLAUDE_PLUGIN_ROOT}/skills/*)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git status *)
---

# Review Loop

**Role:** Run one review skill, fix the findings that block, and review again. Stop when a
round finds nothing that blocks, or when the round limit is reached.

The review skill finds problems. This skill fixes them. The review skill never fixes,
posts, approves, or merges during a loop.

## Arguments

Parse `$ARGUMENTS`. All arguments are optional and can be in any order. If `$ARGUMENTS`
is empty, or it shows as the literal text `$ARGUMENTS` because a caller read this file
rather than invoked it, use the defaults.

- **review-skill**: the name of the skill that does the review. The default is
  `lensed-review`. Any skill that reports findings is valid: `code-review`,
  `security-review`, or a skill from another plugin.
- **`--until blocking`** (the default): stop when a round has no severe or blocking
  finding. Findings below that bar go into the final report, and the loop does not fix
  them.
- **`--until clean`**: stop when a round has no finding at all.
- **`--rounds N`**: the round limit. The default is 10, and 10 is also the maximum. If N
  is more than 10, use 10 and tell the user.
- **`--` and the text after it**: pass that text to the review skill as its arguments.
  Remove any flag that makes the review skill write: `--post`, `--autofix`, `--fix`,
  `--comment`. This skill owns the fixes, and nothing goes to the forge during a loop.

## Load the review skill

Load the review skill one time, before round 1:

1. If the Skill tool can invoke it, invoke it with the review arguments.
2. If the skill is user-invoked (`disable-model-invocation: true`), the Skill tool cannot
   invoke it. `lensed-review` is one of these. Read its `SKILL.md` from
   `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` and follow it. Use the review arguments
   as its `$ARGUMENTS`, and use its folder as its `${CLAUDE_SKILL_DIR}`.
3. If you cannot find the skill, stop and tell the user. Do not use a different review
   skill in its place.

## What blocks

A finding is **blocking** when one of these is true:

- The review skill gives it a score of 7 or more out of 10. In `lensed-review`, 7 to 8 is
  "should address" and 9 to 10 is "must address".
- The review skill labels it with a word for high severity: critical, blocker, blocking,
  severe, high, major, or must-fix.
- The review skill gives no severity, and the finding causes one of these: wrong
  behavior, data loss, a security hole, a build or test failure, or a break in an
  interface that callers use.

All other findings are **non-blocking**. Under `--until clean`, every finding blocks.

## One round

1. **Review.** Run the review skill on the current state of the branch. Use the same
   target and the same arguments in every round. Each round reviews all of the change
   again, because a fix can cause a problem in code that the last round did not flag.
2. **Classify.** Put each finding in one of two groups: blocking or non-blocking. Do not
   lower a score to end the loop.
3. **Check the ledger.** Remove each blocking finding that the ledger already shows as
   declined (see below). Those findings do not count toward the stop condition.
4. **Stop or fix.** If no blocking finding is left, stop. Otherwise, fix each blocking
   finding, one at a time. Do not fix in parallel, because parallel edits conflict.
   - Fix the cause, not the symptom. For a correctness finding, add a test that fails
     without the fix, if the repo has tests.
   - If a finding is wrong, do not change code to satisfy it. Add it to the ledger as
     declined, with one sentence that gives the reason.
5. **Verify.** Run the project's tests and linters. A fix that breaks the build is not a
   fix. Correct it before the round ends.
6. **Commit.** Commit the fixes of the round, per the
   [`git-conventions`](../git-conventions/SKILL.md) skill. A diff-based review only sees
   committed work, so the next round needs the commit. If you are on the default branch,
   create a branch first.

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

## Report

Always show this report when the loop stops:

```text
## review-loop - <review-skill>, until <blocking|clean>, <R> of <N> rounds

Stopped: <clean | limit | no convergence | broken>

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
