#!/usr/bin/env bash
# Make a small Python repo with one commit on main.
set -euo pipefail
git init -q -b main
printf 'def add(a, b):\n    return a + b\n' > calc.py
git add calc.py
git -c user.email=eval@example.com -c user.name=eval commit -qm "feat: add"
# Put one change on a topic branch, so that there is a branch to review.
git switch -qc topic
printf '\ndef sub(a, b):\n    return a - b\n' >> calc.py
git -c user.email=eval@example.com -c user.name=eval commit -qam "feat: add sub"
