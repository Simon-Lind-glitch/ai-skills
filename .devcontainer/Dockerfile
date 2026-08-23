# Node is here for one reason: it is what the Claude Code CLI installs onto.
# Nothing in this repo is a Node project, so the tag pins the CLI's runtime,
# not a target the plugin has to match.
FROM mcr.microsoft.com/devcontainers/javascript-node:22-bookworm

# The repo's only executable code is the bash in .github/workflows and the JSON
# manifests that bash rewrites. jq reads and writes those manifests exactly the
# way the workflow does, and shellcheck lints the workflow.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      jq \
      shellcheck \
 && rm -rf /var/lib/apt/lists/*

# gh is what the release step calls, so it is pinned rather than taken from
# apt: bookworm ships 2.23 from 2023, and a local gh three years behind the
# one on ubuntu-latest defeats the point of reproducing CI here.
ARG GH_VERSION=2.98.0
RUN arch="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/gh.deb \
      "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${arch}.deb" \
 && dpkg -i /tmp/gh.deb \
 && rm /tmp/gh.deb

# The agent CLI ships in the image. Its credentials do not — they live in the
# named volume mounted over ~/.claude below, which is what keeps this image
# free of secrets and shareable.
RUN npm install -g @anthropic-ai/claude-code markdownlint-cli2

# Docker seeds a fresh named volume from whatever the image has at the mount
# point, ownership included. Creating this as node up front is what stops the
# ~/.claude volume from mounting root-owned on first build.
RUN install -d -o node -g node /home/node/.claude

USER node
