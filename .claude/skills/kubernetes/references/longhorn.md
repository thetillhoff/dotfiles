# Longhorn

## Deleting a PVC leaves an orphan PV and a Longhorn volume

A `Retain` StorageClass leaves two objects behind after a PVC delete: a PV in phase `Released`, and the `volumes.longhorn.io` resource with its replicas. The replicas keep their full scheduled reservation on each node, even for an almost empty volume. The cost is scheduling headroom, not disk.

Clean up needs both deletes. The PV delete alone does not remove the Longhorn volume:

```sh
kubectl delete pv <pv-name>
kubectl -n longhorn delete volumes.longhorn.io <pv-name>
```

- An orphan shows `STATE: detached` and `ROBUSTNESS: unknown`. A detached volume that a workload still needs looks the same. Confirm that the PV is `Released` with an empty claim before you delete anything.
- The `orphans.longhorn.io` CRD tracks stray replica directories on disk. It does not track these volumes.

## Replace or drain nodes

- The drain rebuilds replicas only for attached volumes (`nodeDrainPolicy: block-for-eviction` blocks until each replica exists on another node).
- The drain skips detached volumes. A detached volume with all replicas on the outgoing nodes is lost. Attach each one in maintenance mode first, so it rebuilds.
- Remove nodes one at a time. Check that all volumes are `healthy` between nodes.

## Upgrades

- Upgrade one minor at a time. Create a Longhorn system backup first, and check that all volumes are `healthy`.
- A manager upgrade does not upgrade the volume engines. `defaultSettings.concurrentAutomaticEngineUpgradePerNodeLimit: 1` upgrades them by itself, one per node.
- The default `networkPolicies` (rendered since chart 1.12.1) block Prometheus from scraping longhorn-manager on `:9500`. Set `restrictInternalTraffic: false`, or set `metricsScrapeSources`.
- Longhorn never prunes the backups of a deleted volume. List `backupvolumes.longhorn.io` and delete the stale ones by hand.

## A stale attachment ticket pins an RWX volume to another node

A foreign ticket on a Longhorn RWX volume (`kubectl get volumeattachments.longhorn.io -n longhorn <pvc> -o jsonpath='{.spec.attachmentTickets}'`) keeps the volume on that node. The share-manager stays stopped, and every mount hangs in `ContainerCreating`. Remove the foreign ticket. A job that waits on such a mount shows `Running` for ever, so give long waits a timeout.
