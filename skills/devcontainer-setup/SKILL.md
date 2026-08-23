---
name: devcontainer-setup
description: Set up a devcontainer before doing development work in an existing repo, so the agent runs sandboxed and cannot reach host credentials by accident. Use when starting work on a repo, when asked about environment or dev-container setup, or before running a build, test suite, or install for the first time.
---

# Devcontainer Setup

Development work happens inside a devcontainer. The point is containment: the agent gets a shell, and that shell should reach the repo and its toolchain, not the developer's machine.

## Why sandbox the agent

A shell on the host reaches everything the developer's account reaches — `~/.ssh`, `~/.aws`, `~/.config/gcloud`, kubeconfig, npm and PyPI publish tokens, `.env` files belonging to every other project on the disk, and whatever the host exported into the environment. Building and testing one repo needs none of it.

Inside a container, reaching any of that requires an explicit mount. That turns credential exposure into a decision someone made rather than a side effect of running a command in the wrong directory.

## Am I inside one right now?

Answer this first, and do not answer it from the filesystem. A `.devcontainer/devcontainer.json` in the repo means someone *can* build a container here; it says nothing about the process running this shell. Opening the folder directly instead of reopening in the container, or attaching a plain terminal to the repo, puts the session on the host with every host credential in reach — sitting next to a config file that makes it look otherwise. The config is not the container.

Check the running environment instead:

- `REMOTE_CONTAINERS`, `REMOTE_CONTAINERS_IPC`, `DEVCONTAINER`, or `CODESPACES` set in the environment — the devcontainer tooling sets these inside the container.
- `/.dockerenv` exists (Docker), or `/run/.containerenv` (Podman).
- `/proc/1/cgroup` or `/proc/1/environ` names `docker`, `containerd`, or `libpod` — catches the case where the environment was stripped, though it is not reliable under every cgroup v2 setup.
- The workspace lives under `/workspaces/`, and `$HOME` is a container user's home rather than the developer's.

**Ambiguous means host.** If nothing fires, or the signals disagree, treat the session as unsandboxed. The false positive is the expensive one: it means working as though credentials are out of reach while standing on top of them.

## The default

Before development work in an existing repo:

1. **Establish where this shell is actually running**, using the checks above.
2. **Inside a container already** — nothing to do. Containers do not nest usefully; the sandbox is in place.
3. **On the host, config present** — say so plainly: the repo defines a container and this session is not in it. Point at reopening in it. This is the case that quietly looks safe, so name it instead of proceeding as if the file were doing the work.
4. **On the host, no config** — propose one and stop. Say what it would contain and what it keeps out of reach. Wait for a yes.
5. **Told no, either way** — proceed on the host. Name once, in a sentence, which credentials the session can now reach. Then drop it: no repeat asking, no re-litigating later in the session.

This is a default, not a gate. Answering a question, reading code, editing a doc, or a one-line fix does not need a container. It applies when a session is about to build, install dependencies, run a test suite, or execute project tooling.

## Exception: a project that does not exist yet

Starting from scratch is not gated on a devcontainer. There is no toolchain to pin and no dependency to install, so the container would be guesswork. Scaffold the project first, then offer a devcontainer once the language, runtime version, and test command are settled — that is the point where pinning them is worth something.

## Rules for the container itself

Write the container for the project in front of you — read its manifests, its CI config, and its test command, and pin what they actually need. Devcontainer features and base images move faster than any checked-in example, so these are the constraints the result has to satisfy, not a shape to copy.

- **`remoteUser` is not root.** A root container writes root-owned files into the bind-mounted workspace, and the host has to clean up after it.
- **Mount nothing from the host home directory.** Not `~/.ssh`, not `~/.aws`, not `~/.config`. A bind mount of any of these hands over exactly what the container exists to withhold.
- **Agent state goes in a named volume**, not a bind to the host's copy. A named volume for `~/.claude` keeps the login and installed plugins across rebuilds without inheriting the host's user-scope settings.
- **Pass secrets one variable at a time** through `remoteEnv` from `${localEnv:...}`. One named variable is auditable; a mounted credentials directory is not.
- **Bind mounts the container only reads are `readonly`.** Datasets, reference checkouts, extracted assets — mark them and a mistake becomes an error instead of a corrupted source.
- **Pin the toolchain in the `Dockerfile`**, including versions that must match a target runtime exactly. The image is the record of what the project builds against.
- **`postCreateCommand` is idempotent.** It re-runs on every rebuild.
- **Install the agent CLI in the image, never its credentials.** Auth lives in the volume, so the image stays free of secrets and shareable.

## Checklist

- [ ] Did I check the running environment, rather than infer the sandbox from a `devcontainer.json` on disk?
- [ ] If the signals were ambiguous, did I treat the session as being on the host?
- [ ] If on the host with a config present, did I say so instead of carrying on?
- [ ] Did the user say yes to creating one?
- [ ] Does `remoteUser` resolve to a non-root user?
- [ ] Is every mount either the workspace, a named volume, or `readonly`?
- [ ] Is each secret a single named variable rather than a mounted directory?
- [ ] Does a rebuild reproduce the environment without a manual step?
