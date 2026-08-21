# ADR 0006: Use Azure-native managed observability

## Status

Accepted.

## Context

The platform needs centralized AKS logs, durable Prometheus metrics, dashboards, and a small operational alert baseline. The original in-cluster `kube-prometheus-stack` duplicates infrastructure Azure already provides and adds lifecycle, storage, upgrade, and credential-management responsibilities to the platform.

## Decision

Use Azure Monitor Container Insights with Log Analytics for logs, Azure Monitor managed service for Prometheus with an Azure Monitor workspace for metrics, and Azure Managed Grafana for visualization. Terraform owns Azure resources, associations, diagnostics, RBAC, and alerts. Argo CD owns only the Azure Monitor metrics-agent scrape configuration and workload annotations.

## Consequences

The platform no longer operates Prometheus or Grafana pods. Azure Managed Grafana Standard has a cost, and public network access is disabled by default for Azure Monitor Workspace, its data collection endpoint, and Grafana. Deployment therefore requires private endpoints, private DNS, and an Azure Monitor Private Link Scope before private AKS can ingest data or users can reach Grafana. Central action groups remain deferred.

Self-managed Prometheus and Grafana remain appropriate where portability, offline operation, custom extensions, or complete storage/control-plane ownership outweigh the operational cost of running them.
