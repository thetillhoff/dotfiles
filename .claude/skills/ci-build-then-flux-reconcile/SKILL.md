---
name: ci-build-then-flux-reconcile
description: Use after pushing a commit when you must wait for a GitHub Actions image build to finish and then force Flux to deploy the freshly-built image without waiting for its scan interval. Triggers - "reconcile the new image when the build finishes", "watch the build then roll it out", "deploy after CI", "force flux to pick up the new image", "skip the 5m flux interval", "make flux pull the new tag".
---

# CI Build → Flux Reconcile

Wait for a GitHub Actions image-build run to succeed, then force the Flux image-automation pipeline (scan → bump → apply) so the new image deploys now instead of at the next scan.

## Placeholders (discover, then substitute)

| Placeholder | What | Discover with |
| --- | --- | --- |
| `<run-id>` | the in-progress build run | `gh run list --limit 5` (numeric ID column) |
| `<kubeconfig>` | cluster kubeconfig path | ask / repo docs |
| `<ctx>` | kube context | `kubectl config get-contexts` |
| `<ns>` | namespace of the Flux image resources | `flux get image repository -A --context=<ctx>` |
| `<automation>` | ImageUpdateAutomation name | `flux get image update -n <ns> --context=<ctx>` |
| `<kustomization>` | Kustomization that applies the app | `flux get kustomization -A --context=<ctx>` (often `apps`) |

**`--context` goes AFTER the verb, `=` form** (`flux reconcile ... --context=<ctx>`). A leading `--context` hits a plugin-shim error. Same for `kubectl`.

## Step 1 — find the build

```bash
cd <repo> && gh run list --limit 5
```

Pick the `<run-id>` of the `in_progress` run for your pushed commit.

## Step 2 — watch it to completion (run in background)

```bash
gh run watch <run-id> --exit-status && gh run view <run-id> --json status,conclusion -q '.status+" / "+.conclusion'
```

`--exit-status` returns non-zero if the build fails. Run it in the background and wait for the exit notification. **Do NOT reconcile if the build failed.**

## Step 3 — force the Flux pipeline (only after success)

```bash
export KUBECONFIG=<kubeconfig>
flux get image policy -n <ns> --context=<ctx>            # see resolved tags (sanity)
flux reconcile image repository <repo-or-_-for-each> -n <ns> --context=<ctx>   # rescan registry
flux reconcile image update <automation> -n <ns> --context=<ctx>              # bump tags + commit to GitOps repo
flux reconcile kustomization <kustomization> --with-source --context=<ctx>    # apply
```

- Flux often already scanned (the policy shows the new tag) — the rescan is then a no-op, harmless.
- `image update` prints `repository up-to-date` when the bot already committed the bump. That is success, not an error.
- The bump is a commit to the GitOps infra repo by the flux bot. If you have that repo checked out: `cd <infra> && git pull --ff-only origin main`.

## Step 4 — verify the rollout

```bash
kubectl get deploy -n <ns> --context=<ctx> -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.template.spec.containers[0].image}{"\n"}{end}'
kubectl get pods -n <ns> --context=<ctx>
```

Confirm the deployments show the new tag and pods restarted. If an operator spawns Jobs from a `WORKER_IMAGE` env, check that too:

```bash
kubectl get deploy <operator> -n <ns> --context=<ctx> -o jsonpath='{range .spec.template.spec.containers[0].env[?(@.name=="WORKER_IMAGE")]}{.value}{"\n"}{end}'
```

## Common mistakes

- Reconciling before the build finishes → registry has no new tag, scan finds nothing.
- Leading `--context` → plugin-shim error; put it after the verb.
- Forgetting `export KUBECONFIG` → flux/kubectl hit the wrong (or no) cluster.
- Treating `repository up-to-date` as failure → it means the commit already landed.
