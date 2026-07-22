---
name: convergence-audit
description: >
  Whole-repo structural convergence audit. Finds things that solve the SAME
  problem in DIFFERENT ways and proposes one unified form - broad-scope DRY at
  the level of modules, functions, and types, not lines. Also spots
  near-miss abstractions ("extend X + delete A") and restructurings ("do X this
  way + add Z, then A and B become one"). Use when the user says "convergence
  audit", "find duplicate implementations", "what should be unified/consolidated",
  "these two feel similar but are written differently", "why do we have three
  ways to do X", "de-dup at scale", or "/convergence-audit". Distinct from
  ponytail-audit (which DELETES bloat) and /code-review (line-level DRY in a
  diff). One-shot report, applies nothing.
---

Whole-repo. Find where the codebase solves one problem in N different shapes,
propose the single shape. This is **consolidation**, not deletion: the code
isn't dead, it's redundant-in-disguise.

## The lens

Cluster the repo by **responsibility** (the question a unit answers), not by
filename. Then look across each cluster for divergence. Four shapes:

- `parallel:` two+ units with the same responsibility, different mechanism (two
  retry loops, two config loaders, two cache layers). Unify on one.
- `near-miss:` a helper already *almost* covers a new case. Small change (add a
  param, widen a type) lets the new code reuse it. "Extend X, delete A."
- `converge-if:` A and B look separate but a restructuring collapses them - "do
  X this way + add Z, then A and B are one thing." The user's core ask.
- `concept-split:` one domain concept in N representations (dict here, dataclass
  there, raw tuple elsewhere). One type.

## The guardrail (this is the whole skill)

A naive pattern-matcher fights DRY-after-3, KISS, YAGNI, SRP and drives
premature abstraction - the abstraction nobody can undo at 3am. Be
**conservative**. A finding ships ONLY if it passes every gate:

- **Rule of three** - ≥3 real instances cited (file:line). Two similar things
  are a coincidence, not a pattern. Drop 2-instance findings.
- **Net complexity** - the unified form must remove more concepts/lines than the
  indirection it adds. If merging just hides duplication behind a new layer,
  drop it. State the delta.
- **SRP / reasons-to-change** - unify only if the instances change for the *same*
  reason. Same code today + different reasons tomorrow = leave split. Forced
  unification here is the worst outcome the skill can produce.

Name the gate that killed a rejected candidate - a near-miss the user should
know you *considered and rejected* is signal, not noise.

## Output

Ranked, biggest consolidation first. One block per finding:

```text
<shape> <concept> · <N> sites: path:line, path:line, path:line
  divergence: <how they differ today>
  unify:      <the one form>
  net:        -<X> concepts / -<Y> lines · couples: <what, or "nothing new">
```

End with `net: -<N> lines, -<M> concepts, <K> types collapsed possible.`
Nothing worth merging: `Coherent already. No convergence wins.`

## Boundaries

Structure only. Correctness, security, performance → normal review. Applies
nothing - report only, like ponytail-audit. Cost: whole-repo scan, so it's
opt-in, not per-diff. For deletion use ponytail-audit; for line-DRY in a diff
use /code-review.
