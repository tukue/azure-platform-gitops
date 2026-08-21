# ADR 0008: Use Conftest CI checks with the AKS Azure Policy add-on

## Status

Accepted

## Context

GitOps requires feedback before merge and guardrails at runtime. A single policy mechanism cannot efficiently provide both developer-friendly pull-request feedback and centrally governed AKS compliance reporting.

## Decision

The repository uses OPA Rego policies through Conftest against rendered Kubernetes manifests in GitHub Actions. Terraform enables the supported Azure Policy add-on on AKS. Azure Policy assignments are introduced separately in audit mode and managed by Terraform at the appropriate Azure scope.

## Consequences

Developers receive fast, deterministic feedback from policies versioned beside the manifests. Azure administrators retain centralized audit and enforcement capability without a second standalone Gatekeeper installation. Some checks intentionally overlap; CI prevents avoidable failed syncs, while Azure Policy protects runtime admission. Policy exceptions require a reviewed code change and should be periodically removed.
