---
name: architecture-audit
description: >
  Whole-repo architecture and intent audit. Extracts every class/method with its
  signature fingerprint, its ACTUAL purpose from the body, and its CLAIMED purpose
  from name+docstring, flags the drift, then merges file → service → inter-service
  into C4-style mermaid maps and asks whether the resulting shape still serves what
  the product is for. Finds dead code, dead interfaces, dead services, misnamed and
  mis-documented units, bypassed abstractions, layering violations, contract drift
  between two sides of an edge, and design flaws that weaken the product's core job.
  Use whenever the user asks about architecture, structure, or design health rather
  than a specific diff. Triggers on "architecture audit", "architecture review",
  "is the design sound", "find dead code", "dead interfaces", "unused endpoints",
  "what services are still used", "do the docs match the code", "do our diagrams
  match reality", "C4 diagram", "map the architecture", "structural issues",
  "does our structure hurt <the product's goal>", "why is this hard to change".
  Distinct from full-review (per-area correctness lenses), convergence-audit
  (duplicate implementations) and review-comments (comment wording in a diff).
---

# architecture-audit

Three questions, in this order. Everything below serves them.

- **drift** — does each unit do what its name and doc claim?
- **reachability** — is each unit actually reached, and by whom?
- **fitness** — does the resulting shape serve what this repo is FOR?

Drift and reachability are mechanical enough to fan out cheaply. Fitness is the
payoff and needs the other two as evidence, which is why it runs last.

Cost is real (whole tree, many agents), so this is opt-in. An argument scopes it
to a subtree; the phases are unchanged, just narrower.

## The blind pass (why the phases are ordered this way)

**Phases 1-4 read code only. Architecture docs stay shut until Phase 5.** The whole
value of this audit is an independent second opinion on what the system *is*, and a
diagram read beforehand destroys that: you start confirming its boxes instead of
deriving your own, and every drift it contains becomes invisible because it now
frames your reading. Docs are a *claim* this audit judges — never an input to it.
The same goes for competing sources: when `CLAUDE.md`, a `spec/`, and a README
disagree, the code is what runs.

So build your own map first, then compare. Write every artifact to a scratch dir
inside the git dir, which can never be staged, committed, or caught by
`git status` / `git clean`:

```bash
SCRATCH="$(git rev-parse --git-dir)/review-$(date +%s)" && mkdir -p "$SCRATCH"
```

(`git rev-parse` resolves it correctly in a worktree, where `.git` is a file.)

One file per unit, per boundary pass, and per synthesis step. **After Phase 4 the
scratch artifacts are frozen** — reading the docs will tempt you to quietly
harmonize your findings with them, so corrections after that point go into the
Phase-5 reconciliation with a stated reason, never as edits to the frozen map.

## Phase 0 — Preflight, purpose, inventory, extractors (main thread)

**`bash scripts/preflight.sh` from the repo root, first thing.** It reports which
languages are here and whether each one's extractor and reachability tools are
usable. A gap changes the plan rather than blocking it (agents read instead of
parsing — slower and pricier; dead-code findings rest on greps alone), and that
tradeoff is the user's to price, so it must be surfaced before anything is spawned.
Install nothing yourself.

**Then ask once, and wait.** Combine both openers into a single message so the run
costs one round trip:

1. the purpose — *"I understand this repo exists to X; the value flows through Y;
   the thing that must not break is Z. Correct?"* Phase 4 judges everything against
   that answer, so guessing it burns the whole run. Derive the proposal from the
   **product surface in code** (entry points, CLI verbs, service and route names,
   the README's one-line intent) — not from architecture docs, which are the blind
   pass's subject matter. You need what the system is *for*, which the user owns;
   how it's built comes from the code. In Claude Code an auto-loaded `CLAUDE.md` is
   already in context — you can't unsee it, so treat any structural claim in it as a
   claim to verify in Phase 5, and don't go reading further into it;
2. the preflight `MISSING` lines with their install commands, plus what each gap
   costs, and the option to proceed degraded.

Correct your understanding from their reply before spawning anything.

Then build the map yourself so no agent re-explores:

- `git ls-files`, drop generated/vendored/lock/minified noise.
- Group survivors into **units**: one per deployable/service, plus each coherent
  library module. Tests are their own unit and get a lighter pass — their real
  value here is reachability evidence (a symbol only tests call is dead in
  production terms, and that only shows up if tests are inventoried too).
- Note the languages present.

**Run the extractors — see `references/extractors.md` for commands and caveats.**
Two jobs there:

- **Symbol harvest** (bundled scripts for Python, Go, TS/JS): a TSV of every
  class/func/method with signature, visibility and docstring. This is the half of
  Phase 1 that is pure transcription, so a parser should do it — agents spend
  their tokens on judgement instead. Split the TSV per unit for Phase 1.
- **Reachability** (whatever the repo already has: `knip`, `vulture`, `deadcode`,
  …; never install anything): whole-repo call/import analysis, so its output goes
  to Phases 2-3 where the cross-file view is. Every such tool over-reports dead
  because framework-invoked code looks uncalled, so it produces *leads to confirm*,
  never verdicts.

A language with no extractor loses nothing but speed: the Phase-1 agent produces
the same columns by reading.

## Phase 1 — Drift scan (haiku, one agent per unit batch of ~8-12 files)

Haiku fits because this is local bounded reading: one file at a time, no
cross-file judgement. Batch files — one agent per file means hundreds of agents.

Hand each agent its batch's harvest rows (`path line kind vis name signature doc`)
so it starts from the symbol list rather than rebuilding it, and require it to
read the bodies anyway: the harvest carries no behaviour, and `purpose` is the
whole point of the phase.

Brief each agent to emit only these two blocks, no prose:

```text
sym: path:line | kind | name | fingerprint | purpose | doc | MATCH|DRIFT|MISNAMED|UNDOC
edge: path:line | this-unit -> target | import|call|http|db|queue|cr|cli
```

- `fingerprint` — the harvest's signature plus what the body touches
  (`pure`, `io`, `db`, `net`, `mutates-arg`, `global`). The effects are the part
  a parser can't see and the part that exposes a lying docstring.
- `purpose` — what the body ACTUALLY does, ≤10 words, inferred from the body
  alone. Read the body before the docstring; reading the doc first anchors it.
- `doc` — the claim made by the docstring/comment, or `-` if none.
- `DRIFT` doc contradicts body · `MISNAMED` name implies something the body
  doesn't do (a name is documentation, and the most-read kind) · `UNDOC`
  non-obvious public symbol with no claim at all · `MATCH` otherwise.
- Apply the `review-comments` lens on the same pass (WHY-not-WHAT, history in
  comments, restating names, stale claims) and emit those as
  `cmt: path:line | violation | suggested`. Same read, so it's nearly free —
  and a comment that describes a former behaviour is drift by another name.

Two lines every fan-out brief needs: **"read code only — no `spec/`, no
`ARCHITECTURE.md`/`DEVELOPMENT.md`, no diagrams; if you catch yourself checking what
the docs say, that's the bias this phase exists to avoid"**, and the path in
`$SCRATCH` to write its block to. Subagents don't inherit `CLAUDE.md`, so also paste
the `dev-environment` skill into any brief that might run the repo's tooling — which
is a bonus here: they start docs-blind by default.

## Phase 2 — Unit synthesis (sonnet, one agent per unit)

Input: that unit's Phase-1 lines from `$SCRATCH` plus its slice of the extractor
output. Not the files again, and still no docs. Produce (into `$SCRATCH`):

- a mermaid **C4 component** diagram of the unit's internals;
- findings: exported-never-called (cross-checked against the tool), layering
  violations (lower layer calling upward, a helper reaching into a caller's
  concern), god-modules and SRP breaks, drift *clusters* (a module whose docs are
  systematically stale is a module nobody reads — worth more than the individual
  DRIFT lines), name-vs-role mismatch at module level.

Repo-wide duplicate implementations belong to `convergence-audit`; note and hand
off rather than re-deriving them here.

## Phase 3 — Boundary synthesis (opus, one agent)

Input: all Phase-2 outputs in `$SCRATCH` plus the `edge:` lines. The edges are where
the worst defects hide, because no single-unit review can see both ends — and the
boundary map is the artefact the docs will be diffed against in Phase 5, so it must
be derived from code alone (a service diagram is the single most tempting doc to peek
at, and the one whose staleness costs most).

- a mermaid **C4 container** diagram: services, datastores, queues, external
  systems, entry points (cron, CLI, operator, UI).
- findings: **dead interface** (endpoint/topic/table/CR with no producer, or no
  consumer), **dead service** (nothing routes to it and it starts nothing),
  **bypassed abstraction** (a caller reaching past a facade — writing another
  service's table, importing its internals), **contract drift** (the two sides of
  one edge disagree on shape, units, nullability, or error semantics), cycles and
  chatty coupling.

## Phase 4 — Fitness (opus)

Given the purpose confirmed in Phase 0 and the maps from 2-3 (still code-only):
**where does the structure fight the goal?** Not a checklist — reason it out:

- which paths actually carry the value, and what could silently degrade them;
- what is easy to get wrong and hard to verify, especially near the risky part;
- which invariant is held only by convention, so a plausible edit breaks it;
- what the shape makes expensive to change, and whether that's where change is
  most likely.

Rank by cost-to-the-goal if wrong, not by code aesthetics. Cite `path:line`.

**Then attack the reachability half of your own headline finding before writing it
down.** The mechanism ("this function omits X") and the blast radius ("and it's the
only caller, so Y is affected") come from different evidence, and the second is the
half that gets overstated — the story wants one clean orphan. `rg` every caller of
the symbol, including callers inside its own file, and state the corrected scope:
one true mechanism with the wrong blast radius sends the user to fix the wrong
thing, which is worse than reporting nothing.
And say plainly when the answer is *"the structure is fine, the limit is
elsewhere"* — an invented structural flaw is worse than none, because it sends
someone refactoring instead of fixing the real thing.

## Phase 5 — Reconcile with the docs (now, and only now, open them)

The map in `$SCRATCH` is frozen. Read the repo's architecture docs for the first
time and diff them against it, **both directions**:

- code → doc: a real component or edge the docs never mention;
- doc → code: a `doc-only:` node or edge that no longer exists.

Because the map was derived blind, both lists are evidence rather than artefacts of
how the docs framed you — that's the payoff for the ordering. A doc-only component
is a claim nobody checks, which is how a diagram becomes a lie people plan against.
Report both; fix or delete stale nodes rather than leaving them.

**Then find where architecture is already documented — the repo has decided.** Look
for the stated convention (`CLAUDE.md` / `AGENTS.md` / a docs README) and the doc
already carrying this material (`ARCHITECTURE.md`, `DEVELOPMENT.md`, `docs/`,
`spec/`). Where a section covers this, the diagram belongs *inside* it, replacing the
prose it duplicates. A new `spec/architecture/` tree is the last resort, right only
when nothing documents architecture at all — a second home next to the real one is
the competing-source-of-truth problem this phase exists to end. **Never `git add` or
commit** — the user stages their own docs.

## Phase 6 — Report (a verdict, not a transcript)

The audit produces a mountain of material and the reader wants a **decision**. So the
report is conclusion-first and bounded; everything that merely *supports* the
conclusion stays in `$SCRATCH` and gets referenced by path, never pasted.

```text
## Verdict
<3 sentences, standalone: is the shape sound, the ONE thing to fix first, what it costs.>

## Fix now
## Decide
## Ignore for now
<every finding in exactly one bucket, worst first, as blocks:>

### <short title>   ·   <path:line>
what:     <the defect, one sentence>
costs:    <what it costs the goal — money, wrong numbers, change risk — one sentence>
evidence: <path:line, path:line · the grep/tool result that confirms it>
scope:    <what IS affected and what is NOT — both halves>
do:       <the action, one sentence — or "A vs B" when it's the user's call>

## Docs
<code-only / doc-only lists from Phase 5, plus where diagrams were written.>

## Details
<paths in $SCRATCH: drift lines, harvest TSV, tool output, per-unit maps.>

## Skill verdict
<Phase 7: what to change about this skill, with the run's evidence.>
```

What keeps it short and final:

- **Counts, not lists, for the long tail.** `31 DRIFT / 12 UNDOC — see $SCRATCH/drift.tsv`
  beats 43 lines nobody reads. A drift line only earns a block if it misleads
  someone about behaviour.
- **No process narration.** Which phase found it, which model ran, what you'd have
  fanned out — none of that changes what the user does next. Constraints that
  *weaken a conclusion* are the exception: those belong in `scope:`.
- **Both halves of `scope:` are mandatory.** "Affects the universe gate; grid runs are
  unaffected" is what makes a finding actionable instead of alarming.
- **Every block passes the Monday test**: a reader can act on it without asking a
  follow-up question. If it can't, it's evidence — move it to `$SCRATCH`.
- If it reads like intermediate output (raw `sym:` lines, tool dumps, per-file walls),
  it isn't the report.

Then append the `Fix now` and `Decide` items to `TODO.md` in the `todo-md` skill's
layout — the report is the read, `TODO.md` is the record. Don't stage it.

Fix nothing structural automatically: those are judgement calls and a wrong one is
expensive to unwind. Mechanical fixes (a stale docstring, a dead private helper) can
be offered as a follow-up batch once the user has read the verdict.

Phases 5 and 6 belong to the main thread. Harnesses commonly refuse a subagent
writing a file named `report`/`summary`/`findings`/`analysis*.md`, so a delegated
write-up can vanish while the agent reports success — and a fan-out agent has only
its own slice anyway, which is the wrong altitude for the whole-repo write-up.

## Phase 7 — Verdict on this skill (quality and tokens)

Close every run by auditing the audit. You have just seen this skill meet a real
repo, which is evidence no amount of editing from the armchair produces — and it is
gone the moment the session ends unless it lands in this file.

Two questions, answered from what actually happened, never from impressions:

**Did it find the truth?**

- Which findings died in verification, and why — overstated blast radius, a
  reachability tool believed too readily, a docstring taken as behaviour? Each cause
  maps to a specific instruction here that failed to prevent it.
- What did Phase 5 catch that the code pass should have? A doc that revealed a
  component the blind map missed means Phases 1-3 have a coverage hole, not that the
  docs were useful.
- Which findings did the user already know, or reject? Both mean the lens is aimed
  slightly wrong.

**What did it cost?**

- **Tokens per surviving finding** — the only ratio that matters. Compute it.
- Which phases produced zero findings that reached the report? A phase that never
  pays is a phase to narrow or cut.
- Where was the same file read twice (a Phase-1 batch and again later)? The design
  says read once; every re-read is a straight loss.
- Did the harvest actually displace reading, or did agents rebuild the symbol list
  anyway (check a brief's reply against the TSV it was handed)?
- Batches returning almost all `MATCH` = too broad a net; agents queueing behind the
  concurrency cap = fan-out wider than the machine, not wider coverage.

Output at the end of the report, as concrete diffs to this file:

```text
## Skill verdict
cost:   <N tokens · M agents · K surviving findings → tokens/finding>
keep:   <what earned its cost — name the finding it produced>
change: <SKILL.md section> — <the edit> — <the run evidence that demands it>
cut:    <what produced nothing, and what it cost to produce nothing>
```

Nothing to change is a legitimate verdict — say it in one line rather than inventing
an improvement; a plausible-sounding edit with no evidence behind it is how a skill
rots. Propose the edits, then apply them only if the user agrees: this file governs
future runs, so it is theirs to change, not yours.

Correctness/security → `full-review` or `/code-review`. Duplicate
implementations → `convergence-audit`. Comment wording in a diff →
`review-comments`. Bloat deletion → `ponytail-audit`. This skill owns the layer
none of those see: what a unit claims vs what it does, what is reachable, and
whether the shape serves the goal.
