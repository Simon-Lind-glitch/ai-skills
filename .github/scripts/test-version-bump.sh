#!/usr/bin/env bash
# Tests for decide-bump.sh and next-version.sh. Run it directly:
#
#     .github/scripts/test-version-bump.sh
#
# Every expected value here is a literal, never a value recomputed the way the
# scripts compute it, so a test can actually disagree with the code.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
decide="$here/decide-bump.sh"
next="$here/next-version.sh"
RS=$'\036'

pass=0
fail=0

check() {
  local name=$1 expected=$2 actual=$3
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$name" "$expected" "$actual"
  fi
}

bump_of() { printf '%s' "$1" | "$decide" -; }

# A commit as decide-bump.sh receives it: record separator, subject, then body.
commit() { printf '%s%s\n%s\n' "$RS" "$1" "${2:-}"; }

# Several commits in one log. Built here rather than by concatenating commit()
# calls, because command substitution strips the trailing newline and would run
# the next record separator onto the previous line, where it no longer anchors.
commits() {
  local subject
  for subject in "$@"; do printf '%s%s\n' "$RS" "$subject"; done
}

check "feat is a minor"        minor "$(bump_of "$(commit 'feat: add sso login')")"
check "feat with scope"        minor "$(bump_of "$(commit 'feat(auth): add sso login')")"
check "fix is a patch"         patch "$(bump_of "$(commit 'fix: handle expired token')")"
check "chore releases nothing" none  "$(bump_of "$(commit 'chore(deps): bump express')")"
check "docs releases nothing"  none  "$(bump_of "$(commit 'docs: rewrite the readme')")"
check "empty log"              none  "$(bump_of '')"

check "bang is a major"        major "$(bump_of "$(commit 'feat!: drop v1 endpoints')")"
check "bang with scope"        major "$(bump_of "$(commit 'fix(api)!: drop v1 endpoints')")"
check "breaking-change footer" major \
  "$(bump_of "$(commit 'feat: rework the api' 'BREAKING CHANGE: v1 is gone')")"

check "feat outranks fix" minor \
  "$(bump_of "$(commits 'fix: a' 'feat: b')")"
check "major outranks feat" major \
  "$(bump_of "$(commits 'feat: a' 'feat!: b')")"

# Regressions. Both of these used to bump when they should not have.
check "breaking-change in prose is not a footer" none \
  "$(bump_of "$(commit 'docs: note the policy' 'Avoid a BREAKING CHANGE unless forced.')")"
check "a type in the body is not the subject" none \
  "$(bump_of "$(commit 'docs: summarise' 'feat: quoted from another commit')")"

check "minor from 0.6.0"      0.7.0  "$("$next" 0.6.0 minor)"
check "patch from 0.6.0"      0.6.1  "$("$next" 0.6.0 patch)"
check "major from 0.6.0"      1.0.0  "$("$next" 0.6.0 major)"
check "none is unchanged"     0.6.0  "$("$next" 0.6.0 none)"
check "minor does not clamp"  1.10.0 "$("$next" 1.9.9 minor)"
check "patch resets on minor" 2.4.0  "$("$next" 2.3.7 minor)"

"$next" 0.6.0 sideways >/dev/null 2>&1
check "unknown level exits non-zero" 1 "$?"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
