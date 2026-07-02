---
name: kubernetes-kind
description: Apply for any task involving kubectl, kind, k8s manifests, or local cluster operations. Enforces --context on every kubectl call, documents kind cluster conventions, and defines what make up / make down must provide.
---

# Kubernetes & kind

## Hard rules

**Always pass `--context` on every kubectl call. Never call `kubectl config use-context`.**

Multiple clusters run in parallel terminals. The default context is unreliable. `use-context` breaks other sessions.

```bash
kubectl get pods -n myapp --context kind-myapp
kubectl apply -k overlays/kind/ --context kind-myapp
kubectl rollout restart deployment/web -n myapp --context kind-myapp
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
4. `kubectl apply -k overlays/kind/ --context kind-<name>`
5. Create required secrets

`make down`: `kind delete cluster --name <name>`

Expose `up` / `down` as short aliases:

```makefile
up: kind-up
down: kind-down
```
