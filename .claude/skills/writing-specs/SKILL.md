---
name: writing-specs
description: >
  Write, audit, or refactor a design spec so it captures **contracts** (what must be true) not **mechanisms** (how we happened to build it). Use whenever the user is drafting a new design doc, complains their spec "reads too specific" or "reads like a code walkthrough", asks for a spec sufficient to rebuild the featureset in a different stack, refactors an implementation note into a proper spec, or audits an existing spec for register-drift. Also use when someone asks "what belongs in the spec vs the code?" or "at what level of detail should I write this?". Triggers: "write a spec", "spec too specific", "spec register", "sufficient to rebuild", "contract vs mechanism", "audit this spec", "spec drift", "rebuild-spec", plus adding a `docs/**/specs/*.md` or `docs/**/design/*.md` file.
---

# Writing Specs

A spec that "reads too specific" is one that named the mechanism when it should have named the contract. This skill gives you the three registers a design doc can sit in, the dividing-line question that separates them, and a section template that keeps you honest.

## Three registers

Every sentence in a design doc sits in one of three registers. Mixing them is the most common failure mode.

### 1. Product overview

**Question:** what does the user / operator experience?

Reads like a product page. Names features + user-visible flows. Nothing about internals.

Sufficient to rebuild? **No** — tells you what to demo, not what to build.

Use for: onboarding docs, sales collateral, feature announcements, the top-of-spec `Featureset` bullet list.

### 2. Rebuild spec — the target register for most design docs

**Question:** what needs to exist + which contracts must hold, so a competent engineer can rebuild the same featureset in a different stack?

Names **behaviours, contracts, guarantees, data shapes** — not mechanisms.

Sufficient to rebuild? **Yes** — contracts are precise, mechanism is deliberately open.

Use for: the body of a design doc, ADRs, cross-team contracts, "what does this subsystem promise?" documentation.

### 3. Implementation notes

**Question:** how did we build it, exactly? Which Redis keys, which env var names, which Lua scripts, which TTLs?

Reads like a code walkthrough.

Sufficient to rebuild? **Yes, but only in the same stack.** A reimplementer on NATS + Postgres + k8s-cron has to reverse-engineer intent from mechanism.

Use for: the "Post-implementation notes" section clearly labelled as *how we did it, not what's required*. Runbooks. Debugging notes. Never as the primary spec.

## Contrast on one subsystem

To calibrate: same recipe / stage system, three ways.

**Register 1 (product overview):**

> Operator drops a file into the scan mount. It appears in the inventory as `new`. Operator clicks Analyse. Progress shows live on the status page. When done, results show on `/images` / `/videos`. Failed files reappear as `failed` and can be re-analysed.

**Register 2 (rebuild spec):**

> **DAG execution.** Each source runs a static per-kind stage DAG. Predecessor set satisfied → stage becomes eligible. Re-firing a completed stage is a no-op. Failed stage writes a failure sentinel that surfaces to the operator; retry clears failure state + re-fires from scratch.
>
> **Concurrency guarantees.** At most one worker per `(sha, stage)`. Same successor-stage race → exactly one enqueue wins. Worker death (crash, restart) → a peer recovers the job. Workers must not requeue their own in-flight jobs.
>
> **GPU serialisation.** On a shared-GPU node, at most one ML inference across all ML services at a time. Implementation open (host mutex, distributed lock, k8s device-plugin) — the guarantee is what matters.

**Register 3 (implementation notes):**

> `SET enqueued:{sha}:{stage} 1 NX` guards the enqueue race. `SADD stage_done:{sha} {stage}` records completion. `SET lock:gpu:{node_id} 1 NX EX 600` is the GPU lock; Lua compare-and-delete releases so a TTL-expired holder doesn't `DEL` a peer's lock. `_recover_orphans(include_own=True)` at startup, peer-only in the heartbeat loop.

Same information density in all three. Different register. Only the middle one is a spec.

## The dividing line

For each sentence, ask: **could a reasonable engineer swap the mechanism without breaking the featureset?**

- **Yes** → mechanism. Belongs in code / comments / Register-3 notes. Not in the spec.
- **No** → contract. Spec keeps it.

Concrete pairs:

| Sentence | Register | Why |
| --- | --- | --- |
| "Uses Redis as the broker" | 3 | Could swap NATS + Postgres |
| "Broker is a shared queue + KV store, one writer per key" | 2 | Shape survives the swap |
| "Stage results >100 KB spill to `/db/stage_results/<sha>/<stage>.json`" | Half + half | Threshold + spill behaviour = contract; the path = mechanism |
| "Stage results above the broker's inline-value budget spill to shared object storage" | 2 | Rewrote the same thing without leaking the path |
| "GPU lock uses `SET NX EX 600` + Lua release" | 3 | Mechanism |
| "GPU lock: mutual exclusion across ML services on one node, TTL-based liberation if the holder crashes" | 2 | Contract |
| "Frontend is a FastAPI app using Jinja templates" | 3 | Framework choice; could rebuild on Rails + ERB |
| "Frontend renders server-side; page is usable without JS (JS only for live polling)" | 2 | The contract the operator relies on |
| "Fan-out is 4 concurrent worker calls" | 3 unless the 4 is load-bearing | Ask: does the whole system fall over at 8? If yes, it's a contract |

The `Half + half` row is the most common trap. Extract the contract, drop the mechanism.

## Anti-patterns to catch in your own draft

- **Env var names in the spec.** `ENROLLER_URL=http://...` is implementation. Spec says "the enroller has a reachable HTTP endpoint".
- **File paths in the spec.** `services/frontend/mgmt_ui/scan.py` is a code map, not a spec. Spec says "the frontend owns the scan-triggering UI".
- **Redis / SQL key names.** `stage_result:<sha>:<stage>` names a mechanism. Spec says "stage results are keyed by `(sha, stage)`".
- **Language / framework names in normative sentences.** Fine in a `Technology choices` addendum, wrong in the "what this subsystem does" section.
- **Version pins.** `redis:7-alpine` is deploy-config. Spec says "requires a broker with the CAS + TTL + list primitives listed below".
- **Loop counts, poll intervals, TTLs — unless the number is load-bearing.** "Retries 3 times" is only a contract if the operator sees a difference between 3 and 30. "Polls every 2 s" is only a contract if the UX depends on 2 s specifically vs "under 5 s".
- **Function names / class names.** Belong in code. Spec names components + their boundaries, not their symbols.

## Section template

Structure a subsystem spec in this order. Each section has a defined register.

```markdown
## Purpose  [Register 1-2, one paragraph]

Why this subsystem exists. What problem it solves. Which class of user
depends on it.

## Featureset  [Register 1, bulleted]

Operator-visible behaviours. What can the user do, what do they see?
Minimal — this is the demo script, not the design.

## Contracts  [Register 2, the meat]

What must be true. Guarantees the subsystem upholds.
- Concurrency / consistency guarantees
- Failure modes + recovery expectations
- Idempotency, at-most-once, at-least-once semantics
- Ordering, back-pressure, cancellation

## Data shapes  [Register 2]

Schemas that survive a re-implementation.
- Persisted entities: fields + types + relationships
- Wire payloads: request / response shapes
- Broker key structure at the abstraction level, not literal strings

## Boundaries  [Register 2]

Which components exist. What each is responsible for. What HTTP / queue
/ event surfaces they expose. Who owns which contract.

## Non-goals  [Register 2]

Explicit anti-features. What this subsystem deliberately does not do,
so the reimplementer doesn't overshoot.

## Open questions  [Register 2]

Decisions still pending. Trade-off summaries. Never leave a decision
implicit in prose — surface it here.

## Post-implementation notes  [Register 3, clearly labelled]

Optional. How the current build satisfies the contracts above. Redis
key names, env var names, framework choices, TTLs, retry counts,
directory layout. Reads as "here's how we did it, not what's
required." Anyone rebuilding reads §1–6; anyone maintaining reads §7.
```

Section 7 is where implementation debris legitimately lives without polluting the front-of-house spec. If your existing spec has drifted, moving the Register-3 material into a section 7 (or a sibling `implementation-notes.md`) is often 80% of the fix.

## Reviewing an existing spec — the sweep

Walk each section top to bottom. For each paragraph:

1. **Register-check.** Mark each sentence 1 / 2 / 3.
2. **Anti-pattern scan.** Env vars? File paths? Redis keys? Framework names?
3. **Mechanism-swap question.** For each Register-2 sentence: is there a reasonable swap that breaks it? If not, it's Register 3 in disguise — rewrite.
4. **Contract completeness.** For each Register-1 feature, is there a Register-2 contract that guarantees it? Missing guarantees are gaps.
5. **Reimplementer test.** Read the spec top-down as if you were rebuilding on a different stack. Where do you have to guess? Fill those gaps.

Output per finding: `<section>:<line> — <register-drift> — <fix>`. Batch into a targeted set of edits, don't rewrite paragraph-by-paragraph.

## Cheap tests

Before shipping a spec, run these:

- **The framework-swap test.** Skim the doc pretending Redis / FastAPI / SQLite are prohibited. Do the requirements still make sense? If half the doc references "the Redis queue", it's Register 3.
- **The two-year test.** Read the spec pretending it's two years old and the current implementation is gone. Can you rebuild the featureset from it alone? Missing → gap.
- **The onboarding test.** Give the spec to someone joining the team. Are they confused by mechanism they haven't seen yet, or by the featureset? Confusion by mechanism = you leaked implementation into the spec.

## When Register 3 is actually the right choice

Sometimes you *want* an implementation note, not a spec:

- Runbooks. "Restart procedure: `docker compose down && rm -rf db && docker compose up -d`". Mechanism is the point.
- Debugging notes. "If queue depth stalls, check `running:*` for orphan entries." Mechanism is the point.
- Post-mortems. Naming the exact keys / TTLs / retries that failed is the point.
- Migration plans. "Rename `service-yolo` → `service-object-detection` across compose, k8s, env vars, dashboards" — mechanism is the deliverable.

These are legitimate documents; they're just not specs. File them somewhere separate — `runbooks/`, `incidents/`, `migrations/` — so nobody reads them expecting to rebuild the system.

## Format for suggestions

When asked to write / audit / refactor a spec, respond in this shape:

1. Which register the current doc mostly sits in (or which mix).
2. Two or three specific sentences that leaked mechanism into a contract slot, with the fix.
3. Any missing contracts you noticed while reading.
4. Recommendation: rewrite in place, or split into `spec.md` + `implementation-notes.md`.

End with a recommendation, not a shrug.
