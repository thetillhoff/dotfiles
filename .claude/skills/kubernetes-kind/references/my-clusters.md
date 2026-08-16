# My named clusters

Machine-specific cluster instances for the `kubernetes-kind` skill. The skill body
(`../SKILL.md`) holds the universal method; this file holds the concrete clusters.

## hydra (remote, production)

`hydra` = production Hetzner/Talos cluster. **Not** in the default kubeconfig — its
kubeconfig lives in the infra repo.

| | Value |
|---|---|
| Context | `admin@hydra` |
| Kubeconfig | `~/code/thetillhoff/infra/pulumi/kubeconfig` |
| App manifests | `~/code/thetillhoff/infra/kubernetes/apps/hydra/<app>/` (GitOps via Flux) |

```bash
export KUBECONFIG=~/code/thetillhoff/infra/pulumi/kubeconfig   # hydra only
kubectl get pods -n <ns> --context=admin@hydra
kubectl logs deploy/<app> -n <ns> --context=admin@hydra --tail=100
```

Apps deploy via Flux from the infra repo — don't `kubectl apply` declarative resources to
hydra; commit to infra and let Flux reconcile. One-shot CRs are the exception (see the
trading repo's `trading-deploy` skill).
