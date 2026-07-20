---
name: microservice-architecture
description: >
  Architecture principles for building and evolving a fleet of cooperating
  backend services (ML workers, job processors, API services) around a
  message broker. Use whenever the user is designing a new service,
  splitting a monolith, adding a service to a docker-compose/k8s cluster,
  deciding how services should communicate or share code, wiring up a
  job/queue pipeline, choosing transport between co-located services, or
  building status/health/load reporting for a service fleet. Also use when
  the user complains about services that don't report progress, silent
  failures, duplicated code across services, or idle services wasting
  resources. Triggers on: "microservice", "service architecture", "split
  this service", "add a service", "how should these services talk",
  "shared library vs service", "queue/worker", "service status/health",
  "self-contained service".
---

# Microservice Architecture

Principles for a fleet of cooperating backend services behind a broker. Distilled from a real ML-pipeline landscape; written to generalize. Each principle leads with the *why* - apply judgement, don't cargo-cult.

## The two load-bearing rules

**Self-contained services.** A service owns everything it needs to run: its Dockerfile, its dependencies (pinned), its model/assets, its worker loop, and its slice of state. It talks to the rest of the world *only* through explicit contracts - a queue message, an HTTP endpoint, a broker key - never by importing another service's internals or reaching into another service's database. The test: you can delete every other service, hand this one its inputs, and it still runs and is testable in isolation. Self-containment is what lets you rebuild, redeploy, scale, and reason about one service without holding the whole fleet in your head.

**Shared library for strong overlap, not a shared service.** When 3+ services repeat the same *mechanism* - the queue/poll protocol, wire framing, DB access, status snapshotting - extract it into a shared component they are all **built on** (vendored/copied into each image at build time), not a runtime service they call. This keeps them self-contained (no new network dependency, no new failure mode) while killing duplication. Extract *after* the third copy, not before (YAGNI): two copies are cheaper to maintain than the wrong abstraction. When the shared piece changes, every service rebuilds - that's the cost, and it's acceptable because the alternative (drift between hand-maintained copies) is worse.

These two pull against each other on purpose. Self-containment resists coupling; the shared library resists duplication. The line between them is "is this the same *mechanism* (share it) or the same *idea implemented differently* (leave it)?"

## Uniform contract

Every service exposes the **same surface**: the same job protocol (e.g. `enqueue` → returns id; `poll(id)` → status+result) and the same `status` shape. Uniformity is leverage - the orchestrator, the status UI, and the retry logic treat every service identically, and a new service costs near-zero integration. Resist per-service special-case endpoints; when one service needs a bespoke call, ask whether the uniform contract can carry it instead (a payload field, a batch variant of the standard call).

## Broker-mediated pull, not a call graph

Producers fan work onto per-service queues; each service **pulls from its own queue** autonomously. There is no service-to-service call graph to reason about - the broker holds the queue, the in-flight/running set, and the passed-downstream results. This decouples producers from consumers (add replicas, restart a service, no producer changes), gives natural backpressure (bounded queues), and makes the whole system's load legible in one place (the broker). A stage's result is keyed by `(work-item-id, stage)` so downstream stages read predecessors without re-doing work.

Reserve synchronous service-to-service HTTP for the rare case where a stage genuinely needs another service's answer *inline* - and route it through the same tracked queue path so it still shows up as work (see Observability), rather than a raw call that's invisible to the fleet's status.

## Idempotency and at-least-once

Assume every job can be delivered more than once and retried. Make stage execution **idempotent**: re-firing a completed stage is a no-op; results are keyed so a re-run overwrites cleanly; a successor fires exactly once even under a race. This is what makes retries, restarts, and crash recovery safe instead of corrupting.

## Fail loud, fail durably

The worst failure mode is the **silent degrade**: a stage hits an error, returns an empty result, and the work-item finishes looking successful with missing data. Ban it. On failure:

- **Hard-fail the unit of work** - don't swallow-and-continue. A stalled/errored/timed-out consumer fails the item.
- **Persist the error durably**, not only in ephemeral broker state that expires (a TTL'd job hash is gone by the time the operator looks). Write the failure reason somewhere with the lifetime of the failed state itself, and carry it to where the operator sees the item.
- **Reprocess from a clean state** - a failed item re-enters as if fresh, no half-written partial.

Corollary: distinguish "genuinely no result" (0 detections is a valid answer) from "failed to produce a result" (an error). Encode which one it is; never let them look the same.

## Reconcile un-TTL'd claim markers

Any dedup/claim key - an `enqueued:*` / `locked:*` / `in-flight:*` flag - that has **no TTL** and is cleared only on success will strand work forever when a job is lost: the process dies between claiming and enqueueing, or a worker dies and crash-recovery misses it. The marker lingers, the item shows "in progress" forever, and nothing re-fires it.

Add a **reconciler**: each service periodically re-checks the work *it owns* and resolves stranded markers.

- **Liveness, not timeout.** A marker is stranded iff its result is absent AND no live job will deliver it (not in any queue, not running on a live instance). Correct at any job duration - a legitimately slow job is never falsely reaped, unlike a time-based guess.
- **Grace against races.** A just-created job can momentarily look marker-set-but-not-yet-enqueued. Require the stranded condition to hold across two consecutive passes before acting.
- **Surface as failed**, don't silently retry - the operator sees it and it re-enters cleanly.
- **Deploy fleet-wide.** A reconciler in a shared library only runs in instances actually rebuilt with it; the fix isn't live until the whole fleet is redeployed.

## Backpressure and liveness

Bounded queues + a **liveness deadline** measured as *no progress*, not *slowness*. A slow-but-progressing consumer on a slow machine must never be killed; a genuinely stuck one must be. Reset the timer on any unit of progress; trip only when a consumer makes zero progress against a full buffer for a long, generous interval. Pace each consumer independently so one slow consumer stalls only itself, not the whole pipeline.

For a multi-stage or multi-consumer pass, attribute wall-clock with **per-phase accumulators** so "unaccounted" time gets a name; measure backpressure concretely as **time blocked pushing to a bounded queue**, which pins the bottleneck to the specific downstream consumer that can't keep up.

## Release shared resources on every exit path

A producer that streams to co-located consumers (open sockets, tracked jobs, claimed slots) must release **every** consumer connection on **all** exit paths - success, handled error, and unexpected exception (`try/finally`). Skip it and a crash leaves consumers holding phantom work (a stuck "busy"/running marker) until something else notices. Because a hard kill (SIGKILL/OOM) skips the `finally` too, the **consumer** also needs an idle/liveness timeout to self-release a connection gone silent. Belt (producer `finally`) + suspenders (consumer timeout) - neither alone covers every death.

## Co-location and transport

Let the *deployment topology* pick the transport. If the deployment co-locates a producer and its consumers on the same node (e.g. a daemonset running one full stack per node, one work-item per node at a time), then a network codec (JSON/protobuf over TCP, JPEG-encoding frames) is pure overhead - use a **local transport**: in-process for same-process consumers, a Unix-domain socket or shared memory for same-host separate processes. Don't build cross-node machinery for data that never crosses a node (YAGNI). **Name the invariant** ("consumers are always co-located") in the design so the choice is justified and the reader knows what would have to change to break it.

Match the transport to the data rate, not the fear: at a few frames/second a raw-bytes copy over a local socket is free, and shared memory's slot-pool + cross-process refcount + cleanup complexity buys nothing. Reach for zero-copy only when throughput actually demands it.

## Lazy resources, cheap idle

Expensive resources (models, big caches, connections) load **lazily as singletons** - on first real use, cached thereafter. Do not eagerly warm them at boot on every node: in a fleet where every node runs every service, eager warmup means every model is resident in RAM everywhere forever, even on services that a given node never exercises. An idle service should cost ~nothing. Keep eager warmup only where first-request latency is genuinely critical, and gate it behind a flag so it's a deliberate per-deployment choice, not a default tax. (The loaders are lazy singletons already; "warmup" is just pre-triggering them - so *not* warming is usually a deletion, not new code.)

## Observability: pull is fragile, prefer central state

Status/load reporting is where fleets quietly rot. The naive design - the UI HTTP-polls each service's `/status`, and each service reports its own busyness - has three structural flaws, all of which this landscape hit:

1. **A busy single-threaded service can't answer its own `/status`.** Under a CPU-bound (GIL-holding) burst it misses the poll timeout and shows *unreachable* exactly when it's working hardest.
2. **Sequential probing with per-service timeouts** makes the whole refresh slow and stale; one hung service delays all.
3. **Instantaneous "is the running-set non-empty" misses sub-poll bursts** - a job that starts and finishes between two 2s polls is invisible even though CPU spiked.

Remedies, in order of value:

- **Read fleet state centrally from the broker, not by probing each service.** Queue depth, running set, and activity all already live in the always-responsive broker - read them there in one shot. This eliminates the can't-report-while-busy failure entirely. Use the per-service HTTP call only for what only the service knows (cpu%, memory, version), and degrade gracefully when it times out.
- **"Did something since the last refresh."** Keep a monotonic activity counter per service in the broker (incremented on each job start) and highlight if it changed since the previous poll. This catches sub-poll bursts that an instantaneous running-count misses - and, unlike a fixed TTL "active for N seconds" window, it's keyed to the actual refresh interval instead of a guessed constant. Prefer this counter-diff over a magic-number window.
- **Show load, not just a binary.** CPU% as an interval average (it captures bursts a point sample drops) is a cheap, honest load signal alongside the did-something flag.
- **Probe concurrently** if you must probe at all; bound the cycle by the slowest, not the sum.
- Prefer **push/heartbeat** (`last_active_at`) over pull where you can - "active 3s ago" is more honest than a binary sampled at the wrong instant.

The through-line: **the broker is always up and cheap to query; the busy worker is not.** Derive fleet status from the former.

## State ownership

Each piece of state has exactly one owner; everything else derives or reads through a contract. Don't let two services write the same table or two components cache the same fact - they drift. When you need a fact in two places, pick the owner and have the other read it (or read the broker's shared result), rather than duplicating the write path.

## Spec discipline

Design docs name **contracts** (what must be true) not **mechanisms** (how you happened to build it): "results keyed by (item, stage)", not "Redis key `result:{sha}:{stage}`". A good spec lets someone rebuild the featureset on a different stack; the mechanism lives in code. This keeps the architecture legible as implementations churn. (If a `writing-specs` skill is available, use it for the spec itself.)

## Operational hygiene

- **Rebuild every image that bakes changed shared code - silently running stale is the trap.** A shared library copied into N images (see the two load-bearing rules) means one edit must rebuild all N. Build tooling often *doesn't*: `docker compose up` builds an image only if it's **missing**, never on source change, so an edited shared module keeps running its old version in every already-built image with **no error**. The tell: "I changed the shared code / fixed the bug and nothing happened at runtime" → the image wasn't rebuilt. Make your up/deploy step rebuild-on-change (`compose build` before `up`, a content hash, or per-image stamps), and treat "a shared-lib change had no effect" as an un-rebuilt image until proven otherwise.
- **Keep each service's Dockerfile COPY list in sync with its imports.** A new local/shared module that's imported but never added to the `COPY` lines crashes the service on startup (`ModuleNotFoundError`) - and stays **latent** until something triggers a rebuild, which (per the point above) may be long after the code merged. When you add a module, add its COPY; when a rebuilt image won't boot, check the COPY list before anything else.
- **Pin dependencies.** A floating version is a latent "works on my node" failure and defeats reproducible rebuilds.
- **Prefer plain/linear build progress in tooling.** Fancy in-place TUI progress renderers mangle into pages of duplicated garbage under some container providers/terminals; a `--progress plain`-style flag gives readable, log-friendly output.
- **One k8s resource per file**, named `<kind>-<name>.yaml`; wire each into the kustomization. Never bundle resources with `---`.
- **Run language runtimes with system deps in containers**, not on the host.
- **Isolate failure domains at the Kustomization/deploy boundary** so one broken service doesn't block unrelated deploys.
