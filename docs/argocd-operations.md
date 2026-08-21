# Argo CD operations

## High availability and scaling

`scripts/bootstrap-argocd.sh` installs Argo CD's HA manifest by default. The manifest runs multiple replicas for supported components and Redis in HA mode. It requires at least three schedulable AKS nodes because of pod anti-affinity rules.

Before bootstrapping production-like environments, set `system_node_min_count = 3` in `dev.tfvars` and apply the Terraform change. The existing autoscaler can then add nodes up to `system_node_max_count` during demand spikes.

For a constrained, non-production environment only, use the standard profile explicitly:

```bash
export ARGOCD_INSTALL_PROFILE=standard
./scripts/bootstrap-argocd.sh
```

Do not use the standard profile as a production availability baseline. To scale beyond the HA defaults, use Argo CD controller metrics and queue/reconciliation latency to identify the bottleneck before increasing the relevant controller or repository-server capacity.

## Drift detection and correction

All root, platform, and application Argo CD Applications enable automated sync, pruning, self-healing, and bounded retry. Argo CD detects Git changes on its reconciliation interval and retries live-state drift correction after the application-controller self-heal timeout.

Demonstrate workload drift only in a non-production environment:

```bash
kubectl -n demo scale deployment/demo-api --replicas=1
argocd app get applications
kubectl -n demo get deployment demo-api
```

The Deployment returns to the Git-declared two replicas. Use `argocd app diff <application>` to inspect drift before a manual sync. A resource intentionally changed outside Git should either be committed as a reviewed desired-state change or allowed to self-heal; do not treat Argo CD's live state as an editing surface.

## Operational checks

```bash
kubectl -n argocd get pods
argocd app list
argocd app get platform
argocd app get applications
```

Investigate unsynced Applications, controller logs, repository-server saturation, and node scheduling before increasing replicas. HA availability depends on the AKS node topology as well as Argo CD deployment replicas.
