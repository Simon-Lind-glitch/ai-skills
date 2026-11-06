#!/usr/bin/env bash
# Make a small Python repo with one commit on main.
set -euo pipefail
git init -q -b main
printf 'def add(a, b):\n    return a + b\n' > calc.py
git add calc.py
git -c user.email=eval@example.com -c user.name=eval commit -qm "feat: add"
