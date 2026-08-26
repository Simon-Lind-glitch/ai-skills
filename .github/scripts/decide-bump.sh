#!/usr/bin/env bash
# Prints the semver bump level implied by a range of Conventional Commits:
# major, minor, patch, or none.
#
# Usage:
#   decide-bump.sh      derive the range from the last v* tag
#   decide-bump.sh -    read a commit log on stdin
#
# That stdin path is the seam: it is what lets the behaviour be tested without
# pushing to main to find out. It is selected by an explicit argument rather
# than by detecting a tty, because CI has no tty and would take the wrong
# branch every time.
set -euo pipefail

# ASCII record separator, emitted before each subject so the type pattern can
# anchor to a subject rather than to any line. Without it a body line that
# happens to begin "feat:" would count as a feature.
RS=$'\036'

read_log() {
  if [ "${1:-}" != "-" ]; then
    local last_tag range
    last_tag=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo "")
    if [ -n "$last_tag" ]; then range="$last_tag..HEAD"; else range="HEAD"; fi
    git log "$range" --no-merges --pretty=format:"${RS}%s%n%b"
  else
    cat
  fi
}

log=$(read_log "${1:-}")

# A breaking change is either a `!` before the colon in the subject, or a
# BREAKING CHANGE: footer, which the spec puts at the start of its own line.
if printf '%s\n' "$log" | grep -qE "^${RS}[a-z]+(\([^)]*\))?!:" \
  || printf '%s\n' "$log" | grep -q '^BREAKING CHANGE'; then
  echo major
elif printf '%s\n' "$log" | grep -qE "^${RS}feat(\([^)]*\))?:"; then
  echo minor
elif printf '%s\n' "$log" | grep -qE "^${RS}fix(\([^)]*\))?:"; then
  echo patch
else
  echo none
fi
