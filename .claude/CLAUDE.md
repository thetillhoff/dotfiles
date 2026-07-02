# User CLAUDE.md

## Git

- Always use SSH URLs for `git clone`: `git@github.com:<owner>/<repo>.git` — never HTTPS.
- Repo layout: `~/code/<owner>/<repo>/` — `.git` may be at any subdirectory level within, not necessarily the root. Locate it before running git commands.
- Use `cd <path> && git <cmd>`, never `git -C <path> <cmd>`.
- Superpowers skills must never run git commands.

## Principles

- **DRY** (Don't Repeat Yourself) — one source of truth; extract only after 3+ identical uses, not before.
- **KISS** (Keep It Simple, Stupid) — simplest solution that works; never clever for clever's sake.
- **YAGNI** (You Ain't Gonna Need It) — don't build for hypothetical future needs; later can scaffold for itself.
- **SRP** (Single Responsibility Principle) — one unit does one job; split when a second unrelated reason to change appears.
- **CoC** (Convention over Configuration) — follow existing patterns before inventing new ones.
- **Fail fast** — surface errors at the boundary; don't swallow and continue silently.

## Scaffolding Over Manual File Creation

Prefer scaffolding commands (`npm create`, `cargo new`, `go mod init`, `docker init`, framework CLIs, etc.) over writing boilerplate by hand. Only write files manually when no scaffolding command covers it.

## Dev Environment

### Docker for Python and system-level runtimes

Always run Python in Docker - never install Python packages on the host. Node.js is exempt (dependencies go into `node_modules`). See the `dev-environment` skill for the full rule set and Docker command patterns.

### Git: cd then git, never git -C

Already stated above under Git. Repeated here as a reminder for hook sections below.

### Kubernetes manifests: one resource per file

One k8s manifest per file - never bundle multiple resources with `---` separators. Name files `<kind>-<name>.yaml` (e.g. `serviceAccount-trading-worker.yaml`), matching the existing dir convention. Wire each into `kustomization.yaml`.

## Memory

Never write project-specific memory to `~/.claude/projects/*/memory/` — those files are machine-local and invisible to colleagues or other machines. Put project context in the repo's `CLAUDE.md` instead (checked in, portable, always present). The auto-memory system is fine for truly global preferences (user style, cross-repo workflow rules) but not for anything repo-specific.

## Finishing Work (leave it closeable)

End a piece of work with the repo in a state a fresh session could close - no implied follow-up:

- Update the docs the change touched: `README.md`, `EXAMPLES.md`, `TODO.md`, design/spec docs, and `CHANGELOG.md` if the repo keeps one. Don't touch docs the change didn't affect.
- Capture next steps and known gaps in `TODO.md` so nothing lives only in chat.
- Commit completed work with a written message; never leave a coherent change uncommitted or half-applied. (Push only when asked.)
- Write down anything deliberately deferred (a `TODO.md` entry or a `ponytail:` comment) instead of leaving it implicit.
- Persist all session learnings to files — never rely on memory. Each learning that's reusable across repos (a workflow rule, a tool quirk, a preference) goes in this global CLAUDE.md or a global skill; each one specific to a repo goes in that repo's `CLAUDE.md`, docs, or a repo-local skill. This means editing existing skills and CLAUDE.md sections, not just adding new ones — if a skill or CLAUDE.md section was wrong, incomplete, or out of date during the session, correct it in place before finishing. Treat "I'll remember this" as a bug: if it isn't in a file, it didn't happen.

Stop because the work is at a clean point, not because the turn ran out. If a follow-up prompt would obviously just be "now tidy up / update the docs / commit", do that now.

## Superpowers Workflow Hooks

### During superpowers:writing-plans

- Any task that runs, tests, or installs Python must specify Docker in the plan steps.
- All git commands in the plan must use `cd <path> && git <cmd>` — never `git -C`.

### During superpowers:subagent-driven-development

**Before dispatching any subagent**, include the full content of the `dev-environment` skill in the subagent brief. Subagents do not inherit CLAUDE.md — without this, they will use `pip install` on the host and `git -C`, breaking both constraints.

### During superpowers:test-driven-development

- Python tests must run inside Docker. Do not run `pytest` or `python -m pytest` directly on the host.

### During superpowers:systematic-debugging

- If debugging involves running Python, run it in Docker. Do not install debug deps on the host.

### During superpowers:executing-plans

- Apply the same Docker and git constraints as during writing-plans when executing steps.

## Blog/Prose Writing Style

- No em dashes (—). Use a plain hyphen-minus surrounded by spaces ( - ) instead.

## Markdown Linting

After creating or editing any markdown file, auto-fix the mechanical issues first, then lint:

```sh
npx markdownlint-cli --fix --disable MD013 -- <file.md>
npx markdownlint-cli --disable MD013 -- <file.md>
```

`--fix` handles tables, bare URLs, list/heading spacing, etc. automatically. Fix any remaining reported errors (e.g. MD040 fenced-code language, which it can't infer) by hand before considering the task done.

## Markdown Writing Style

When writing or editing markdown documents (ADRs, design docs, architecture docs):

- **DRY** — Extract shared information into a single section and reference it. Don't repeat the same facts across options/sections.
- **Concise** — One sentence where one sentence suffices. No filler, no restating what the reader just read.
- **Diagrams over paragraphs** — Prefer diagrams to explain architecture, data flow, or component relationships. Always use Mermaid JS for diagrams in markdown files and READMEs (never ASCII art). Each node shows the component name and role on separate lines (e.g., `Kamailio\nSIP Registrar`). Include a color-coded legend inside the diagram (e.g., mermaid subgraph) only when connection types need explanation (e.g., solid = direct, dotted = indirect). The legend describes connection semantics, not components — components are self-described by their node labels.
- **Tables and bullet lists over paragraphs** — But only when they add clarity. Don't create tables or comparisons for the sake of it. Ask the user if unsure.
- **Per-option: only what's unique** — Shared traits go in a shared section. Each option describes only its delta.
- **Short advantages/disadvantages** — One line per point. No preamble.
- **Living lists use plain bullets** — `TODO.md`, backlogs, roadmaps, next-steps: unordered `-` only — never ordered `1. 2. 3.` and never checkboxes `- [ ]`. When an item is done, delete it; don't mark it complete or keep a "done" list (git history is the record). Adding/removing an item must not renumber or churn the rest. Ordered lists are only for genuinely sequential procedures where the numbers carry meaning.
