---
name: flux-kustomization-boundaries
description: Use when designing or refactoring FluxCD Kustomization structure, or debugging why one broken app/component blocks unrelated deploys - symptoms like "a Kustomization won't go Ready", "monitoring is broken so I can't update the gateway / anything else", "image automation isn't converging", "lastAppliedRevision is frozen / stale", one app's failed health check stalling others, or deciding between one big apps/infrastructure Kustomization vs per-app/per-component ones.
---

# Flux Kustomization Boundaries

A Flux `Kustomization` is the unit of **reconcile loop, health gate, prune scope, and fate-sharing**. `spec.wait: true` + `healthChecks` are evaluated per-Kustomization, so **everything in one Kustomization shares fate**: a single unhealthy resource keeps the whole Kustomization from going `Ready`, which **freezes `lastAppliedRevision`** and stalls convergence (including image-automation bumps) for every other resource in it.

## The rule

Draw Kustomization boundaries around **failure domains**, not by convenience. Group resources that *should* succeed/fail together; separate resources that *shouldn't* share fate. The axis is lifecycle/health/ownership - not "one big bucket" and not dogmatically "one per resource."

- **Independent apps/components → their own Kustomization** (each points at its own dir). One breaking can't wedge the others.
- **Don't over-split** tightly-coupled pieces you deploy and fail as a unit - grouping them is correct.

## Symptom → cause

| Symptom | Cause |
| --- | --- |
| "monitoring broke, now I can't update the gateway" | both in one Kustomization → shared health gate |
| image bump committed but not live; `lastAppliedRevision` stale | Kustomization never `Ready` (some resource unhealthy) → won't advance |
| deleting one app's manifests risks others | one `prune` scope for the whole bucket |

## Recommended shape

```text
Kustomization: infra-base   (namespaces, CRDs, cluster-scoped: PriorityClass, RBAC)
    ▲ dependsOn
per-controller Kustomizations   (cert-manager, longhorn, gateways, ...)
    ▲ dependsOn (only the SPECIFIC one needed)
per-app Kustomizations          (each app its own; healthChecks scoped to that app)
```

- A shared **base** Kustomization for cluster-scoped prerequisites (CRDs, namespaces, PriorityClasses). Apps `dependsOn` it → prerequisites exist and are healthy before dependents apply (also fixes ordering races).
- Each app/component: its own Kustomization, `path` at its own dir (which has its own `kustomization.yaml`), `wait: true`, `prune: true`, and `healthChecks` scoped to *its* critical resources.

## Critical gotcha: `dependsOn` transmits the wedge

`dependsOn` waits for the dependency to be **Ready**. If app X `dependsOn` a *monolithic* `infrastructure-resources` that also contains a broken `monitoring`, then `infrastructure-resources` never goes Ready → **X never applies**. Splitting apps is pointless unless you also split what they depend on and depend only on the **specific** component needed (e.g. `dependsOn: gateways`, not `dependsOn: infrastructure-resources`).

## Cheaper partial mitigations (when you can't split yet)

- Scope `spec.healthChecks` to only the resources that must be healthy → an unrelated failure no longer blocks `Ready`.
- Set `spec.wait: false` on the shared Kustomization → apply succeeds without gating on health (you lose readiness gating / ordering guarantees).

## Common mistakes

- One `apps` + one `infrastructure` Kustomization for everything → every failure is cluster-wide blast radius.
- Per-app Kustomizations that still `dependsOn` a monolith → wedge returns transitively.
- Cluster-scoped shared resources (CRDs, PriorityClass) with no home → ordering races; put them in the base.
- Forgetting per-Kustomization `decryption` (SOPS) / `sourceRef` when splitting - each new Kustomization needs its own copy.
- `prune: true` with a too-broad `path` → deleting one thing risks pruning neighbors.
