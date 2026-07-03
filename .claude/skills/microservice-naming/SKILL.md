---
name: microservice-naming
description: >
  Name new microservices, rename existing ones, and audit an existing service catalog for naming smells. Use whenever the user is adding a service to a docker-compose/k8s cluster, splitting a monolith, choosing between candidate names ("should this be X or Y"), reviewing a service list for consistency, or complaining about naming sprawl. Triggers: "name this service", "microservice naming", "service naming convention", "rename service X", "what should we call the X service", "audit our service names", "new service for X", plus adding entries to `docker-compose.yml`, `services/*/`, k8s manifests, or a service registry.
---

# Microservice Naming

Service names show up in more places than people expect - DNS, k8s manifests, Redis queue keys, log filters, Grafana dashboards, PagerDuty rotas, muscle memory of everyone who's ever been on-call for it. Treat naming as a one-shot decision. Renaming post-hoc costs a migration.

## Format

- **kebab-case, lowercase.** Works in DNS labels, k8s resource names, docker-compose service keys, `grep`-friendly logs. `snake_case` breaks DNS. `camelCase` breaks case-insensitive tooling. Mixed case is where "which service is this?" confusion starts.
- **One canonical string per service.** Same identifier in DNS, k8s Service, docker-compose key, Redis queue key (`queue:<name>`), log prefix, dashboard title, on-call rota. Every divergence (`svc-orders` here, `order_svc` there, `OrdersService` in code) is technical debt.
- **Role suffixes for multi-deployable domains.** `orders-api`, `orders-worker`, `orders-scheduler`, `orders-consumer`. Bare `orders` for a single-shape service. Only allowed suffixes: `-api | -worker | -scheduler | -consumer | -cron | -gateway`. If it doesn't map to one of those, drop it.
- **Prefix policy: pick one, enforce it.** Either always `svc-<name>` or never. Do NOT mix `service-orders`, `orders`, and `orders-api` in the same repo. Default recommendation: **no prefix** on the service identifier itself; use role suffix for disambiguation. (`service-orders` in docker-compose is fine as the compose key convention; the identifier the code passes around is `orders`.)

## Semantic

- **Name the domain, not the technology.** `orders`, not `postgres-orders` or `kafka-orders`. Stack-free names survive stack swaps.
- **Name the domain, not the model.** ML services identify by capability (`face`, `body-fingerprint`), never by model file (`osnet-body`, `yolov8-detector`). Model swap ≠ service rename. Keep model term inside the code (`reid.py`, `REID_NCNN_DIR`); expose only the capability.
- **Name the business capability, not the codename.** `loan-approval` beats `project-phoenix`. Memorable codenames (S3, Zuul, Hystrix) work for **public products** with docs, marketing, and a moat behind them. Inside a private cluster with 200 services they cost more than they save - Uber's own postmortem documents the 3000-4000-service naming crisis where nobody could map codenames back to purpose.
- **Bounded context per DDD.** One service = one team-owned capability. If two teams ship independent features through the same service, the name is masking a needed split.
- **Business language, not implementation language.** Words the product/domain expert uses. Not `data-aggregator`, not `orchestrator-service`, not `core`.

## Anti-patterns

- **Version in the identifier.** `payments-v2`, `new-search`. Version the API (`/v2/`), never the service. Renaming across dashboards + alerts + on-call books is why v2 sticks as a permanent scar.
- **Status in the identifier.** `legacy-`, `new-`, `temp-`, `old-`. Time invalidates every one.
- **Team name in the identifier.** `finance-team-refunds`. Teams reorg; services don't.
- **Filler suffixes.** `-service`, `-manager`, `-handler`, `-processor`, `-system`. Zero information. Drop them unless the suffix is a real role from the allowed list above.
- **Cryptic acronyms without a glossary.** `pas`, `ums`, `ccx`. If it needs a wiki lookup, it's misnamed.
- **Env / region in the identifier.** `orders-prod-eu`. Env and region belong in the DNS FQDN (`orders.prod.eu.example.com`), the namespace, or a label. Not in the identifier.
- **Ephemeral data leaking into names.** Instance IDs, container hashes, pod ordinals in anything customer-facing become de-facto contracts.
- **Generic dispatcher/orchestrator names.** `orchestrator`, `dispatcher`, `coordinator`, `manager`, `router` on their own name nothing. If a service really is a coordinator, name what it coordinates: `checkout-workflow`, `order-router`. Bare `orchestrator` invites feature-creep because "well, it orchestrates things".

## Bad → Good

| Bad | Good | Why |
| --- | --- | --- |
| `postgres-adapter` | `orders` | Domain, not storage tech |
| `yolov8-detector` | `object-detection` | Capability, not model |
| `BillingServiceV2` | `billing` + `/v2/` API | Version the API, not the service |
| `NewSearchEngine` | `search` | Status word will lie in six months |
| `data-aggregator` | `order-analytics` | What business function specifically |
| `svc-manager-orders` | `orders-api` | Filler out; role in |
| `finance-team-refunds` | `refunds` | Team reorgs; service doesn't |
| `orders-prod-us-east` | `orders` | Env/region in DNS, not identifier |
| `orchestrator` | `checkout-workflow` | Name what it coordinates |
| `body-reid` | `body-fingerprint` | Model term inside; capability outside |

## Renaming cost (why to get it right the first time)

Every one of these carries the old name and needs migration:

- k8s Service + Deployment + Ingress
- DNS record + TLS certificate SAN
- Redis queue keys (`queue:<svc>`), pub/sub topics
- Log aggregation index, Grafana dashboard variable
- PagerDuty service + on-call rota
- Metric labels (`service="orders"`) - beware cardinality when dual-emitting
- Runbooks, ADRs, arch diagrams, docs
- Muscle memory of every on-call engineer

**When you must rename:** DNS alias for one release cycle, dual-emit metrics + logs, stage queue-key migration behind a flag, update dashboards + runbooks in the same PR that flips traffic. Don't `sed -i` and hope.

## Decision heuristic

For each candidate name, ask in order:

1. **Domain check.** Does the name describe the business capability, or the technology / model / storage? Reject stack-leaking names.
2. **Bounded context check.** Does exactly one team own this capability? If two teams would ship features here, split first, then name.
3. **Longevity check.** Will this name still be true in three years? Reject anything with `v1/v2`, `new/legacy`, team names, or current-implementation flavour.
4. **Role check.** Is this one deployable or multiple? If multiple (api + worker + scheduler), pick from the allowed role suffixes.
5. **Grep check.** Type the name into your log tool. Does it uniquely identify this service, or does it collide with a common noun (`worker`, `service`, `handler`)?
6. **DNS check.** Lowercase, kebab-case, <= 63 chars per label, valid DNS label characters.

If a candidate fails 1-4, throw it out. If it fails 5-6, edit the format.

## Auditing an existing catalog

Given a list of service names, flag any that hit an anti-pattern above. Common findings in real catalogs:

- Filler suffix noise (`-service`, `-manager`) - drop them.
- Model/tech names (`postgres-x`, `yolo-x`) - rename to capability.
- Version scars (`x-v2` next to `x`) - decide which is canonical, sunset the other.
- Codename sprawl (mix of `zeus`, `hydra`, `phoenix` with `orders`, `billing`) - pick one register and stick to it.
- Bare `orchestrator` / `dispatcher` / `core` - always suspicious; ask what it actually does.

Report per finding: `<name> → <suggested rename>: <one-line reason>`. Don't propose the rename PR - identify + let the user decide which are worth the migration.

## When sources disagree

- **Prefix (`svc-`, `service-`).** Some orgs use it uniformly, some skip it. Both work if enforced. Default: skip in the identifier; role suffix carries the disambiguation.
- **Codenames vs descriptive.** Fine for public products with docs; bad for internal services past ~50 count. Watermark: if a new hire needs a glossary to route a page, you've outgrown codenames.
- **Version in identifier.** Some tutorials still recommend it. Industry post-mortems (Uber, most SaaS at scale) all say don't. Version the API contract instead.
- **Per-domain prefix (`Cart-CheckoutService`).** Only useful if your service registry actually groups by domain. Otherwise it's another filler word.

## Format for suggestions

When asked to name a new service, respond with **2-3 ranked candidates**, not a list of 10. For each: one-line reason it fits, one-line trade-off. Example:

> 1. **`payments`** (best) — bare domain name; role suffix not needed since only one deployable exists. Trade-off: if a background worker is added later, requires rename to `payments-api` + new `payments-worker`.
> 2. **`payments-api`** — explicit role suffix leaves room for future workers without rename. Trade-off: slight verbosity when only one deployable exists today.
> 3. **`billing`** — worth considering if the domain is actually broader (invoicing, refunds, subscription lifecycle) rather than just payment execution. Trade-off: broader scope = more team coordination.

End with a recommendation, not a shrug.
