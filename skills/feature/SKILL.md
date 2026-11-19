---
name: feature
description: "Build a feature with the engineering standards in context: codebase-design, tdd, clean-code, code-commenting, docs-sync, git-conventions, then review-loop. With --plan, it proposes a plan first. It stops at a checkpoint after each step, with the change staged, until the user says go; --auto runs without checkpoints. TRIGGER when the user asks to build, implement, add, or change a feature, an endpoint, a component, a command, or a behavior in code. Asks before it starts. SKIP for a question, a one-line fix, a config value, or a change that is only docs."
argument-hint: "[--plan] [--auto] [what to build]"
allowed-tools:
  - Bash(cat ${CLAUDE_PLUGIN_ROOT}/skills/*)
  - Bash(git add *)
  - Bash(git diff *)
  - Bash(git status *)
  - Bash(git rev-parse *)
  - Bash(git symbolic-ref *)
  - Bash(git switch *)
  - Bash(git pull *)
---

# Feature

## Ask first

Do this step before anything else in this file. Do not run a tool before it.

Look at the last message that the user wrote, as text. Do not look at what the skill loader added.

- If that message contains `/feature` or `/ai-skills:feature`, skip this step.
- If another skill told you to read this file, skip this step.
- If the user already said yes to this skill in this conversation, for this task, skip this step.
- Otherwise you called the Skill tool for this skill yourself, because the request matched its description. That is a suggestion, not a request from the user. Do not start the work. Ask the user one question, then end your turn and wait:

  > This looks like feature work. Use the `feature` skill? It loads clean-code, tdd, codebase-design, and the git conventions, and runs `review-loop` at the end. It stops after each step with the change staged, so you can read it before it is committed. Reply `yes`, `yes --plan`, `yes --auto`, or `no`.

  - On yes, continue with this file. Use the request of the user as `$ARGUMENTS`.
  - On no, do the task without this skill. Do not ask again for the same task.

Build: **$ARGUMENTS**

If the arguments include `--plan` or `--auto`, remove them from the text above: they are
flags, not part of what to build. With `--plan`, start at step 0 below. Without `--plan`,
skip step 0 and start at step 1. With `--auto`, do not stop at the checkpoints (see
[Checkpoints](#checkpoints)). Without it, stop at each one.

Six skills are inlined below. They are already in context — do not invoke them again, and
do not go looking for them on disk. The seventh, `review-loop`, is loaded at step 7, when
the work is ready for it.

## The order the work happens

The skills overlap, so their precedence matters more than their content.

0. **Plan, then wait for approval.** Only with `--plan`. Read the code that the change
   touches. Do not edit a file yet. Then write the plan in ASD-STE100 Simplified Technical
   English, per `code-commenting`:
   - Start with one or two sentences that tell what the change does and why.
   - Then give numbered steps, in the order you will do them. Each step has one action
     and one or two short sentences. Name the files, the interface, and the seam.
   - Name the seams that you intend to test. The approval of the plan is the confirmation
     of those seams in step 2.
   - Name the docs that the change makes stale.
   - End with the open questions and the risks. If there are none, say so.

   Then stop and wait. The user can discuss the plan, change it, or accept it. Change the
   plan and show it again until the user accepts it. Start step 1 only after the user
   accepts the plan clearly. Silence or a question is not acceptance. If the work later
   moves away from the accepted plan, stop, tell the user what changed, and ask again.
1. **Start a branch from the default branch, then shape the module before writing
   anything.** First do [Start from the default branch](#start-from-the-default-branch).
   Then shape the module. Decide the interface, where the seam
   goes, and how much sits behind it. Use the `codebase-design` vocabulary below to say it
   out loud: module, interface, depth, seam, adapter, leverage, locality.
2. **Agree the seams under test, then confirm them.** No test is written at an unconfirmed
   seam. Ask which seams matter before writing the first test, not after.
3. **Red → green, one vertical slice at a time.** One seam, one failing test, one minimal
   implementation, repeat. Never write all the tests first — that is horizontal slicing,
   and it verifies imagined behavior. After each slice is green, stop at a
   checkpoint: the slice is one commit.
4. **Then clean up.** Naming and function shape per `clean-code`; comments per
   `code-commenting`, which means the non-obvious _why_ on the line that is easy to get
   wrong, in ASD-STE100 Simplified Technical English, and nothing that narrates the change
   you just made. Refactoring is a stage of its own, not a step inside the red → green
   loop. Stop at a checkpoint when the clean-up is done. If there was nothing to clean
   up, say so and do not stop.
5. **Sync the docs.** Per `docs-sync`: list the names the change touched, grep the prose
   for them, and update or delete every stale hit. Write the prose in ASD-STE100, per
   `code-commenting`. A feature is not done while a doc it contradicts still ships, and the
   doc changes go in the same commit as the code: stage them with the last slice or the
   clean-up, before its checkpoint, or stop at a checkpoint of their own if those are
   already committed.
6. **Commit and title the MR** per `git-conventions`, which is also what decides whether
   a release gets cut. The checkpoints make the commits; write each message per
   `git-conventions`. Then give the MR title.
7. **Review until nothing blocks.** Run
   `cat "${CLAUDE_PLUGIN_ROOT}/skills/review-loop/SKILL.md"` and follow it with its
   defaults, plus `--auto` if this run has `--auto`: the Opus 5.5 reviewer that runs `code-review` at `high` on the branch, until no severe or blocking finding is left,
   10 rounds at most. Its fixes follow steps 3 to 6: a test before a correctness fix, the
   standards above, and a commit per round. The feature is done when the loop stops
   clean. If it stops for another reason, give its report to the user and stop there.
   Its declined findings go in the MR description, as `review-loop` says.

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

## Start from the default branch

Do this before you change a file, so that the branch of the feature starts from the
latest default branch:

1. Find the default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, without
   the `origin/` prefix. If that fails, use `main`.
2. If the working tree has changes, stop and ask the user what to do with them. A switch
   of branch takes them along.
3. If you are not on the default branch, tell the user which branch you are on. If the
   user said to continue the work on that branch, stay on it and skip the rest of this
   list. Otherwise, switch: `git switch <default>`.
4. Update it: `git pull --ff-only`. If that fails, stop and tell the user why.
5. Create the branch of the feature per `git-conventions`: `git switch -c <branch>`.

## Checkpoints

A checkpoint is a stop with the change staged and not committed, so the user can read it
and understand it before it goes into the history. Without `--auto`, stop at each
checkpoint that the steps above name. With `--auto`, commit at each checkpoint and
continue.

1. **Verify.** Run the tests and the linters that the change touches. Do not stop at a
   checkpoint with a failing build, except for the failing test of a red step that you
   show on purpose.
2. **Stage only this step.** Stage the files that this step changed, by name:
   `git add <path>...`. Never `git add -A` or `git add .`. A file that the user changed is
   not yours to stage.
3. **Show the checkpoint, then end the turn.** Use this form. Write the prose in
   ASD-STE100, per `code-commenting`. Explain the change; do not paste the diff:

   ```text
   ## Checkpoint <n> - <slice | clean-up | docs>: <one line>

   What it does: <the behavior that is new, from the view of a caller>
   Seam and test: <the seam, the test name, and why it failed before the change>
   How: <the code that changed and why, in two or three sentences>
   Look at: <the one or two lines that are easy to get wrong, as file:line>
   Verify: <the commands> → pass

   Staged:
   <the output of git diff --staged --stat>

   Read the change with `git diff --staged`.
   Reply `go` to commit it and continue, tell me what to change, or `stop`.
   ```

4. **Wait for the user.**
   - **`go`**: run `git diff --staged --stat` again. The user can stage or unstage
     files, and what is staged now is the decision. Commit it, then continue.
   - **`go --auto`**: the same, and do not stop at the next checkpoints.
   - **A change or a question**: answer it, or make the change, verify, stage, and show
     the checkpoint again. A question is not a `go`.
   - **`stop`**: leave the change staged and stop the skill. Tell the user where the work
     stopped and what comes next.

## Where they disagree

- **`clean-code` says small; `codebase-design` says deep.** Smallness is about
  implementations — short functions, small classes. It is not an argument for many small
  modules. When the two pull against each other, the interface wins: hide more behind it
  rather than splitting it across callers.
- **`clean-code` says avoid comments; `code-commenting` says write these ones.**
  `clean-code` is right that most comments are a failure to express something in code.
  `code-commenting` owns the ones that survive that test.
- **`tdd` says refactoring is out of the loop; step 4 above is where it goes.** Do not
  refactor between red and green.
- **`clean-code` says code should explain itself; `docs-sync` still demands prose.**
  Self-documenting code reaches the person already reading the code, not the person
  deciding whether to. The README and its kin stay in scope however clean the code is,
  and `code-commenting` owns how that prose is written.

If a rule below contradicts this section, this section wins.

---

## Standard: codebase-design

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/codebase-design/SKILL.md"`

---

## Standard: tdd

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/tdd/SKILL.md"`

---

## Standard: clean-code

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/clean-code/SKILL.md"`

---

## Standard: code-commenting

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/code-commenting/SKILL.md"`

---

## Standard: docs-sync

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/docs-sync/SKILL.md"`

---

## Standard: git-conventions

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/git-conventions/SKILL.md"`

---

## Now start

Do the "Ask first" step at the top of this file now, if you did not do it yet. The skill text above is long, so do not skip that step. Look at the last message that the user wrote. If it does not contain `/feature` or `/ai-skills:feature`, and the user did not say yes yet, ask the question from that step. Then end your turn and wait for the answer.

Build **$ARGUMENTS**, following the order above, through to step 7. Without `--auto`,
stop at each checkpoint and wait for `go`. With `--plan`, begin at
step 0: write the plan and wait for the user to accept it. Without it, begin at step 1:
state the interface and the seam, and ask which seams should be tested. Do not write an
implementation before there is a failing test for it.
