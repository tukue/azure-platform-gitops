# ADR 0001: AKS as the Kubernetes runtime

## Status

Accepted.

## Context

The platform is Azure-focused and needs a managed Kubernetes control plane that integrates with Azure networking, Microsoft Entra ID, managed identities, and Azure Container Registry.

## Decision

Use Azure Kubernetes Service (AKS), with Azure RBAC, Microsoft Entra ID group administration, managed identities, Azure CNI Overlay, OIDC issuer, and Azure Workload Identity enabled.

## Consequences

AKS reduces control-plane operations and provides native ACR integration. The platform remains responsible for node pools, network address planning, upgrades, and access governance. The public API option requires explicit authorized IP ranges; a private API endpoint is supported for production network topologies.
