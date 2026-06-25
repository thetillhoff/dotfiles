# User CLAUDE.md

## Git

- Always use SSH URLs for `git clone`: `git@github.com:<owner>/<repo>.git` — never HTTPS.
- Repo layout: `~/code/<owner>/<repo>/` — `.git` may be at any subdirectory level within, not necessarily the root. Locate it before running git commands.
- Use `cd <path> && git <cmd>`, never `git -C <path> <cmd>`.
- Superpowers skills must never run git commands.

## Dev Environment

### Docker for Python and system-level runtimes

Always run Python in Docker - never install Python packages on the host. Node.js is exempt (dependencies go into `node_modules`). See the `dev-environment` skill for the full rule set and Docker command patterns.

### Git: cd then git, never git -C

Already stated above under Git. Repeated here as a reminder for hook sections below.

## Finishing Work (leave it closeable)

End a piece of work with the repo in a state a fresh session could close - no implied follow-up:

- Update the docs the change touched: `README.md`, `EXAMPLES.md`, `TODO.md`, design/spec docs, and `CHANGELOG.md` if the repo keeps one. Don't touch docs the change didn't affect.
- Capture next steps and known gaps in `TODO.md` so nothing lives only in chat.
- Commit completed work with a written message; never leave a coherent change uncommitted or half-applied. (Push only when asked.)
- Write down anything deliberately deferred (a `TODO.md` entry or a `ponytail:` comment) instead of leaving it implicit.

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

After creating or editing any markdown file, lint it with:

```sh
npx markdownlint-cli --disable MD013 -- <file.md>
```

Fix all reported errors before considering the task done.

## Markdown Writing Style

When writing or editing markdown documents (ADRs, design docs, architecture docs):

- **DRY** — Extract shared information into a single section and reference it. Don't repeat the same facts across options/sections.
- **Concise** — One sentence where one sentence suffices. No filler, no restating what the reader just read.
- **Diagrams over paragraphs** — Prefer diagrams to explain architecture, data flow, or component relationships. Always use Mermaid JS for diagrams in markdown files and READMEs (never ASCII art). Each node shows the component name and role on separate lines (e.g., `Kamailio\nSIP Registrar`). Include a color-coded legend inside the diagram (e.g., mermaid subgraph) only when connection types need explanation (e.g., solid = direct, dotted = indirect). The legend describes connection semantics, not components — components are self-described by their node labels.
- **Tables and bullet lists over paragraphs** — But only when they add clarity. Don't create tables or comparisons for the sake of it. Ask the user if unsure.
- **Per-option: only what's unique** — Shared traits go in a shared section. Each option describes only its delta.
- **Short advantages/disadvantages** — One line per point. No preamble.
- **Living lists use plain bullets** — `TODO.md`, backlogs, roadmaps, next-steps: unordered `-` only — never ordered `1. 2. 3.` and never checkboxes `- [ ]`. When an item is done, delete it; don't mark it complete or keep a "done" list (git history is the record). Adding/removing an item must not renumber or churn the rest. Ordered lists are only for genuinely sequential procedures where the numbers carry meaning.
