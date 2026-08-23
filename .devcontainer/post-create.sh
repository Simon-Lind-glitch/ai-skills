#!/usr/bin/env bash
# Runs on every rebuild, so every step here has to be safe to repeat.
set -euo pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

git config --global --add safe.directory "$WORKSPACE"

# This repo *is* the ai-skills plugin, which is why the marketplace points at
# the working tree instead of at GitHub the way a consuming repo's would: the
# skills the agent loads in here are the ones being edited, not the last
# published release.
#
# User scope, not project or local: those write the marketplace source into the
# workspace, and the source is an absolute container path that a session on the
# host would then try and fail to resolve. User scope keeps it in the ~/.claude
# volume, where it is container-only and survives a rebuild.
#
# Surviving a rebuild is also why this branches — a second run finds the
# marketplace already registered, and re-reading the same path is the
# idempotent form of adding it.
if claude plugin marketplace list 2>/dev/null | grep -q 'ai-skills'; then
  claude plugin marketplace update ai-skills
else
  claude plugin marketplace add "$WORKSPACE" --scope user
fi

claude plugin install ai-skills@ai-skills --scope user --yes

claude plugin list
