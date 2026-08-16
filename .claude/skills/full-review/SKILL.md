---
name: full-review
description: >
  Token-frugal whole-repo audit. Fans out parallel subagent reviewers partitioned
  by code area (not by review skill), each reading its slice once and applying that
  slice's provably-safe fixes in the same pass, writing compressed findings to files
  that get assembled into TODO.md. Never commits. Use
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

## Never commit

This skill leaves everything uncommitted, always. No `git add`, no `git commit`, no
branch, no `git stash`, no push - not for the findings, not for the fixes, not "to keep
the tree clean". A sweep touches a hundred files across every area; the operator reviews
that diff before it becomes history, and they cannot review what is already committed.

- Report what changed and let the operator commit. If they ask you to commit, that is a
  separate instruction - follow it then, not now.
- A sweep runs on a tree that usually already has uncommitted work in it. `git add -A`
  bundles that work, plus any untracked scratch directories, into a commit the operator
  never chose. Never stage broadly.
- This overrides any general "finish by committing" habit or project instruction to
  commit completed work. A review is not completed work; it is a proposal.

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

**Markdown belongs to exactly one area.** Every `*.md` in the repo - specs, READMEs,
design docs - goes to the docs/project-meta area and NOWHERE else. Do not hand a
`SPEC.md` to a code reviewer "for context": specs are long, the reviewer pays to read
one per area, and it produces doc findings that duplicate what the docs reviewer
already reported. If a code area's contract genuinely matters, write the two relevant
sentences into its brief yourself - you read the spec once, in Phase 0, or not at all.

Same rule for anything else that is expensive per token and thin on findings: fixture
data, committed CSV/JSON datasets, snapshots, `*-lock.json`.

## Phase 1 - Review and mechanical fix (parallel subagents, one per AREA)

**At most 4 reviewers in flight.** Run the areas in waves of 4, not all at once. A
sweep is allowed to take time; what it is not allowed to do is lose 8 agents' worth of
half-finished work to one interruption. Wall-clock is cheap here, re-doing work is not.

**Per area, not per skill** - one frontend subagent applies every frontend lens at
once, so the files are read once, not once per lens.

**The reviewer also applies its own tier-A fixes.** This is the single biggest cost
lever in the whole skill. A reviewer that has just read a 1500-line file already knows
which three lines to change; handing that to a separate fixer agent later means a
second agent pays to read the same file again. Every file in the repo gets read twice
for no benefit. So: find and fix in one pass, while the file is in context.

Match lenses to the area:

| Area | Lenses the subagent applies |
| ---- | --------------------------- |
| Frontend / UI | ui-ux-best-practices + htmx (if HTMX) |
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

### Tier A vs tier B

The old single "auto-fixable Y/N" flag was too coarse and got over-trusted. Two tiers:

- **Tier A - provably no semantic change.** Unused import or unreachable branch, a
  docstring/comment that states a wrong fact, a hand-rolled format string replaced by
  the repo's shared formatter, a missing unit in a label. The reviewer APPLIES these.
- **Tier B - everything else**, including fixes that look like one-liners: deleting a
  function (something may call it, incl. a test), changing a default, changing a
  computed value, changing a signature, anything that alters an emitted number.
  Reported, never applied.

If a "mechanical" fix changes what the code computes, it is tier B. Two real examples
that were mislabelled A: removing `fillna(0)` from an ATR warmup (changes every
computed ATR, which feeds stops and sizing), and "delete this dead method" (a test
called it).

### The brief

Fill in `<area>`, `<paths>`, `<lenses>`, `<reviewdir>`:

```text
Review the <area> area of this repo, and apply your own tier-A fixes as you go.
Read ONLY these paths - do not explore elsewhere, do not re-run git:
<paths>

Apply these lenses: <lenses>. Read each relevant skill once, then review.

Work file by file: read a file, note its findings, and apply that file's tier-A
fixes before moving on - never a second pass over a file you already read.

TIER A (apply): provably no semantic change - unused import, unreachable branch,
a comment/docstring stating a wrong fact, a hand-rolled format string replaced by
the repo's shared formatter, a missing unit in a label.
TIER B (report only): everything else, including one-line-looking fixes that
delete a function, change a default, change a signature, or change any value the
code computes. When unsure, it is B.

Write findings to TWO files. Do not print them:
  <reviewdir>/<area>.applied.tsv   the tier-A fixes you made
  <reviewdir>/<area>.open.tsv      the tier-B findings

One finding per line, tab-separated, exactly these fields, no header:
  H|M|L <TAB> path:line <TAB> problem <TAB> fix

Field rules - these keep the file machine-readable and lint-clean:
- Plain ASCII. No HTML entities (&lt; &amp;), no smart quotes, no em dashes.
- No tabs or newlines inside a field.
- Backticks ARE allowed and REQUIRED around every code token: identifiers,
  paths, snippets. Write `_write_one`, `__init__`, `*args`, `period_weeks * 7`.
  A bare underscore or asterisk pair in prose renders as emphasis and breaks the
  markdown these files get assembled into. No other markdown - no bold, no
  bullets, no links.
- `problem` states the defect and its consequence. `fix` does not restate it.
- Do not repeat shared context across findings ("the trap CLAUDE.md warns
  about") - say it in the one finding it belongs to.
- Real issues only. Skip L-severity style nits unless they change meaning.

Your REPLY is only:
  APPLIED <n>
  OPEN <n> (H <n> / M <n> / L <n>)
  then the H-severity open lines verbatim, and nothing else.
The M and L lines stay in the file - they must not appear in your reply.
```

That last rule matters as much as the tier split. In a sweep this size the findings
text is the bulk of the payload, and printing it into the orchestrator's context means
it gets carried three times over: agent reply, then scratch file, then `TODO.md`.
Written straight to a file, hundreds of M/L findings never enter the main thread at
all - Phase 2 concatenates the files with shell, and the orchestrator only ever reads
the H lines it was shown.

Because subagents don't inherit CLAUDE.md, if the brief may lead to running Python or
git, paste the `dev-environment` skill into it. Reviewers apply fixes but MUST NOT run
git (see **Never commit**).

## Phase 1b - Convergence (main thread)

The area partition gives every reviewer only its own slice, so no one sees that
two services solve one problem in two shapes. Run the `convergence-audit` skill
once on the main thread to cover that cross-area structural layer. It's
report-only and whole-repo, matching this sweep's opt-in cost.

Its findings are structural consolidations - always tier B, never mechanical. They land
in `TODO.md` (Phase 2) and are never applied.

Worth the cost, and worth running properly: roughly half of what it surfaces is not a
someday-refactor but a live bug that the area partition structurally cannot see, because
the defect lives in the gap between two areas - one side of a boundary honouring a field
the other side never reads, two copies of a query disagreeing on strictness with the live
path on the lenient one, a client calling an endpoint no router defines.

Give it its OWN output format - the ranked blocks with the `net:` delta that its skill
specifies. Do not squeeze it into this skill's TSV: the `net complexity` line and the
rule-of-three citation ARE its guardrails, and a format that drops them produces
unvetted two-site "duplications" that fail its own gates.

Neither this sweep nor convergence-audit checks whether a unit does what its name
and docstring claim, whether it's reachable at all, or whether the service-level
shape serves the product's goal. That layer is `architecture-audit` - a separate
opt-in run, not part of this one.

## Phase 2 - Collect (main thread)

Assemble with shell, not by reading. The `.open.tsv` files hold hundreds of findings; if
you `Read` them you have just paid for the payload the file-output rule exists to avoid.

- Sort and dedup with `sort`/`awk`: same `path:line` = one entry.
- Render each area's TSV into a markdown section with one command. Backticks are already
  in the fields (the brief requires them), so the renderer adds no markdown of its own
  beyond the bullet and the severity marker.
- Then, and only then, `Read` the assembled section once to sanity-check it.
- Fold in the Phase 1b convergence findings as their own group, in their own format.
- Append to `TODO.md`, grouped by area, severity-sorted (H→M→L). Follow the `todo-md`
  skill's layout. Leave it uncommitted (see **Never commit**).

**Lint it at generation, never afterwards.** Wrap the generated section in
`<!-- markdownlint-disable MD037 MD049 MD050 -->` / `<!-- markdownlint-enable ... -->`.
Those three rules fire on the underscore and asterisk pairs that are unavoidable in
prose about code, and the disable is scoped to generated content only - the rest of the
file still lints normally.

Then run the repo's normal markdownlint pass. If something still trips: fix the
GENERATOR or the offending field, and re-render. Never post-process the rendered
markdown with `sed`/`awk`/a regex script - a regex that walks prose containing code
tokens will mangle real text (it turned `HYPOTHESIS_TEST_RESULTS.md` into
`` `HYPOTHESIS_TEST_RESULTS`.md ``), and three rounds of that on a cosmetic warning
costs more than the warning.

## Phase 3 - Verify and report (main thread)

Tier-A fixes already landed in Phase 1, so there is no separate fix pass. What is left:

- Run the repo's own checks: test suite (in whatever sandbox the project mandates),
  typecheck each build that has one, markdownlint. A sweep touching a hundred files
  cannot be handed over unverified.
- A check that now FAILS on a pre-existing defect rather than on your change is a
  finding, not something to paper over. Confirm it against a clean tree before you
  decide which it is, and if it is pre-existing, make it visible (a strict-xfail with a
  reason) rather than reverting the assertion that exposed it.
- Report: the diff stat, the checks you ran with their results, the open count by
  severity, and the handful of findings the operator most needs to decide.
- Do not commit (see **Never commit**).
