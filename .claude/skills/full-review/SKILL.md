---
name: full-review
description: >
  Token-frugal whole-repo audit. Fans out parallel subagent reviewers partitioned
  by code area (not by review skill), each reading only its slice once, returning
  compressed findings that get deduped into TODO.md and auto-fixed where safe. Use
  whenever the user wants the entire repo/codebase reviewed or audited at once - not
  a single diff or PR. Triggers on: "full review", "audit this repo", "audit the
  codebase", "review the whole repo", "review everything", "whole-repo review",
  "review all the code", "find all the issues in this project". For a single diff or
  PR use /code-review or /review instead; this is the multi-area, whole-tree sweep.
---

# full-review

Whole-repo audit that stays cheap. Three moves keep it token-frugal without losing
coverage: **read each file once**, **partition by area not by skill**, **compressed
findings only**. Every lens still applies to every relevant file - only duplication
and prose are cut.

## Phase 0 - Inventory (main thread, single pass)

Build the map yourself so reviewers never re-explore.

- `git ls-files` for the tracked file list.
- Drop generated/vendored/lock noise: `node_modules`, `dist`, `build`, `vendor`, `*.lock`, `*-lock.json`, `*.min.*`, snapshots, generated clients.
- Group the survivors into **areas** - natural review boundaries discovered from the tree, not a fixed set:
  - a frontend/UI area (templates, components, styles, client JS),
  - one area per backend service (`services/*/`, `cmd/*/`, each deployable),
  - a shared/library/utils area,
  - config/infra (CI, k8s, Dockerfiles, IaC) only if worth reviewing,
  - project-meta: `CLAUDE.md` / `AGENTS.md` at any level, and `.claude/skills/*/SKILL.md` - if present (a dotfiles or skills repo may be *mostly* this).
- A monorepo may have many areas; a small monolith one or two. Match reality.

Output: a path list per area. That list is the **only** input a reviewer gets.

## Phase 1 - Review (parallel subagents, one per AREA)

Spawn one subagent per area, all in a single turn. **Per area, not per skill** - one
frontend subagent applies every frontend lens at once, so the files are read once, not
once per lens.

Match lenses to the area:

| Area | Lenses the subagent applies |
| ---- | --------------------------- |
| Frontend / UI | ui-ux-best-practices + htmx (if HTMX) + interface-kit |
| Each service | microservice-architecture |
| Shared / utils | review-comments |
| Config / infra | relevant infra skill if one exists |
| Skills (`SKILL.md`) | skill-creator (review/audit mode - coverage, gaps, bloat, drift) |
| `CLAUDE.md` / `AGENTS.md` | claude-md-writer (brevity, staleness, redundancy) |

Domain lenses only - the universal lenses below apply on top of every *code*
row (not the doc rows: skills, `CLAUDE.md`).

**Universal lenses (native/official, always available).** On top of its domain
skills, every code area also gets:

- `code-review` - correctness (the `/code-review` command or `code-review:code-review` plugin skill),
- `/security-review` - vulnerabilities,
- `/simplify` (or `code-simplifier`) - dead code, over-engineering.

These ship with Claude Code, so they don't drift with local skills. The table's
per-area entries are the domain layer added on top; the local skills (ui-ux, htmx,
microservice-architecture, review-comments, skill-creator, claude-md-writer) are
your own.

Give each subagent this brief (fill in `<area>` and `<paths>`):

```text
Review the <area> area of this repo. Read ONLY these paths - do not explore
elsewhere, do not re-run git:
<paths>

Apply these lenses: <lenses>. Read each relevant skill once, then review.

Return findings in EXACTLY this format, one per line, nothing else:
  path:line | H|M|L | problem | fix | Y|N

- Severity H/M/L. auto-fixable Y only if the fix is mechanical and unambiguous
  (no A-vs-B judgement call).
- Real issues only. No style nits below M unless they change meaning.
- No prose, no praise, no summary. The lines ARE the whole reply.
```

Because subagents don't inherit CLAUDE.md, if the brief may lead to running Python or
git, paste the `dev-environment` skill into it.

## Phase 2 - Collect (main thread)

- Dedup across areas: same `path:line` = one entry (merge lenses).
- Append to `TODO.md` grouped by area, severity-sorted (H→M→L). One line per finding.
  No cap on count. Follow the `todo-md` skill's layout. Don't stage/commit `TODO.md`
  unless already tracked.

## Phase 3 - Fix (main thread)

- Fix only `auto-fixable=Y` findings.
- Any A-vs-B or judgement call: leave the TODO entry, skip it, move on. Never guess.
- Batch all fixes for one file together; don't reload a file already in context.
- After fixing, delete the fixed entries from `TODO.md` (git history is the record) -
  what remains is exactly the decisions the user still owes.
