---
name: dev-environment
description: Apply when running, testing, debugging, or planning code execution - and ALWAYS include verbatim in every subagent brief dispatched via superpowers:subagent-driven-development. Enforces Docker for Python and other system-dep runtimes; enforces cd&&git instead of git -C. Subagents do not inherit CLAUDE.md, so this skill is the only way these constraints reach them.
---

# Dev Environment Constraints

These rules apply to you and to every subagent you dispatch. Include this section verbatim in subagent prompts.

---

## Docker for Python and system-level runtimes

**Always use Docker for:**

- Python - scripts, tests, package installation, REPL, tooling
- Any runtime that requires system packages (C libraries, build tools, system headers, shared libs)

**Do NOT use Docker for:**

- Node.js - install into `node_modules` (project-local, no system pollution)
- Single-binary tools with no system-level deps
- Pure shell/bash scripts

**Why:** Python packages frequently depend on system libraries that cannot be scoped to a project directory. Host-level installation causes version conflicts and pollutes the system. Docker keeps runtimes isolated without requiring anything from the host.

**How:**

- Use the project's existing `Dockerfile` or `docker-compose.yml` when present.
- Otherwise use an ephemeral container:

  ```bash
  docker run --rm -v "$(pwd)":/app:z -w /app python:<version> python script.py
  ```

- For dependency install + run in one shot:

  ```bash
  docker run --rm -v "$(pwd)":/app:z -w /app python:<version> sh -c "pip install -r requirements.txt && python script.py"
  ```

- For tests:

  ```bash
  docker run --rm -v "$(pwd)":/app:z -w /app python:<version> sh -c "pip install -r requirements.txt && pytest"
  ```

- Mount only what is needed. Do not mount `~` or `/`.

---

## Dockerfile image layering: deps first, then COPY the whole dir

1. COPY dependency manifests + lockfiles, then install - caches until deps change.
2. `COPY . .` guarded by `.dockerignore` (exclude `.git`, `node_modules`, build artefacts, secrets, caches).

Never enumerate source files (`COPY a.py b.py …`): a new module gets silently omitted → runtime `ImportError` that tests miss, because tests mount the source dir and run against the mount, not the baked image. Must enumerate (monorepo, minimal image)? Verify one import against the **built** image.

---

## SELinux volume relabeling (podman / Fedora / RHEL)

On SELinux hosts a bind-mounted dir is unreadable in the container unless relabeled.
**Always add the lowercase `:z` suffix to the `-v` source.** It applies a shared label
readable by any container and back on the host, re-relabels recursively on every mount
(so stale files self-fix), and is ignored on non-SELinux hosts - always safe.

---

## Git commands: always `cd` then `git`, never `git -C`

**Always:**

```bash
cd <path> && git <cmd>
```

**Never:**

```bash
git -C <path> <cmd>
```

**Why:** Allowed git commands are matched by command name. The `-C` flag changes the effective command signature seen by the permission system, which invalidates pre-approved commands and triggers a new prompt every time.
