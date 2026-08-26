---
name: feature
description: Build a feature with this repo's engineering standards already in context — codebase-design, tdd, clean-code, code-commenting, and git-conventions are inlined at load time, in the order the work happens.
argument-hint: "[what to build]"
disable-model-invocation: true
allowed-tools:
  - Bash(cat ${CLAUDE_PLUGIN_ROOT}/skills/*)
---

# Feature

Build: **$ARGUMENTS**

Five skills are inlined below. They are already in context — do not invoke them again, and
do not go looking for them on disk.

## The order the work happens

The skills overlap, so their precedence matters more than their content.

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
   wrong, and nothing that narrates the change you just made. Refactoring is a stage of its
   own, not a step inside the red → green loop.
5. **Branch, commit, and title the MR** per `git-conventions`, which is also what decides
   whether a release gets cut.

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

## Standard: git-conventions

!`cat "${CLAUDE_PLUGIN_ROOT}/skills/git-conventions/SKILL.md"`

---

## Now start

Build **$ARGUMENTS**, following the order above. Begin at step 1: state the interface and
the seam, and ask which seams should be tested. Do not write an implementation before
there is a failing test for it.
