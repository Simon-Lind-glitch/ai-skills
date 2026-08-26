#!/usr/bin/env bash
# Prints the version that follows <current> at the given <bump> level.
# `none` prints <current> unchanged, so a caller can print it without branching.
set -euo pipefail

current=${1:?usage: next-version.sh <current> <bump>}
bump=${2:?usage: next-version.sh <current> <bump>}

IFS='.' read -r major minor patch <<<"$current"

case "$bump" in
  major) echo "$((major + 1)).0.0" ;;
  minor) echo "$major.$((minor + 1)).0" ;;
  patch) echo "$major.$minor.$((patch + 1))" ;;
  none) echo "$current" ;;
  *)
    echo "next-version.sh: unknown bump level: $bump" >&2
    exit 1
    ;;
esac
