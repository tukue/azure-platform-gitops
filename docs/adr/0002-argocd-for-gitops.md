# ADR 0002: Argo CD for GitOps reconciliation

## Status

Accepted.

## Context

Kubernetes desired state must be auditable, reviewable, and restored after drift. CI should validate and build, not directly mutate workload state.

## Decision

Use Argo CD to reconcile `clusters/dev` from Git. A bootstrap `platform-root` Application creates platform and application Applications. Argo CD manages ingress-nginx and kube-prometheus-stack directly from their pinned Helm repositories.

## Consequences

Git commits become the deployment interface and Argo CD corrects out-of-band changes. The Argo CD bootstrap is intentionally an operator action because it establishes repository access and installs the initial controller into a live cluster. The web UI supports day-to-day visibility without making it an alternate deployment path.
