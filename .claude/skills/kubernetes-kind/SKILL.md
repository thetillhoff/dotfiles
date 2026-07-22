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
