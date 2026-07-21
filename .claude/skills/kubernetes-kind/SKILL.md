---
name: kubernetes-kind
description: Apply for any task involving kubectl, kind, k8s manifests, or local cluster operations. Enforces --context on every kubectl call, documents kind cluster conventions, and defines what make up / make down must provide.
---

# Kubernetes & kind

## Hard rules

**Always pass `--context` on every kubectl call. Never call `kubectl config use-context`.**

Multiple clusters run in parallel terminals. The default context is unreliable. `use-context` breaks other sessions.

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

`make down`: `kind delete cluster --name <name>`

Expose `up` / `down` as short aliases:

```makefile
up: kind-up
down: kind-down
```
