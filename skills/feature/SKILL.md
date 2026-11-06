---
name: feature
description: "Build a feature with the engineering standards in context: codebase-design, tdd, clean-code, code-commenting, docs-sync, git-conventions, then review-loop. With --plan, it proposes a plan first. TRIGGER when the user asks to build, implement, add, or change a feature, an endpoint, a component, a command, or a behavior in code. Asks before it starts. SKIP for a question, a one-line fix, a config value, or a change that is only docs."
argument-hint: "[--plan] [what to build]"
allowed-tools:
  - Bash(cat ${CLAUDE_PLUGIN_ROOT}/skills/*)
---

# Feature

## Ask first

Do this step before anything else in this file. Do not run a tool before it.

Look at the last message that the user wrote, as text. Do not look at what the skill loader added.

- If that message contains `/feature` or `/ai-skills:feature`, skip this step.
- If another skill told you to read this file, skip this step.
- If the user already said yes to this skill in this conversation, for this task, skip this step.
- Otherwise you called the Skill tool for this skill yourself, because the request matched its description. That is a suggestion, not a request from the user. Do not start the work. Ask the user one question, then end your turn and wait:

  > This looks like feature work. Use the `feature` skill? It loads clean-code, tdd, codebase-design, and the git conventions, and runs `review-loop` at the end. Reply `yes`, `yes --plan`, or `no`.

  - On yes, continue with this file. Use the request of the user as `$ARGUMENTS`.
  - On no, do the task without this skill. Do not ask again for the same task.

Build: **$ARGUMENTS**

If the arguments include `--plan`, remove it from the text above: it is a flag, not part
of what to build. Then start at step 0 below. Without `--plan`, skip step 0 and start at
step 1.

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
1. **Shape the module before writing anything.** Decide the interface, where the seam
   goes, and how much sits behind it. Use the `codebase-design` vocabulary below to say it
   out loud: module, interface, depth, seam, adapter, leverage, locality.
2. **Agree the seams under test, then confirm them.** No test is written at an unconfirmed
   seam. Ask which seams matter before writing the first test, not after.
3. **Red → green, one vertical slice at a time.** One seam, one failing test, one minimal
   implementation, repeat. Never write all the tests first — that is horizontal slicing,
   and it verifies imagined behavior.
4. **Then clean up.** Naming and function shape per `clean-code`; comments per
   `code-commenting`, which means the non-obvious _why_ on the line that is easy to get
   wrong, in ASD-STE100 Simplified Technical English, and nothing that narrates the change
   you just made. Refactoring is a stage of its own, not a step inside the red → green
   loop.
5. **Sync the docs.** Per `docs-sync`: list the names the change touched, grep the prose
   for them, and update or delete every stale hit. Write the prose in ASD-STE100, per
   `code-commenting`. A feature is not done while a doc it contradicts still ships, and the
   doc changes go in the same commit as the code.
6. **Branch, commit, and title the MR** per `git-conventions`, which is also what decides
   whether a release gets cut.
7. **Review until nothing blocks.** Run
   `cat "${CLAUDE_PLUGIN_ROOT}/skills/review-loop/SKILL.md"` and follow it with its
   defaults: `lensed-review` on the branch, until no severe or blocking finding is left,
   10 rounds at most. Its fixes follow steps 3 to 6: a test before a correctness fix, the
   standards above, and a commit per round. The feature is done when the loop stops
   clean. If it stops for another reason, give its report to the user and stop there.

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

Build **$ARGUMENTS**, following the order above, through to step 7. With `--plan`, begin at
step 0: write the plan and wait for the user to accept it. Without it, begin at step 1:
state the interface and the seam, and ask which seams should be tested. Do not write an
implementation before there is a failing test for it.
