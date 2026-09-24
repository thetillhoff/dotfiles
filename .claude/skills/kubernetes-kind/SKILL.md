---
name: kubernetes-kind
description: Apply for any task involving kubectl, kind, k8s manifests, or local/remote cluster operations. Enforces --context on every kubectl call, documents kind cluster conventions, points to this machine's named clusters in references/my-clusters.md, and defines what make up / make down must provide.
---

# Kubernetes & kind

## Hard rules

**Always pass `--context` on every kubectl call. Never call `kubectl config use-context`.**

Multiple clusters run in parallel terminals. The default context is unreliable. `use-context` breaks other sessions.

**Pass `--context` AFTER the verb, `=` form** (`kubectl get pods -n x --context=my-ctx`). A plugin shim rejects a leading `--context`. Same for `flux`.

> **This machine's named clusters** (remote clusters, kubeconfig paths, Flux/GitOps rules) live in `references/my-clusters.md`. Read it when a task targets a specific named cluster.

**Deleting resources: always by an explicit, reviewed name list — never a selector you haven't verified matches only the intended set, and never trust a pipe (`| head -N`) to bound how many objects get deleted.** `kubectl delete` resolves its match server-side and deletes every match before your local pipe reader even runs; `-l ''` matches everything, and a `--field-selector` on a field that's always true (e.g. `metadata.name!=<value-nothing-is-named>`) is the same as no selector at all. This deleted a live production config once. The safe pattern, every time:

```bash
kubectl get <kind> -n <ns> --context=<ctx> -o name | grep '<narrow-pattern>'   # 1. list, read it
# 2. only once the printed list is confirmed to be exactly the intended set:
kubectl get <kind> -n <ns> --context=<ctx> -o name | grep '<narrow-pattern>' | xargs -r kubectl delete -n <ns> --context=<ctx>
```

Never combine "list" and "delete" into one untested command on a real cluster. If a name list is short, just name them literally (`kubectl delete <kind> a b c -n <ns> --context=<ctx>`).

---

## Context selection

**Use `$KUBECONTEXT` — never hardcode the context name.** Set it once for the session or in `.envrc`:

```bash
export KUBECONTEXT=kind-myapp   # shell session
# or: KUBECONTEXT=kind-myapp in .envrc (direnv)
```

Then every command is portable across projects:

```bash
kubectl get pods -n myapp --context $KUBECONTEXT
kubectl apply -k overlays/kind/ --context $KUBECONTEXT
kubectl rollout restart deployment/web -n myapp --context $KUBECONTEXT
```

---

## kind conventions

- Cluster name → context: `kind-<name>`, node: `<name>-control-plane`
- Host port mappings live in `kind/kind-config.yaml` (`extraPortMappings`). They cannot change on a running cluster — requires `make down && make up`.
- `kind load docker-image <tag> --name <cluster>` loads from local Docker; the tag is just a label, no network pull occurs. Images are lost when the cluster is deleted.
- All Deployments in the kind overlay need `imagePullPolicy: IfNotPresent`. Use `op: replace` in the JSON patch — `op: remove` on a missing path is a hard error.

## Namespace: set it in kustomization.yaml only

If a `kustomization.yaml` sets `namespace:`, omit `metadata.namespace` from every manifest it
includes. Kustomize injects the value. One source of truth, so a global rename of the namespace
touches one line and cannot clash with a stale value in a child file.

## `make up` / `make down`

`make up` must (in order):

1. `kind create cluster --name <name> --config kind/kind-config.yaml || true`
2. Build all cluster images
3. `kind load docker-image … --name <name>` for each
4. `kubectl apply -k overlays/kind/ --context $KUBECONTEXT`
5. Create required secrets

## Watching a Job to completion

When polling a Job's status, **match `SuccessCriteriaMet`, not just `Complete`.** Modern k8s (1.31+)
sets the `SuccessCriteriaMet` condition first; a loop that breaks only on `Complete`/`Failed` never
matches and spins until its own timeout while the Job has actually finished. Prefer `kubectl wait`:

```bash
kubectl wait --for=condition=complete job/<name> -n <ns> --context=<ctx> --timeout=180s \
  || kubectl wait --for=condition=failed job/<name> -n <ns> --context=<ctx> --timeout=5s
```

`kubectl wait --for=condition=complete` handles the condition aliasing; a hand-rolled poll must check
both condition types. (Jobs with `ttlSecondsAfterFinished` also vanish shortly after finishing —
capture logs promptly.)

## Verify-pod / debug-pod in a PodSecurity-restricted namespace

A bare `kubectl run tmp --image=busybox ...` FAILS in a namespace with the `restricted` Pod Security
Standard (error: `violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false,
unrestricted capabilities, runAsNonRoot != true, seccompProfile`). Add a securityContext via
`--overrides`, or (usually easier) verify the thing another way — e.g. to confirm a built image
contains code, grep it with `docker run` locally BEFORE `kind load`, rather than exec-ing a pod on the
cluster. Trusting a fresh CI build from the merged commit avoids the check entirely (CI has no local
docker-cache staleness).

`make down`: `kind delete cluster --name <name>`

Expose `up` / `down` as short aliases:

```makefile
up: kind-up
down: kind-down
```

## Changes a fresh cluster cannot catch

kind always CREATES an object; it never UPDATES one that already exists. So a class of apply failures
is invisible locally and appears only on a long-lived cluster.

**`strategy: {type: Recreate}` cannot be adopted by a Deployment that is already RollingUpdate.** Such
a Deployment has an API-server-defaulted `spec.strategy.rollingUpdate`; server-side apply will not
remove a subfield another field manager owns, so the merge is rejected as invalid on every retry
forever (`spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy type is
'Recreate'`). A Deployment CREATED with `Recreate` never gets the subfield and is fine - so the rule
is about retrofitting, not about age.

So: **`Recreate` when you own the object from creation** (clearest intent, correct at any replica
count); **`maxSurge: 0` + `maxUnavailable: 1` when retrofitting a live RollingUpdate Deployment** -
same no-overlap guarantee at `replicas: 1`, and legal to apply because it sets the subfield rather
than forbidding it. Same retrofit trap for any immutable field (Service `clusterIP`, StatefulSet
`volumeClaimTemplates`, Job selectors).

**Dry-run a manifest change against the cluster that already holds the object**, not against kind:

```bash
kubectl apply --server-side --dry-run=server --context=<remote-ctx> -f <file>
```

## A Flux Kustomization is all-or-nothing

One resource failing its dry-run aborts the WHOLE Kustomization - every other manifest in it silently
stops reconciling. **`flux reconcile` still exits 0.** Read the verdict from status, never the exit
code:

```bash
kubectl get kustomization <name> -n flux-system --context=<ctx> \
  -o 'jsonpath={range .status.conditions[*]}{.type}={.status} {.message}{"\n"}{end}'
```

`spec.force: true` makes Flux delete and recreate on such a failure. Do not reach for it to escape one
bad manifest: it applies to every resource in the Kustomization, including StatefulSets whose PVCs you
do not want recreated. Fix the manifest.

## A pod holding an exclusive resource must not overlap itself

If a pod owns something only one holder may have - a session/client id at an external service, a lock,
a licence, a device - `replicas: 1` does NOT prevent two existing at once. The default RollingUpdate
starts the replacement before the old one goes. Set `maxSurge: 0`.

## A probe that ignores its dependency hides a dead pod

Readiness that returns 200 regardless of a downstream connection reports `1/1 Running` and Ready for a
pod that can do nothing. Decide deliberately whether the probe gates on the dependency. If it does
not, make the SUCCESS path visible in the log - a "connected" line logged below the pod's configured
level means healthy and broken look identical, and only an out-of-band query can tell them apart.
